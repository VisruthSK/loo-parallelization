# `loo` Parallelization

General documentation for Stan/Numfocus GSOC 2026 project: [parallelizing `loo`](https://www.visruth.com/blog/20260516-01/).  The relevant issue is [#308](https://github.com/stan-dev/loo/issues/308).

Currently `loo` relies on the `parallel` package from base R @R to parallelize certain computations, such as moment matching, Pareto smoothed importance sampling @PSIS, and more. This works well on Unix systems, where `parallel` can use forking, but Windows requires a separate, socket based path. This project will replace `loo`'s current parallelization structure, swapping to a platform-agnostic approach using `mirai` @mirai. This will have the added benefit of allowing users to parallelize execution over heterogenous compute resources (e.g., over local cores, a distributed systems, GPUs, or any mixture). This freedom decouples execution profiles from `loo`'s software, allowing users with varying compute needs to exploit their available resources without any extra work. Further, a major part of the project here would be writing strong documentation which teaches users how to make use of some common resources such as SLURM or SSH access to users, building off of the documentation in packages like `mirai`, but with a focus on applications to `loo`.

## Main Tasks

Broadly then, our main tasks are:

* Benchmark and test all changes
* Swap the codebase to `mirai`
* Parallelize heretofore serial code when possible
* Write documentation (function level, vignettes, etc.) which clearly showcase how to use the new parallel backend

## Misc. Tasks

* Warn users when too much memory may be used
