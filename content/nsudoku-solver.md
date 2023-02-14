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
pub fn naive_solve(sudoku: &mut  Sudoku) -> ControlFlow<()> {
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
            naive_solve(sudoku)?; // If a solution is found (Break(sudoku)) then return early
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

### Prunning the Possibilities

We naively defined a `SudokuValue` as:

```rust
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
struct SudokuValue(Option<NonZeroU8>);
```

We use `NonZeroU8` to take advantage of the niche filling optimization from
`Option`, this way `mem::sizeof<Option<NonZeroU8>>() == mem::sizeof<u8>`.

To adapt to our new definition we will instead use:

```rust
#[derive(Debug, Clone)]
enum AugmentedValue {
    Fixed(NonZeroU8),
    Possible(HashSet<NonZeroU8>),
}
```

The `NonZeroU8` is no longer needed, but as `0` is not a valid Sudoku value, we
will keep it.

To match with this `AugmentedValue`, we will create an `AugmentedSudoku` that
uses `AugmentedValue`s instead.

We can now transparently convert between a `Sudoku` and an `AugmentedSudoku`:

```rust
impl From<Sudoku> for AugmentedSudoku {
    fn from(value: Sudoku) -> Self {
        let all: HashSet<NonZeroU8> = (1..=value.order()).collect();
        Self::new(value.data.mapv_into_any(|val| {
            if let Some(value) = val.0 {
                AugmentedValue::Fixed(value)
            } else {
                AugmentedValue::Possible(all.clone())
            }
        }))
    }
}

impl From<AugmentedValue> for SudokuValue {
    fn from(value: AugmentedValue) -> Self {
        if let AugmentedValue::Fixed(value) = value {
            SudokuValue(Some(value))
        } else {
            SudokuValue(None)
        }
    }
}

impl From<AugmentedSudoku> for Sudoku {
    fn from(value: AugmentedSudoku) -> Self {
        Self::new(value.data.mapv_into_any(|val| val.into()))
    }
}
```

We can now implement our solve based on the `AugmentedSudoku`:

```rust
fn augmented_solve(sudoku: &mut AugmentedSudoku) -> ControlFlow<()> {
    let Some((ix, possible)) = sudoku.data.indexed_iter().find_map(|(ix, val)| {
        if let AugmentedValue::Possible(val) = val {
            Some(val.clone())
        } else {
            None
        }
    }) else {
        if sudoku.solved() {
            return ControlFlow::Break(());
        } else {
            return ControlFlow::Continue(());
        }
    };

    for value in possible {
        *sudoku.data.get_mut(ix).unwrap() = AugmentedValue::Fixed(value);

        if sudoku.valid() {
            augmented_solve(sudoku)?;
        }
    }

    *sudoku.data.get_mut(ix).unwrap() = AugmentedValue::Possible((1..=sudoku.order()).collect());

    ControlFlow::Continue(())
}
```

But this is basically a copy paste of the `naive_solve` algorithm, the value
from this is that we can update the `possible` set in a cheaper way  while
culling the a huge amount of possibilities:

```rust
impl AugmentedSudoku {
    fn prune(&mut self) {
        let fixed_cols = self.data.columns().map(|col| {
            col.filter_map(|val| {
                if let AugmentedValue::Fixed(val) = val {
                    Some(val)
                } else {
                    None
                }
            }).collect::<HashSet<_>>()
        });

        // Remove fixed values in the same column
        for col, fixed in self.data.mut_columns().zip(fixed_cols.into_iter()) {
            for value in col.iter_mut() {
                if let AugmentedValue::Possible(set) = value {
                    set -= fixed;
                }
            }
        }

        // Repeat for rows and cells
    }
}
```

We can also perform a cheaper prunning each time we fix a value:

```rust
impl AugmentedSudoku {
    fn fix_value(&mut self, ix: usize, value: NonZeroU8) {
        let (x, y, cell) = self.split_ix(ix);

        self.remove_possible_value_from_column(x, value);
        self.remove_possible_value_from_row(y, value);
        self.remove_possible_value_from_cell(cell, value);
    }
}
```
