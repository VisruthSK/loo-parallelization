# Parallelization in loo (current state)


## What is parallelization?

<!-- TODO: what is parallelization, why we would want it, differences in multprocessing/multithreading, etc., how to do in R, how does mirai work -->

### Serial `mirai` execution

Currently, parallelization in loo goes through [three
paths](https://github.com/stan-dev/loo/blob/05a6bd20af83c919ba7a5572e3e0a50426c17a77/R/importance_sampling.R#L206)
\[1\]:

1.  Serial execution using `lapply()`
2.  Forking through `parallel::mclapply()`
3.  Fresh processes through `parallel::parLapply()`

The serial execution path is taken when the `cores` argument is equal to
1, and forking is only available on Linux and MacOS. Since `mirai` \[2\]
neatly subsumes paths 2 and 3, a question we had was what would the
performance hit be if we also removed 1–that is, if a user requested
serial execution, what do we lose by using `mirai` with a single core.

``` r
log_ratios <- -loo::example_loglik_matrix()
S <- nrow(log_ratios)
N <- ncol(log_ratios)
tail_len <- loo:::n_pareto(r_eff = rep(1, N), S = S)

x <- Map(
  \(i) {
    list(
      log_ratios_i = log_ratios[, i],
      tail_len_i = tail_len[i]
    )
  },
  seq_len(N)
)

work <- function(s) {
  loo:::do_psis_i(
    log_ratios_i = s$log_ratios_i,
    tail_len_i = s$tail_len_i
  )$pareto_k
}

mirai::daemons(1)

results <- bench::mark(
  vapply = vapply(x, work, numeric(1)),
  lapply = lapply(x, work),
  mirai = mirai::mirai_map(x, work)[],
  vapply_to_list = vapply(x, work, numeric(1)) |> as.list(),
  purrr_map = purrr::map_dbl(x, work),
  check = same_numeric_values,
  iterations = 200
)
```

Note that `mirai_map()` and `lapply()` results are lists.
`same_numeric_values()`’s definition is elided from output but simply
checks that results are identical without counting unlisting as part of
the benchmark (unlike `vapply_to_list`).

``` r
results |> summary()
```

    # A tibble: 5 × 6
      expression          min   median `itr/sec` mem_alloc `gc/sec`
      <bch:expr>     <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
    1 vapply           9.39ms   10.4ms      93.1    3.37MB   15.8  
    2 lapply           9.33ms     11ms      88.8    3.07MB   15.1  
    3 mirai           20.77ms   23.3ms      41.9  736.67KB    0.639
    4 vapply_to_list   9.29ms   11.1ms      88.6    3.07MB   15.0  
    5 purrr_map        9.49ms   11.2ms      85.2    3.86MB   14.5  

``` r
results |> summary(relative = TRUE)
```

    # A tibble: 5 × 6
      expression       min median `itr/sec` mem_alloc `gc/sec`
      <bch:expr>     <dbl>  <dbl>     <dbl>     <dbl>    <dbl>
    1 vapply          1.01   1         2.22      4.68     24.7
    2 lapply          1.00   1.06      2.12      4.27     23.6
    3 mirai           2.24   2.24      1         1         1  
    4 vapply_to_list  1      1.06      2.11      4.27     23.5
    5 purrr_map       1.02   1.08      2.03      5.37     22.6

NB: the `mem_alloc` column should not be interpreted as total memory
usage for `mirai`: `bench::mark()` records R heap allocations via
`utils::Rprofmem()`, which is not able to track daemons’ memory usage
\[2\], \[3\], \[4\].

`mirai_map()` with a single daemon has a median runtime of 23.3ms,
roughly 2.2x slower than the fastest in-process approach. Of course, in
absolute terms the difference is negligible, adding only about 10ms. The
memory usage of all in-process approaches are relatively close to one
another. `vapply()`’s small memory overhead may probably be attributed
to the extra work it does validating types and lengths and such \[4\].

In short, it is probably a good idea to directly test the effects of
using `mirai` execution in `loo`, but it is likely that we will find
that we should keep the unique single core execution path.

## Where is parallelization currently in use?

- `function()`
  - short description
- `function()`
  - short description

## Where could we benefit from introducing parallelization?

To investigate this question we use two approaches:

1)  Inspecting the code base and figuring out at which points
    parallelization might be helpful (“analytic search”)
