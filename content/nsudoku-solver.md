+++
title = "N-Sudoku Solver"
date = "2023-03-21"
description = "A Generalized Sudoku solver In Rust"
[taxonomies]
tags = ["sudoku", "rust", "programming"]
+++

This is an in progress blog post about my sudoku solver:
[nsudoku-solve](https://github.com/jalil-salame/nsudoku-solver)

<!-- more -->

# N-Sudoku Solver

## What is a Sudoku Puzzle?

Sudoku is a fun puzzle, if you somehow are reading this without knwing how it
works you can check the [Wikipedia Page](https://en.wikipedia.org/wiki/Sudoku)
about it, or see my short explanation on it below, otherwise you can skip until
the [next section](#implementation).

### Explanation

A Sudoku puzzle is typically composed of square cells forming a bigger square,
the normal puzzle is a 9×9 square composed of 3×3 cells, but it can have any
cell size, starting at 1×1, and going up to N×N.

The 1×1 Sudoku is trivial, it looks like this when solved:

```
1×1 Sudoku
+---+
| 1 |
+---+
```

A more interesting, but still simple example is a solved 2×2 Sudoku:

```
2×2 Sudoku
+-----+-----+
| 1 2 | 3 4 |
| 3 4 | 1 2 |
+-----+-----+
| 2 1 | 4 3 |
| 4 3 | 2 1 |
+-----+-----+
```

The important details are that every row, column and cell must have the numbers 1 up to 4 only
once:

```
2×2 Row
| 1 2 | 3 4 |
```

```
2×2 Column
-
1
3
-
2
4
-
```

```
2×2 Cell
+-----+
| 1 2 |
| 3 4 |
+-----+
```

This remains valid for all Sudokus; a 9×9 Sudoku has numbers 1 through 9 in its
cells, a 100×100 Sudoku has numbers 1 through 100 in its cells.

Keeping this invariant makes it possible to solve Sudokus; for example, solving
a 2×2 cell can be done like this:

```
2×2 Cell
+-----+
| 1 . |
| 3 4 |
+-----+
```

We can see there is a `2` missing, thus we can fill the empty spot:

```
2×2 Cell
+-----+
| 1 2 |
| 3 4 |
+-----+
```

That is the basics, we will go through more advanced techniques in the
implementation section.

## Implementation

### Representing a Sudoku in Rust

In order to solve the Sudokus, we first need to have an in memory representation
of the puzzles, that is what we will be going over in this section, if you are
familiar with Rust and can imagine how to represent a Sudoku then you can
probably skip over this section.

#### Rust Arrays

A simple way to represent a 2×2 Sudoku would be using Arrays inside Arrays,
commonly called 2D Arrays, which are part of the N-Dimensional Array family.

Representing our example 2×2 Sudoku using 2D Arrays would look like this:

```rust
// 2×2 Sudoku
// +-----+-----+
// | 1 2 | 3 4 |
// | 3 4 | 1 2 |
// +-----+-----+
// | 2 1 | 4 3 |
// | 4 3 | 2 1 |
// +-----+-----+
let sudoku = [
        [1, 2, 3, 4],
        [3, 4, 1, 2],
        [2, 1, 4, 3],
        [4, 3, 2, 1],
    ];
```

Contrary to your intuition if you come from a garbage collected language like
Java, C# or Python, this is not incredibly innefficient; 2D arrays in most
languages are very innefficient as you end up having an array of
pointers/references, an array of references is not ideal as you have to read two
references in order to access one element (the reference to the array, and the
second reference because its an array of references).

Here it is not a problem as arrays are stack allocated in Rust, therefore this
is a contiguous chuk of memory, manipulating it will make your CPU very happy.
It does have some pretty big drawbacks though:

1. Stack space is limited.

   We plan to support 225×225 Sudokus, which are pretty big (our future
   implementation would use 50,625B just to store the values).

   The stack in Linux has a 8MiB size by default which would fill after ~165
   Sudokus, we could easily have more Sudokus in memory than that.

2. You need to know the size of stack elements beforehand.

   In Rust you can't have dynamically sized types on the stack, therefore you
   must have a generic Sudoku struct in order to support this, sadly you need
   _const generics_ in order to have an ergonomic implementation, this is
   currently (2023-03-21) an unstable Rust feature, so we will not be using it.

   It also requires us to use a different type for each Sudoku size, which would
   be a pain to implement a CLI around.

For the above reasons we will instead be using the heap to store the Sudoku
values, this is not as limiting as the Stack, but tends to be slower.

I could implement a relatively generic 2D Array on the heap myself, but we want
to imlpement a Sudoku solver, not an efficient 2D Array, so we will use an off
the shelf solution: [`ndarray`](https://lib.rs/crates/ndarray), if you are
familiar with `numpy`, then `ndarray` is just the efficient arrays, most other
linear algebra/statistics operation are build on top of `ndarray` and published
as separate crates (Rust packages).

#### Sudoku Values

Our values are dependent on the size of the Sudoku: for a N×N Sudoku, it allows
values between 1 and N inclusive (in Rust syntax: `1..=N`), as it is never 0, we
can try using one of the [NonZero*](https://doc.rust-lang.org/std/num/index.html)
Rust integer types, the smallest one, NonZeroU8, fits our needs:

- A NonZeroU8 represents values between 1..=255, this means that the biggest
  Sudoku we can represent is a 15×15 Sudoku, I will accept this as big enough.
- Bigger Sudokus use `O(N²)` more memory, so it easily becomes impractical to
  run most algorithms in my Laptop's 8GiBs of RAM.
- NonZero* has the added benefit of making some Rust enums smaller; specifically
  `Option<NonZero*>` is guaranteed to have the same size as `NonZero*`.

Using the newtype idiom we can create a SudokuValue type:

```rust
pub struct SudokuValue(NonZeroU8);
```

This prevents our type from being treated as a NonZeroU8, it makes no sense to
support most operations on integers on SudokuValues so we might as well stop
ourselves from using them at the type level.

We can bring back some operations that we do want though:

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct SudokuValue(NonZeroU8);
```

If you are not familiar with Rust, these are
[derive macros](https://doc.rust-lang.org/reference/procedural-macros.html#derive-macros),
in simple terms, they automatically implement some functions on our types:

- `Debug`: Allows debug formatting of our types:
  `println!("{my_debug_type:?}")`.
- `Clone`: Allows our types to be cloned (create an in memory copy of the type).
- `Copy`: Signals that `clone` is cheap (no additional logic/small type), and
  that the values of this type should be copied, not moved.
- `PartialEq/Eq`: Allows our type to be compared to itself (`my_type ==
  my_type_too`).
- `Hash`: Allows our type to be hashed/used in a hashed collection
  (HashSets/HashMaps).

#### Full Sudoku Puzzle

With this background we can now represent the full Sudoku Puzzle:

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Sudoku {
    grid_w: usize,
    values: Array2<Option<SudokuValue>>,
}
```

We keep the grid width inside the structure, as a Sudoku has three important
values:

1. The grid width

   Used to compute the size of the grids (a 9×9 Sudoku has a 3×3 grid of 3×3
   cell chunks)

2. The _order_ of the Sudoku, ie. 9 for a 9×9 Sudoku

   Used to compute the valid values (ie. 1..=9 for a 9×9 Sudoku).

3. The number of cells in the Sudoku (ie. 81 for a 9×9).

   Used to iterate over all the cells/create the Sudoku itself.

If you stare at these values for a bit, you can see their relationship: the
_order_ is just the _grid width_ squared, and the number of cells, is just the
_order_ squared, therefore:

- `order = grid_w²`
- `num_cells = order² = grid_w⁴`

An interesting fact about computers is that calculating the square of a number
is much faster than calculating the square root, especially for integers, Rust
also doesn't have a way to express the integer square root of a number so you'd
have to cast the number to a floating point value calculate the square root, and
then cast it back to an integer, this is prone to errors for big integers and is
awkward to write:

```rust
let grid_w = (num_cells as f64).sqrt().sqrt() as usize;
```

Therefore, storing the `grid_w` makes it easy to derive the _order_ and number
of cells, without having to resort to casting values to floats.

Lets also implement some nice methods on our Sudoku struct:

```rust
// Helpful methods
impl Sudoku {
    pub fn empty(grid_w: usize) -> Self { todo!() }
    pub fn try_empty(grid_w: usize) -> Result<Self> { todo!() }
    pub unsafe fn empty_unchecked(grid_w: usize) -> Self { todo!() }

    pub fn new(grid_w: usize, values: Vec<Option<SudokuValue>>) -> Self { todo!() }
    pub fn try_new(grid_w: usize, values: Vec<Option<SudokuValue>>) -> Result<Self> { todo!() }
    pub unsafe fn new_unchecked(grid_w: usize, values: Vec<Option<SudokuValue>>) -> Self { todo!() }
}
```

Implementing `empty_unchecked` should be the easiest one to check off:

```rust
/// Create an empty Sudoku with grid width `grid_w`
///
/// # Safety
///
/// The grid width (`grid_w`) must be valid (`Self::valid_grid_width`)
pub unsafe fn empty_unchecked(grid_w: usize) -> Self {
    // debug: Make sure invariants are met
    debug_assert!(Self::valid_grid_width(grid_w), "Invalid grid width");
    Self {
        grid_w,
        values: Array2::default((grid_w * grid_w, grid_w * grid_w)),
    }
}
```

We assume that `grid_w` is valid and create a 2D Array of size grid_w²×grid_w²,
we mark this function as _unsafe_ because the rest of the code assumes that
`grid_w` is valid, so we might do something wrong if we don't check it.

Sometimes we can be sure that `grid_w` is right (ie. if we already have a Sudoku
and are using its `grid_w` to create a new empty Sudoku). This way we can skip
checking invariants which are upheld elsewhere. Checking the invariant is simple
though so we do still check it in debug builds to help with debugging if you do
end up using this function wrong.

`try_empty` is the next one we will implement:

```rust
/// Create an empty Sudoku with grid width `grid_w`
///
/// Returns `Err` if the `grid_w` is invalid (`Self::valid_grid_width`)
pub fn try_empty(grid_w: usize) -> Result<Self> {
    Self::valid_grid_width(grid_w)
        .then(|| {
            // Safety: we check that the `grid_w` is valid
            unsafe { Self::empty_unchecked(grid_w) }
        })
        .ok_or(SudokuError::InvalidGridWidth { grid_w })
}
```

We first check the grid width, if it's valid we can call `new_unchecked` safely,
otherwise we return an error.

This makes the implementation of `empty` dead simple:

```rust
/// Create an empty Sudoku with grid width `grid_w`
///
/// **Panics** if `grid_w` is not valid (`Self::valid_grid_width`)
pub fn empty(grid_w: usize) -> Self {
    Self::try_empty(grid_w).unwrap()
}
```

We just unwrap the value in `try_empty`, this exists the program with an error
message if there is an error.

Having such a flexible API is overkill for this program, but as it is just a
learning process, doing it right is also part of the process.

Now that we have an idea of how to do this for `empty`, I will only show you how
to do `try_new`, and you can probably implement the panicking and the unsafe
version yourself:

```rust
/// Create a Sudoku with grid width `grid_w` with the provided values
///
/// **Fails**
///
/// - `grid_w` is invalid
/// - `values.len()` is not `grid_w⁴`
/// - The values are not valid for the size of the Sudoku
pub fn try_new(grid_w: usize, values: Vec<Option<SudokuValue>>) -> Result<Self> {
    Self::validate_grid_width(grid_w)?;
    // Make sure all values are in the correct range and comply with the Sudoku invariants
    Self::validate_values(grid_w, &values)?;
    // Safety: we check invariants beforehand
    Ok(unsafe { Self::new_unchecked(grid_w, values) })
}
```

This function is very boring as all the interesting stuff happens inside
`Self::validate_values`:

```rust
/// Checks if there are enough values and all values are valid for the specified Sudoku size
pub fn validate_values(grid_w: usize, values: &[Option<SudokuValue>]) -> Result<()> {
    // Correct number of values
    let expected = grid_w * grid_w * grid_w * grid_w;
    if values.len() != expected {
        return Err(SudokuError::InvalidValuesAmount {
            len: values.len(),
            expected,
        });
    }
    // Values are Valid
    if let Some(value) = values
        .iter()
        .copied()
        .flatten()
        .find(|&value| !Self::valid_value(grid_w, value))
        .map(|value| value.0.get())
    {
        return Err(SudokuError::InvalidValue {
            value,
            max: grid_w * grid_w,
        });
    }
    let mut vals = Vec::with_capacity(grid_w * grid_w);
    let xs = ArrayView2::from_shape((grid_w * grid_w, grid_w * grid_w), values).unwrap();
    // Verify Rows
    Self::validate_rows_scratch(xs, &mut vals)?;
    // Verify Columns
    Self::validate_columns_scratch(xs, &mut vals)?;
    // Verify cells
    Self::validate_cells_scratch(grid_w, xs, &mut vals)
}
```

The code is prtty linear:

1. We assert that the number of values is grid_w⁴.
2. We assert that the values are in the valid range (1..=grid_w²).
3. We assert that there are no duplicate values in the rows, columns or cells.

Using the `?` operator we forward the errors returned by the `Self::validate_*`
functions, these unctions also take a buffer which we initialize appropriately to
make sure it is only allocated once, this prevents many small allocations.

All three `validate_*` functions are very similar so we will only look at the
`Self::validate_rows_scratch` function:

```rust
/// Validate the Sudoku invariants on the rows
///
/// More Efficient as it doesn't need an extra allocation if you already have a buffer
fn validate_rows_scratch(
    values: ArrayView2<Option<SudokuValue>>,
    vals: &mut Vec<Option<SudokuValue>>,
) -> Result<()> {
    if let Some((iy, ix)) = Self::invalid_sudoku_axis(values.rows(), vals) {
        return Err(SudokuError::WrongValueSet { pos: (ix, iy) });
    }
    Ok(())
}

/// Check if a Sudoku axis has an invalid value
///
/// Returns the index of the axis, and the index of the offending element in a tuple
///
/// An axis could be a row, column or cell
///
/// Passing an appropriately sized (grid_w²) vector as scratch, makes this function not allocate
/// any extra space
fn invalid_sudoku_axis<'a, T, I>(
    axis: impl IntoIterator<Item = I>,
    scratch: &'a mut Vec<T>,
) -> Option<(usize, usize)>
where
    I: IntoIterator<Item = &'a T>,
    T: PartialEq + Copy,
{
    for (i, a) in axis.into_iter().enumerate() {
        scratch.clear();
        scratch.extend(a.into_iter().copied());
        if let Some(j) = Self::duplicate_value_position(scratch) {
            return Some((i, j));
        }
    }
    None
}

/// If there is a duplicate value, return its index
fn duplicate_value_position<T: PartialEq>(vals: &[T]) -> Option<usize> {
    vals.iter()
        .enumerate()
        .position(|(i, val)| vals[i + 1..].contains(val))
}
```

`Self::validate_rows_scratch` is a soft wrapper around `Self::invalid_sudoku_axis`
that returns a nice error message, invalid_sudoku_axis is generic over the axis,
whether it is the rows, columns or cells, it will still find duplicate values in
them, to do this it takes a single row/column/cell and collects it into a
vector, then it goes over the vector searching for the position of a duplicate
value, returning the index of the axis and the duplicate value.

With this we can finally represent a Sudoku in memory.

You can look at the full code up to this point in
[this repository](https://github.com/jalil-salame/nsudoku-solver/tree/v0.1.0)
(it has extra tests and helper functions which were not discussed, ie. a
function to pretty print Sudokus).

The code we have discussed lives in `libnsudoku-solver/src/lib.rs`.

I will continue expanding this post in the near future once I add the CLI and
solver code, but I will leave it here for now.
