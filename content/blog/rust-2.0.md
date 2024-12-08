+++
title = "What should a Rust 2.0 look like?"
date = "2023-07-15"
description = "My thoughts on a successor language to Rust"
[taxonomies]
tags = ["rustlang", "rust", "language-design"]
+++

I have used Rust for about 1.5 years now, and the hype has
settled. Although I am pleased with the language, I do think it is by
no meas perfect, this is a meta post about all the improvements I think
could be made to it.

<!-- more -->

# What should a Rust 2.0 look like?

## Do we want a Rust 2.0?

I don't think so, a lot of the thoughts I will present are not backwards
compatible in a way that would split the language Python 3.0 style.

The great thing about the current Rust ecosystem is that you can get a
crate for just about anything:

- Parsing: `winnow`
- Serialization: `serde`
- CLI interfaces: `clap`
- Easy Enum errors: `justerror`
- N-Dimensional Arrays: `ndarray`
- More Powerful Iterators: `itertools`
- Web Server: `axum`
- Middleware: `tower`
- HTTP client: `reqwest`
- Async Executor Ecosystem: `tokio`

But if you look at that list, you can split it in half easily;

From `winnow` to `itertools`, those are crates I wouldn't mind using
even if they didn't get major updates; they are still relevant without
new updates, sure, they might have problems down the line, the macro
system is fragile, but they would still be relevant, with few real severe
security bugs.

`axum` to `tokio` on the other hand do need constant updates, they depend on the
Web, which is ever changing, and they therefore need constant updates in order
to keep in line with the ecosystem.

So on one hand we have "static" crates, crates which once they implement the
needed functionality no longer need to be updated besides minor bugfixes, and
"dynamic" crates that depend on external factors and thus need to constantly
adap to their ecosystem.

This means that a breaking change impacts the ecosystem heavily, for a "static"
crate, the maintainer might have moved on, and thus someone new would have to
take on the hat and reimplement version 2.0 of that crate, for a "dynamic"
crate, they might have many users still relying on Rust 1.X, thus development
effort might need to be split between a 2.0 compatible version and a 1.X
compatible version.

Therefore I am only speking in hindsight, so we can discuss the decisions that
we now disagree with, and maybe if someone (future me maybe?) decides to
implement a language, they can learn from that and use it as a guide.

## The Language

- [Rust Refs](@/blog/rust_references.md)

## Crates.io

- [Namespacing](@/blog/crates.io_namespacing.md)

## The Ecosystem