2)  Running performance tests on the loo pipeline, investigating where
    the bottlenecks are, and finding out whether we can improve things
    with parallelization.

### Analytic search

For each function/place in code where you think parallelization might
help, do: \* Introduction \* short description of function \* why do you
think that parallelization can improve things? \* Experiment: \*
implement parallelization \* record time (define which time you are
using) for parallel and unparallel version \* report results (how much
speed up we can get?) \* Short conclusion

### Performance testing

- short description of approach for running performance test
- run performance test
- report results
- identify bottlenecks
- provide first ideas whether any of the identified bottlenecks can
  benefit from parallelization

## Vectorization

When browsing the codebase to find places where parallelization could be
helpful (see
<a href="#sec-parallelization-benefit" class="quarto-xref">Section 3</a>),
we found two potential speedups–in these places, we may be able to
benefit from *vectorizing* functions instead of parallelizing a loop.
Vectorization is advantageous in these spots as we would be rewriting R
loops as optimized matrix operations \[5, Sec. 24.5\] - 24.7.

> Matrix algebra is a general example of vectorisation. There loops are
> executed by highly tuned external libraries like BLAS. If you can
> figure out a way to use matrix algebra to solve your problem, you’ll
> often get a very fast solution. - Wickham \[5, Sec. 24.5\]

Of course, for these potential improvements, we should first write tests
for correctness, then write benchmarks in the PR.

