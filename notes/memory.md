# Memory Usage and `loo`


As briefly discussed in [Nested
Parallelization](nested_parallelization.md), parallelization may lead to
running out of memory (OOM). Copying the construction from that note: if
you have, say, 8GB memory but spin up 16 tasks which each use 1GB, you
will run out of memory. The math here is quite clear, though it is worst
case and is complicated by the profile of the program–if that 1GB is
peak usage and it normally doesn’t go so high, and the peaks don’t
overlap, then it is possible for you to squeeze past without 16 gigs
free. Note, however, that this 1GB usage per parallel worker is assuming
that there is no memory that can be shared. If objects are reused across
workers, we could using something like `mori` \[1\] in R to reduce the
physical memory usage by mapping some objects in workers to the same
shared address spaces, thus eliding copies–unless, of course, a worker
modifies the object. This can be loosely seen as mildly clawing back
some of the benefits of forking with respect to memory. Note however,
that `mori` works on a limited set of R objects, specifically “atomic
vector types, lists, and data frames” \[1\]. See [`mori` with model
methods](../experiments/mori_model_meth.md) for empirical proof that we
cannot naively use `mori` to share compiled model methods across
workers.

Since OOM is a slightly tricky thing to think about, one user friendly
feature we would like to implement, somewhat orthogonal to swapping to
`mirai`, is having parallel functions check how much memory they need
and warn users if a run might run out of memory. We could do this pretty
simply by running our functions across varying input sizes and modelling
peak memory usage (probably averaged over a few runs) as a function of
the parameters. Of course, if we implement this we would need to test it
to see how accurate and conservative our model is.

<div id="refs" class="references csl-bib-body" entry-spacing="0">

<div id="ref-moripost" class="csl-entry">

<span class="csl-left-margin">\[1\]
</span><span class="csl-right-inline">C. Gao, “Mori: Shared memory for r
objects,” Apr. 23, 2026. Available:
<https://opensource.posit.co/blog/2026-04-23_mori-0-1-0/>. \[Accessed:
May 26, 2026\]</span>

</div>

</div>
