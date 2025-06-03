---
toc: true
layout: post
title:  "OpenMP && MPI introduction"
date:   2018-03-12
excerpt: "Introduction to parallel programming"
image: "/images/openmp.png"
comments: true
tags: OpenMP
---

## syntax

Therefore there can be three layers of parallelism in a single program: 

Single thread processing multiple data; 

multiple threads running simultaneously; 

and multiple devices running same program simultaneously.


Team: A team is the group of threads executing the program, To create a new team of threads, you need to specify the parallel keyword


SIMD parallelism (Single-Instruction, Multiple-Data).

specify the thread used: num_threads(2)


Therefore, lastprivate cannot be used to e.g. fetch the value of a flag assigned randomly during a loop. Use reduction for that, instead.

The declare reduction directive generalizes the reductions to include user-defined reductions.

## Offloading

Offloading means that parts of the program can be executed not only on the CPU of the computer itself, but also in other hardware attached to it, such as on the graphics card.

You can acquire device numbers by using the <omp.h> library functions, such as omp_set_default_device, omp_get_default_device, omp_get_num_devices, and omp_is_initial_device.


## Thread-safety

The flush directive can be used to ensure that the value observed in one thread is also the value observed by other threads.

## Thread synchronization

The barrier directive causes threads encountering the barrier to wait until all the other threads in the same team have encountered the barrier.



## Coding guide

\#ifdef _OPENMP

## MPI

bcast:

![](https://www.citutor.org/get.php/mpi/Collective_Comm/images/broadcast.gif)

reduction:

![](https://www.citutor.org/get.php/mpi/Collective_Comm/images/reduction.gif)

scactter:

![](https://www.citutor.org/get.php/mpi/Collective_Comm/images/scatter.gif)


## Kubernetes

![](https://d33wubrfki0l68.cloudfront.net/5cb72d407cbe2755e581b6de757e0d81760d5b86/a9df9/docs/tutorials/kubernetes-basics/public/images/module_03_nodes.svg)

A Node is a worker machine in Kubernetes and may be either a virtual or a physical machine, depending on the cluster

pod:

A Pod is a Kubernetes abstraction that represents a group of one or more application containers (such as Docker or rkt), and some shared resources for those containers. 


CaaS (Container as a Service)

