+++
title = "Rust's missing Reference type"
date = "2023-07-15"
description = "Thoughts about a missing reference type in Rust"
[taxonomies]
tags = ["rustlang", "rust", "language-design"]
+++

Rust references are great `&` is a real `const*` and `&mut` being exclusive
makes so much sense, but there is a missing reference type, do you know whaich
one it is?

<!-- more -->

# Rust's missing Reference type

## Rust References

When I talk about references, I mean specifically the two types supported at a
syntax level:

- Immutable references (aka shared references `&`)
- Mutable references (aka unique references `&mut`)

They have some nice properties:

- They are non-null
- They are pointing to a valid region of memory
- They have the right alignment for the type they are pointing to
- The data they point to is initialized

This means you can always pass them around safely, without having to think about
the previous points, and that is great!

We can also see that `&mut >> &` and thus anything that you can do with
`&`, you can also do with `&mut`. Look at this table:

| Action     | `&mut` | `&` |
|------------|--------|-----|
| `read`     | ✓      | ✓   |
| `write`    | ✓      | ✗   |
| `copy ref` | ✗      | ✓   |

It might seems like I just contradicted myself by saying that a `&mut` is more
powerful than a `&`, because you can't copy a `&mut` reference, but you can copy
a `&` reference. That is not a problem though, because `&mut` is unique, we can
temporarily invalidate it, and get a `&` to it, this `&` can be copied as many
times as we'd like, and once we are done with it, our original `&mut` will
become valid again.

Now seeing this table you might be able to guess what the missing reference type
is, if you haven't yet, take a minute to think about it.

## Possible reference types

We have three things that we can do with our references:

- copy them
- read the underlying type
- (partially) overwrite the underlying type

Memory safety makes copying references depend on them being writeable so we only
have two degrees of freedom:

| Action     | `&mut` | `&` | `?` | `?` |
|------------|--------|-----|-----|-----|
| `read`     | ✓      | ✓   | ✗   | ✗   |
| `write`    | ✓      | ✗   | ✓   | ✗   |

We can now fill in the `copy ref` action based on whether the references are
writeable:

| Action     | `&mut` | `&` | `?` | `?` |
|------------|--------|-----|-----|-----|
| `read`     | ✓      | ✓   | ✗   | ✗   |
| `write`    | ✓      | ✗   | ✓   | ✗   |
| `copy ref` | ✗      | ✓   | ✗   | ✓   |

And vóila, we have two new reference types! Wait, then why did I say there was
only one missing type? Well, look at the last one, the only thing you can do
with it is copy it around, if you have a use for that, feel free to tell me, but
I don't. The other one is more interesting, I will name it `&out`, for no
*particular* reason.

### Out references

So... what are out references? And why are they useful?

Well, I'm glad you asked, because this is what this post is all about!

Out references, are write only references, they are useful to initialize values,
think of them like a superpowered `MaybeUninit<T>`.

Sometimes you have some storage, it might be a buffer, it might be a `Box`, I
don't care, but you want a function to fill this space. You might not want to
initialize it to a specific value because it is inefficient. Or you might want a
safer thing, something that can remind you if you missed a field in a struct
instead of leaving it uninitialized.

Welcome to the *worst* Rust trait, I might be exaggerating a bit, but I really
don't like it:

```rust
pub trait Read {
    // Required method
    fn read(&mut self, buf: &mut [u8]) -> Result<usize>;

    // Provided methods

    // skipped ...
}
```

That's right, see that signature `&mut buf [u8]` (*shudders*), I see it in my
worst nightmares. In order to `Read` data, be that from a network socket, a
normal file, whatever you want to read from, you need to provide it a
**initialized** buffer, because god forbid if you didn't; UB ensues. Do you see
the last rule I outlined for references? The data they point to has to be
initialized.

Now, everyone relies on `Read` allowing you to pass a uninitialized buffer of
bytes and does it anyways, therefore, the rust team must be very careful to not
accidentally optimize their code wrongly.

What would be better? I am happy to tell you, that our darling `&out` solve
this:

```rust
pub trait Read {
    // Required method
    fn read(&mut self, buf: &out [u8]) -> Result<usize>;

    // Provided methods

    // skipped ...
}
```

Because `&out` refs are write-only there is no risk of reading uninitialized
values, and we can lift that restriction. You can also have some extra language
level support of them by requiring a function to fully initialize the `&out`
pointer before returning, thus making `assume_init` safe, on values that have
been passed to `&out` refs.

They do have some nasty edge cases though.

### Nasty side of `&out` refs

#### How do you deal with errors?

Ideally, if you return an error, the `&out` ref should stay uninitialized,
this would mean lifting `Result` from the standard library to the
compiler, as it would need special handling.

The ugly way to handle this you be to have a fallible `&out`, that means an
`&out Result<T, Err>`, where you always have an initialized result, but the
caller would need to additionally allocate space for the `Result` type, which is
a very bad way of handling this.

#### How do you deal with arrays?

Ironically, our `Read` example also fails under this simplistic `&out` model.
`Read` return a `usize` which indicates what amount was written to the buffer,
this means the buffer is only valid in `buf[..len]`, and only if the read
operation was successful.

This means that we would need some way of telling the compiler that an `&out`
ref is valid only in a certain range.

## Conclusion

I think `&out` refs are valuable and would solve a lot of problems with
`MaybeUninit`, when working in constrained environments like embedded devices or
the kernel. You need tighter control over your storage, not everything can go
on the stack.

Therefore, you might need to initialize resources directly on the heap and for
that, the current tools are wildly inconvenient.

Still, the proposed problems are very bad edgecases, and I don't think `&out`
refs should be added without atleast solving them. And the many more things I
have overlooked.
