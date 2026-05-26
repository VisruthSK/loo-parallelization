When updating `loo` we wish to avoid "nested parallelization", i.e. attempting to compute something in parallel, when already in a parallel process. Take this nonfunctioning `mirai` code as an example:

```r
# parallel over xs
mirai_map(
  xs,
  # parallel over x
  function(x) mirai_map(x, mean)[]
)
```

We first are doing something parallely over values of `xs`, but then we try to work in parallel again for each value from `xs`! The main problem here is oversubscription: we spawn `n` outer workers, let say, then for each we spawn another `m` inner workers. In the package context though, this implementation would be far more complex, and would probably be hidden completely from users. This becomes a problem when a user sets `n`, the outer parallel workers, to # cores - 1 [^1], as the actual number of parallel tasks could be as large as $n * m$. Oversubscription is bad because, in this context, we are mostly running CPU heavy tasks where each process takes time and needs its own core. Oversubscription is promising more parallelization than what the hardware can provide--note that parallelization usually has some [fixed startup costs as well](../experiments/mirai_overhead.md), so we would probably lose performance. In `loo` specifically, we must be careful when parallelizing functions to ensure we do not accidentally have nested parallelization. 

[^1]: This is a common heuristic for number of threads/daemons/workers/etc. to use because it leaves 1 core free to do normal computer things, lest the system become unresponsive. Note this doesn't account for memory usage at all--if you have 8n memory but send out n tasks which each use "1" memory, you will run out of memory. See [the note on memory](memory.md).

However, we know that other packages also call `loo` functions, which is another potential vector for nested parallelization. To this end, it seems like `brms` is the only (Stan) package where this could even be vaguely possible, but doing so seems to necessitate wilful parallelization not provided natively by `brms`. This merits further investigation, but it seems like we can (softly) table concerns regarding external nested parallelization for now.
