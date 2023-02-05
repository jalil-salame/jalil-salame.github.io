+++
title = "(WIP) N-Sudoku Solver"
date = "2023-02-04"
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
pub fn naive_dfs(mut sudoku: super::Sudoku) -> SudokuResult {
    let order = sudoku.order();
    let Some((ix, _)) = sudoku.0.indexed_iter().find(|(_, value)| value.is_none())
    else {
        if sudoku.solved() {
            return ControlFlow::Break(sudoku);
        } else {
            return ControlFlow::Continue(());
        }
    };

    for value in 1..=order as u8 {
        *sudoku.0.get_mut(ix).unwrap() = SudokuValue(Some(value.try_into().unwrap()));

        if sudoku.valid() {
            sudoku = naive_dfs(sudoku)?;
        }
    }

    *sudoku.0.get_mut(ix).unwrap() = SudokuValue(None);

    ControlFlow::Continue(())
}
```
