+++
title = "(WIP) Rust SAT-solver"
date = "2023-03-04"
description = "A SAT solver in rust"
[taxonomies]
tags = ["sat", "rust", "programming"]
+++

This is a (WIP) post about my (WIP) SAT solver:
[rsat](https://github.com/jalil-salame/rsat)

# SAT

The boolean Satisfiability Problem (SAT) is a famous NP-Complete problem (A very
hard problem) in computer science. NP-Complete problems are important because
they can generally be translated efficiently into each other, that means, if you
solve one of the efficiently, you get an efficient solver for all of them.

Many important problems are NP-Complete, ie. Rust's `match` statement validation
is NP-Complete, and so is solving [Sudokus](@/nsudoku-solver.md)
