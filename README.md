# `loo` Parallelization


General documentation for Stan/Numfocus GSOC 2026 project:
[parallelizing `loo`](https://www.visruth.com/blog/20260516-01/). The
relevant issue is [\#308](https://github.com/stan-dev/loo/issues/308).

<!-- It would be really helpful to add a project overview to your repo, for example in a README.md. This could include the main tasks and subtasks. A few reasons why this is useful:
It acts as a red thread through the project; we can always refer back to it to see where we currently stand, and link out to more detailed discussions in the notes/ folder.
It gives you a natural place for a "Misc tasks" section at the end, where you can collect ideas or questions that come up in our meetings but might be slightly out of scope or uncertain. This way, nothing gets lost, even if we decide later not to pursue a particular idea. -->

Currently `loo` relies on the `parallel` package from base R \[1\] to
parallelize certain computations, such as moment matching, Pareto
smoothed importance sampling \[2\], and more. This works well on Unix
systems, where `parallel` can use forking, but Windows requires a
separate, socket based path. This project will replace `loo`’s current
parallelization structure, swapping to a platform-agnostic approach
using `mirai` \[3\]. This will have the added benefit of allowing users
to parallelize execution over heterogenous compute resources (e.g., over
local cores, a distributed systems, GPUs, or any mixture). This freedom
decouples execution profiles from `loo`’s software, allowing users with
varying compute needs to exploit their available resources without any
extra work. Further, a major part of the project here would be writing
strong documentation which teaches users how to make use of some common
resources such as SLURM or SSH access to users, building off of the
documentation in packages like `mirai`, but with a focus on applications
to `loo`.

<!-- ## Misc. Tasks -->

<!-- TODO -->

<div id="refs" class="references csl-bib-body" entry-spacing="0">

<div id="ref-R" class="csl-entry">

<span class="csl-left-margin">\[1\]
</span><span class="csl-right-inline">R Core Team, *R: A language and
environment for statistical computing*. Vienna, Austria: R Foundation
for Statistical Computing, 2026. Available:
<https://www.R-project.org/></span>

</div>

<div id="ref-PSIS" class="csl-entry">

<span class="csl-left-margin">\[2\]
</span><span class="csl-right-inline">A. Vehtari, D. Simpson, A. Gelman,
Y. Yao, and J. Gabry, “Pareto smoothed importance sampling,” *Journal of
Machine Learning Research*, vol. 25, no. 72, pp. 1–58, 2024, Available:
<http://jmlr.org/papers/v25/19-556.html></span>

</div>

<div id="ref-mirai" class="csl-entry">

<span class="csl-left-margin">\[3\]
</span><span class="csl-right-inline">C. Gao, *Mirai: Minimalist async
evaluation framework for r*. 2026. Available:
<https://mirai.r-lib.org></span>

</div>

</div>
