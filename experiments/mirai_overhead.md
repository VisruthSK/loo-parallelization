# Serial `mirai` Execution


Currently, parallelization in loo goes through [three
paths](https://github.com/stan-dev/loo/blob/05a6bd20af83c919ba7a5572e3e0a50426c17a77/R/importance_sampling.R#L206):

1.  Serial execution using `lapply()`
2.  Forking through `parallel::mclapply()`
3.  Fresh processes through `parallel::parLapply()`

Serial execution is taken when the `cores` argument is equal to 1, and
forking is only available on Linux and MacOS. Since `mirai` neatly
replaces 2 and 3, a question we had was what would the performance hit
be if we also removed 1–that is, if a user requested serial execution,
what do we lose by using `mirai` with a single core. Here is a simple
experiment we started with:

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

    # A tibble: 4 × 6
      expression          min   median `itr/sec` mem_alloc `gc/sec`
      <bch:expr>     <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
    1 lapply            1.24s    1.25s     0.801    11.2KB        0
    2 vapply            1.24s    1.25s     0.802      208B        0
    3 purrr_map         1.24s    1.25s     0.802   781.8KB        0
    4 mirai_1_daemon    1.24s    1.25s     0.802   516.6KB        0

``` r
results |> summary(relative = TRUE)
```

    # A tibble: 4 × 6
      expression       min median `itr/sec` mem_alloc `gc/sec`
      <bch:expr>     <dbl>  <dbl>     <dbl>     <dbl>    <dbl>
    1 lapply          1.00   1.00      1         55.2      NaN
    2 vapply          1      1.00      1.00       1        NaN
    3 purrr_map       1.00   1.00      1.00    3849.       NaN
    4 mirai_1_daemon  1.00   1         1.00    2543.       NaN

As expected, the times are all essentially identical; we are more
interested in the memory usage. We can see that, unsurprisingly,
`vapply()` allocates the least memory, by a long shot. `mirai_map()` is
worse than `lapply()` by a good margin too, using about 50x the memory.