The more important of the two is in
[`pseudobma_weights()`](https://github.com/stan-dev/loo/blob/master/R/loo_model_weights.R#L334),
when performing a Bayesian bootstrap. This function is the backend for
`loo_model_weights()`, and is used to average models using
psuedo-Bayesian model averaging, optionally using a Bayesian bootstrap
(which is referred to as psudo-BMA+). This pseudo-BMA+ path is the one
we care about as it has the elidable loop. We currently loop over
Bayesian bootstrap iterations where it seems quite plausible to swap to
matrix operations. This could potentially be a large speedup as the loop
is large, being of length `BB_n`, which defaults to 1,000 replications.
There don’t appear to be any reallocations in the loop, so the speedup
will probably be dominated by the efficiency of matrix ops \[5, Secs.
5.3.1, 24.6\]. This is tracked in \#XXX. <!-- TODO: PR -->

Similarly, though less interesting, is a gradient calculation in
[`stacking_weights()`](https://github.com/stan-dev/loo/blob/master/R/loo_model_weights.R#L278),
just above the previous function. `stacking_weights()` is similarly used
for combining models using stacking, i.e., fitting a linear model to
weigh the contending models. The gradient function is used for solving
for those weights. However, the speedup here is less interesting because
we are looping over `K`, the number of models being compared, which is
usually small. However, we may as well take the (potential) free
performance. This is tracked in \#XXX. <!-- TODO: PR -->

These two loops seem like low hanging fruit and well worth the time to
implement.

## Nested parallelization

When updating `loo` we wish to avoid “nested parallelization”,
i.e. attempting to compute something in parallel, when already in a
parallel process. Take this nonfunctioning `mirai` code as an example:

``` r
# parallel over xs
mirai_map(
  xs,
  # parallel over x
  function(x) mirai_map(x, mean)[]
)
```

We first are doing something parallely over values of `xs`, but then we
try to work in parallel again for each value from `xs`! The main problem
here is oversubscription: we spawn `n` outer workers, let say, then for
each we spawn another `m` inner workers. In the package context though,
this implementation would be far more complex, and would probably be
hidden completely from users. This becomes a problem when a user sets
`n`, the outer parallel workers, to \# cores - 1[^1], as the actual
number of parallel tasks could be as large as $n * m$. Oversubscription
is bad because, in this context, we are mostly running CPU heavy tasks
where each process takes time and needs its own core. Oversubscription
is promising more parallelization than what the hardware can
provide–note that parallelization usually has some [fixed startup costs
as well](../experiments/mirai_overhead.md), so we would probably lose
performance. In `loo` specifically, we must be careful when
parallelizing functions to ensure we do not accidentally have nested
parallelization.

<!-- TODO: update codes -->

### Where do we currently find nested parallelization in `loo`?

<!-- TODO -->

- short description of function
- do you see any challenges with the identified functions?
- should nested parallelisation run parallel or sequential?
  - provide experiments to stress your statement

### Potential problems with packages that make use of `loo` such that nested parallelization can occur?

However, we know that other packages also call `loo` functions, which is
another potential vector for nested parallelization. To this end, it
seems like `brms` is the only (Stan) package where this could even be
vaguely possible, but doing so seems to necessitate wilful
parallelization not provided natively by `brms`. This merits further
investigation, but it seems like we can (softly) table concerns
regarding external nested parallelization for now.

<!-- TODO -->

Make a list of packages of which you have thought of: \* package name \*
Any issues that you see? \* (make a short note even if you don’t see
issues)

## Appendix

``` r
sessioninfo::session_info(
  pkgs = c("loo", "mirai", "bench", "purrr"),
  info = c("platform", "packages"),
  dependencies = FALSE
)
```

    Warning in system2("quarto", "-V", stdout = TRUE, env = paste0("TMPDIR=", :
    running command '"quarto"
    TMPDIR=C:/Users/visru/AppData/Local/Temp/RtmpiqNbnI/file4cc57eb5023 -V' had
    status 1

    ─ Session info ───────────────────────────────────────────────────────────────
     setting  value
     version  R version 4.6.0 (2026-04-24 ucrt)
     os       Windows 11 x64 (build 26200)
     system   x86_64, mingw32
     ui       RTerm
     language (EN)
     collate  English_United States.utf8
     ctype    English_United States.utf8
     tz       America/Los_Angeles
     date     2026-06-01
     pandoc   3.8.3 @ c:\\Program Files\\Positron\\resources\\app\\quarto\\bin\\tools/ (via rmarkdown)
     quarto   NA @ C:\\Users\\visru\\AppData\\Local\\Programs\\Quarto\\bin\\quarto.exe

    ─ Packages ───────────────────────────────────────────────────────────────────
     package * version date (UTC) lib source
     bench     1.1.4   2025-01-16 [1] RSPM (R 4.6.0)
     loo       2.9.0   2025-12-23 [1] RSPM (R 4.6.0)
     mirai     2.7.0   2026-05-08 [1] RSPM (R 4.6.0)
     purrr     1.2.2   2026-04-10 [1] RSPM (R 4.6.0)

     [1] C:/Users/visru/AppData/Local/R/win-library/4.6
     [2] C:/Program Files/R/R-4.6.0/library

    ──────────────────────────────────────────────────────────────────────────────

<div id="refs" class="references csl-bib-body" entry-spacing="0">

<div id="ref-loo" class="csl-entry">

<span class="csl-left-margin">\[1\]
</span><span class="csl-right-inline">A. Vehtari *et al.*, “Loo:
Efficient leave-one-out cross-validation and WAIC for bayesian models.”
2025. Available: <https://mc-stan.org/loo/></span>

</div>

<div id="ref-mirai" class="csl-entry">

<span class="csl-left-margin">\[2\]
</span><span class="csl-right-inline">C. Gao, *Mirai: Minimalist async
evaluation framework for r*. 2026. Available:
<https://mirai.r-lib.org></span>

</div>

<div id="ref-bench" class="csl-entry">

<span class="csl-left-margin">\[3\]
</span><span class="csl-right-inline">J. Hester and D. Vaughan, *Bench:
High precision timing of r expressions*. 2025. Available:
<https://bench.r-lib.org/></span>

</div>

<div id="ref-R" class="csl-entry">

<span class="csl-left-margin">\[4\]
</span><span class="csl-right-inline">R Core Team, *R: A language and
environment for statistical computing*. Vienna, Austria: R Foundation
for Statistical Computing, 2026. Available:
<https://www.R-project.org/></span>

</div>

<div id="ref-advr" class="csl-entry">

<span class="csl-left-margin">\[5\]
</span><span class="csl-right-inline">H. Wickham, *Advanced r*, 2nd ed.
Chapman; Hall/CRC, 2019. doi:
[10.1201/9781351201315](https://doi.org/10.1201/9781351201315).
Available: <https://adv-r.hadley.nz/></span>

</div>

</div>

[^1]: This is a common heuristic for number of
    threads/daemons/workers/etc. to use because it leaves 1 core free to
    do normal computer things, lest the system become unresponsive. Note
    this doesn’t account for memory usage at all–if you have 8n memory
    but send out n tasks which each use “1” memory, you will run out of
    memory. See [the note on memory](memory.md).
