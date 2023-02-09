+++
title = "(WIP) N-Sudoku Solver"
date = "2023-02-04"
description = "A Generalized Sudoku solver In Rust"
tags = ["sudoku", "rust", "programming"]
+++

This is a (WIP) blog post about my sudoku solver:
[nsudoku-solve](https://github.com/jalil-salame/nsudoku-solve)

# Sudoku

If you somehow don't know how a Sudoku puzzle works, you can check out the
[wikipedia page](https://en.wikipedia.org/wiki/Sudoku), or check out my (very
simplified) explanation:

A Sudoku is a puzzle where you try to fill up the empty cells with symbols based
on rules.

The Sudoku board is `N×N` where `N=k²` and `k∈{2,3,4,...}`, the typical size is `9×9`
(`k=3`).

It has `k×k` mega-cells, each symbol may appear once per row, column, and
mega-cell.

As each of those constructs has exactly `N=k²` cells, you need only `N` symbols
(usually the numbers `[1,2,...,N]`).

A naive calculation of the number of possible valid sudokus is `N^(N²)`, as
there are `N` possible values per cell (and there are `N²` cells), for a `9×9`
sudoku this comes out to be a bit less than `2×10⁷⁷`.

A better approximation of the number of valids sudokus is reached by knowing that
each row contains no duplicate numbers you have `N` possibilities for the first
cell in the row, but only `N-1` for the second, this tells us, that a tighter
bound can be obtained with `N!×N`, there are `N!` possible rows, and there are
`N` rows in total. This gives us `3265920` as an upper bound for the `9x9`
sudoku states.

This huge number of valid sudokus means that heavy prunning of the possibility
space needs to be done in order to be able to solve it efficiently for moderatly
large values of `k`.

## Solving the Sudoku

### The Naive Way

A very naive (badly performing) algorithm would look something like:

1. Find an empty cell.
   - If no cell is found then check if it's solved and return the solved sudoku
     if it is, otherwise continue.
2. For each value `1..=N` try setting the empty cell to that value.
   - If the new sudoku is valid, continue from step 1
3. No solution was possible from this state.

There is an example implementation at
[solve.rs](https://github.com/jalil-salame/nsudoku-solve/blob/main/src/sudoku/solve.rs)
which looks something like this:

```rust
pub fn naive_dfs(sudoku: &mut  Sudoku) -> ControlFlow<()> {
    let order = sudoku.order();
    // Find an empty cell
    let Some((ix, _)) = sudoku.0.indexed_iter().find(|(_, value)| value.is_none())
    else {
        // No Cells are empty
        if sudoku.solved() {
            // Found a valid solution
            return ControlFlow::Break(());
        } else {
            // No valid solution, Continue
            return ControlFlow::Continue(());
        }
    };

    // Try all possible values 1..=N
    for value in 1..=order as u8 {
        *sudoku.0.get_mut(ix).unwrap() = SudokuValue(Some(value.try_into().unwrap()));

        // This value produces a valid sudoku
        if sudoku.valid() {
            naive_dfs(sudoku)?; // If a solution is found (Break(sudoku)) then return early
        }
    }
    // Reset Cell to empty
    *sudoku.0.get_mut(ix).unwrap() = SudokuValue(None);

    ControlFlow::Continue(())
}
```

One nice property of this solution, is that only one sudoku needs to be created
thus the memory usage is proportinal to the size of the sudoku: `N²` cells, and
at most `N²` stack frames.

The only problem with this solution is how wasteful it is; we can precalculate
what values are possible, thus we don't need to check all values `1..=N`, and
just check the possible set, whenever we set a value, we can update this
possible set, which in turn getes rid of all the `sudoku.valid()` calls.

It is only worth it if calculating the original possibilities and then updating
them is cheap.
