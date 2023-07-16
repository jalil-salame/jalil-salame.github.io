+++
title = "Crates.io Namespaces"
date = "2023-07-15"
description = "My thoughts on crates.io namespaces"
[taxonomies]
tags = ["rust", "crates.io", "language-design"]
+++

Crates.io is great in many ways, but falls short in some important
places. This are my thoughts on missed oportunities and *interesting*
design decitions.

<!-- more -->

# Crates.io

Crates.io is the default package registry of
[cargo](https://github.com/rust-lang/cargo) which is the package manager
and build system of Rust.

I have thoughts about cargo too, but lets keep this blog post on point
by just speaking about the package registry.

Crates.io gets a lot of things right; any package uploaded is read-only:

If you want to patch a version because of a bug or vulnerability,
you have to upload a new version.

There is no way to delete a package version from the registry; you can
*yank* it, but that only makes it so that you can't pull that version
when adding a new dependency.

This ensures that your code won't break if you are already using the
yanked version, and makes sure that new users of the package will not
be using a vulnerable version.

Now, onto the bad...

## Namespaces

If you have used GitHub, then you know about these, for example, this
website is under the `jalil-salame/jalil-salame.github.io` namespace,
this means, that the repo itself is `jalil-salame.github.io` and the
namespace is `jalil-salame` (my GitHub username), this means I can create
any project, with whatever name I want, and have it under my namespace.

This prevents name collisions, think of Discord's original handles,
rest in peace, `username#9999`. You could have the username you wanted,
and you'd get a number to disambiguate with other users.

### Why do you want namespaces?

Well, for one thing, you don't have to come up with weird names for your
library, just look at the Rust JSON libraries:

| Library                   | Experimental? | Last update      |
|---------------------------|---------------|------------------|
| `json`                    | no            | 3 years ago      |
| `json_minimal`            | yes           | 3 years ago      |
| `another_json_minimal`    | yes           | 1 year ago       |
| `serde_json_experimental` | yes           | 5 years ago      |
| `alt_serde_json`          | no            | 2 years ago      |
| **`serde_json`**          | **no**        | **14 hours ago** |

You obviously want to use `serde_json`, this is however not intuitive:

When I searched for `json` in crates.io (https://crates.io/search?q=json),
`serde_json` was the 8th result, it wasn't even on the page until you
scrolled down.

lib.rs, an alternate frontend to crates.io, does this a bit better.

There `serde_json` is the first result: https://lib.rs/search?q=json. It
also has a better UI in my opinion, but that is besides the point.

How come the standard way to interact with JSON isn't with the `json`
library?

I don't know the details of what happened, but for some reason, the
owner of the `json` crate, did not give up the name to the people from
`serde_json`, maybe they were busy, maybe they lost the password, maybe
he had bad intentions about it.

The point is, this only happened because crate names had to be unique.

What if you had namespaces?

Then serde would've probably have had it's own namespace, and `serde_json`
would have been `serde/json`, a CBOR library `serde/cbor`, pickling
library? `serde/pickle`, you get my point.

This would make naming crates muche easier, and allow to have some project
backed libraries.

For example, the Rust library team doesn't want to take too much work into
the standard library as it is tied to the compiler version. Therefore
although a lot of libraries are maintained by the same people as the
Rust standard library, they are part of crates.io instead of the standard
library with no plans of ever merging them into it.

Some notable names are:

- `libc`: bindings to the C standard library
- `regex` and `regex-syntax`
- `cc`: compile C code with cargo
- `backtrace`: acquire a backtrace from a Rust program

With namespaces these could've been `rust/libc`, `rust/regex`, etc. Making
it clear that they were endorsed by the rust project.

Basically, namespaces make libraries with better names (`serde/json` vs
`user1234/json` instead of `serde_json` vs `json`) and provides a way
to officially back certain projects, by organizations or libraries.

This would make it slightly more annoying to write the dependencies,
but it could prove to be a nice opportunity to keep things organized:

```toml
[dependencies]
libc = "0.2"
cc = "1.0"
serde_json = "1.0"
cbor = "0.4"
```

vs

```toml
[dependencies.rust]
libc = "0.2"
cc = "1.0"
[dependencies.serde]
json = "1.0"
cbor = "0.4"
```

I feel like the additional difficulty of writing
`[dependencies.namespace]` is worth the extra safety and better naming
that this provides.

## Conclusion

You can actually name the library whatever you want, and not whatever
is available. If you have a project with special requirements and need
your own JSON implementation, you can get the `myproject/json` name,
and have a nice and tidy `Cargo.toml`:

```toml
[dependencies.myproject]
server = "1.0"
json = "1.0"
api = "1.0"
```

You can clearly spot that you are using the project's JSON crate, and
not some outside dependency, thus it *should* work properly.

Now, namespaces themselves may be subject to *name squatting*, but then
the registry itself might impose rules on the namespaces themselves:
for example, prefixing user namespaces with `u-` or `user-`, so that
people can't conflict with common namespaces by changing their username
to something like `json`, and have a review process for when someone is
creating a non-user namespace.

This should come with some verification to ensure the namespace is
either free by not having anything with that name, or is part of the
organization ie. Google or AWS.

But that is something the registry should worry about.

Anyways, the crates.io ship has already sailed, but if you are making
your own language, keep this in mind and maybe add namespaces to your
standard registry?
