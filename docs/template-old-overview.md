---
title: Parallelization in loo (current state)

---

# Parallelization in `loo` (current state)

## Where is parallelization currently in use?

+ `function()`
    + short description
+ `function()`
    + short description

## Where could we benefit from introducing parallelization?

To investigate this question we use two approaches:

1) Inspecting the code base and figuring out at which points parallelization might be helpful ("analytic search")
2) Running performance tests on the loo pipeline, investigating where the bottlenecks are, and finding out whether we can improve things with parallelization.

### Analytic search
For each function/place in code where you think parallelization might help, do:
+ Introduction
    + short description of function
    + why do you think that parallelization can improve things?
+ Experiment: 
    + implement parallelization
    + record time (define which time you are using) for parallel and unparallel version
    +  report results (how much speed up we can get?)
+  Short conclusion

### Performance testing
+ short description of approach for running performance test
+ run performance test
+ report results
+ identify bottlenecks
+ provide first ideas whether any of the identified bottlenecks can benefit from parallelization

## Nested parallelization
### Where do we currently find nested parallelization in `loo`?
+ short description of function
+ do you see any challenges with the identified functions?
+ should nested parallelisation run parallel or sequential?
    + provide experiments to stress your statement

### Potential problems with packages that make use of `loo` such that nested parallelization can occur?
Make a list of packages of which you have thought of:
+ package name
+ Any issues that you see?
+ (make a short note even if you don't see issues)


