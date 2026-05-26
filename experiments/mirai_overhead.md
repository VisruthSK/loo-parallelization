# Serial `mirai` Execution


Currently, parallelization in loo goes through [three
paths](https://github.com/stan-dev/loo/blob/05a6bd20af83c919ba7a5572e3e0a50426c17a77/R/importance_sampling.R#L206)
\[1\]:

1.  Serial execution using `lapply()`
2.  Forking through `parallel::mclapply()`
3.  Fresh processes through `parallel::parLapply()`

Serial execution is taken when the `cores` argument is equal to 1, and
forking is only available on Linux and MacOS. Since `mirai` \[2\] neatly
replaces 2 and 3, a question we had was what would the performance hit
be if we also removed 1–that is, if a user requested serial execution,
what do we lose by using `mirai` with a single core.

Here is the simple experiment we started with:

``` r
x <- rep(0.05, 20)

work <- function(s) {
  Sys.sleep(s)
  sqrt(s)
}

mirai::daemons(1)

results <- bench::mark(
  vapply = vapply(x, work, numeric(1)),
  lapply = lapply(x, work),
  mirai = mirai::mirai_map(x, work)[],
  vapply_to_list = vapply(x, work, numeric(1)) |> as.list(),
  purrr_map = purrr::map_dbl(x, work),
  check = same_numeric_values,
  iterations = 20
)
```

Note that `mirai_map()` and `lapply()` results are lists.
`same_numeric_values()`’s definition is elided from output but it exists
to check that results are identical without counting unlisting as part
of the benchmark.

``` r
results |> summary()
```

    # A tibble: 5 × 6
      expression          min   median `itr/sec` mem_alloc `gc/sec`
      <bch:expr>     <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
    1 vapply            1.24s    1.25s     0.801    11.2KB        0
    2 lapply            1.24s    1.25s     0.801      208B        0
    3 mirai             1.24s    1.25s     0.802   516.6KB        0
    4 vapply_to_list    1.24s    1.25s     0.801      416B        0
    5 purrr_map         1.23s    1.25s     0.802   781.8KB        0

``` r
results |> summary(relative = TRUE)
```

    # A tibble: 5 × 6
      expression       min median `itr/sec` mem_alloc `gc/sec`
      <bch:expr>     <dbl>  <dbl>     <dbl>     <dbl>    <dbl>
    1 vapply          1.01   1.00      1.00      55.2      NaN
    2 lapply          1.01   1.00      1          1        NaN
    3 mirai           1.00   1.00      1.00    2543.       NaN
    4 vapply_to_list  1.01   1         1.00       2        NaN
    5 purrr_map       1      1.00      1.00    3849.       NaN

As expected, the times are all essentially identical; we are more
interested in the memory usage. We can see that, unsurprisingly,
`vapply()` allocates the least memory, by a long shot. `mirai_map()` is
worse than `lapply()` by a good margin too, using about 50x the memory.

We can also see that using vapply and converting the resulting vector to
a list is much more efficient than using `lapply()` directly–ergo if we
can replace some `lapply()` calls we should. Conversion to a list is
only necessary for downstream functions which have been written to
expect a list. Swapping everything to vectors may be aesthetically
pleasing but probably isn’t the best use of time (and, of course, is
probably not possible).

In short, its probably a good idea to keep the unique single core
execution path.

## References

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

</div>
