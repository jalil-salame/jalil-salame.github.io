+++
title = "Package repositories and mirroring"
date = "2026-01-23"
description = "Thoughts on package mirrors and modern programming languages"
[taxonomies]
tags = ["programming", "language-design", "package-repositories", "package-managers"]
+++

Modern programming languages include package managers and package repositories,
but they seem to forget about the learnings from older system package managers
that are system package managers and the tool they use to reduce the load on
their infrastructure: repository mirrors.

<!-- more -->

If you want to go straight to the laundry list of features I consider important,
you can skip the rest and go
[here](#i-wanna-build-a-package-manager-do-you-have-some-recommendations).

## Mirrors? Aren't those reflective surfaces?

Unless you've been around the internet in the early 2010s or delved deep into
Linux, you might not be familiar with the concept of [mirror sites]. These are
full or partial copies of another website hosted under a different URL.

[mirror sites]: <https://en.wikipedia.org/wiki/Mirror_site> "Wikipedia article
about mirror sites"

For example, at the time of writing, the Technical University of Freiberg hosts
a mirror of the Arch Linux package repository, as does the Technical University
of Ilmenau and the RWTH Aachen. If you happen to study at any of those
Universities (or live near them), you should use their mirrors, your Arch
package updates will be very fast.

These mirrors were created since a lot of the time, donating infrastructure is
easier than donating money and it does improve the experience of downloading
packages for the people hosting the mirrors (since they are physically closer to
the download website).

One of the wonderful side effect of this is that the bandwidth cost of hosting
the main package repo is shared with the mirrors. For open source projects with
limited funding, this is an essential way to keep the costs down.

### Small aside on Security

Now, that's all well and good, but how do you ensure you aren't downloading
malware from the mirror? After all, they could switch a package with a virus and
you wouldn't be able to notice... right?

Not really, most linux package repositories sign their packages with a set of
trusted keys, thus mirrors would need to sign the viruses with the main repo's
keys, which isn't possible unless the main repo's keys are compromised.

{% aside() %}
  If the keys are compromised, you probably have more issues than malware on the
  mirrors and you can easily revoke and rotate the compromised keys.
{% end %}

Even if the packages aren't signed, you could trust the mirror by trusting the
organization that runs the mirror. If you were a student of the RWTH Aachen, you
might be acquaintanced with the person running the mirror and thus would trust
that they wouldn't distribute malware through it. This is specially applicable
to private mirrors, which I will advocate for later on.

## How does this benefit my favorite programming language?

A while ago, NixOS had an issue with [funding][NixOS funding issue] for their
distributed cache, specifically, once the sponsor they had for the S3 storage
decided to stop the sponsorship they needed to reach out for more funding and
looked into ways to reduce the amount spent on S3 (by deleting old files or
reducing redundant downloads).

[NixOS funding issue]: <https://discourse.nixos.org/t/2025-s3-sponsorship-more-resources-for-a-sustainable-nix/67019> "Discourse thread asking about solutions for funding the storage for cache.nixos.org"

{% aside() %}

Although, <https://cache.nixos.org> is _technically_ a cache, since NixOS is a
source base distribution, I would cosider it equivalent to a package
repository.

{% end %}

Rust's [crates.io] receives about half a billion daily downloads, so I would
expect it's bill to be similar if not bigger than NixOS. Since Rust has stronger
funding and services like Amazon's S3 rely on Rust, I doubt it will have any
funding issues with [crates.io] specifically, but a newer programming language
will have to consider how to fund it's package registry.

[crates.io]: <https://crates.io> "Rust's main package registry; crates.io"

Mirrors are a low cost way to reduce traffic to the main repository by
redirecting it to a different server and I believe moreecosystems would
benefit from supporting mirrors in a more overt way.

[Docker](https://www.docker.com) is probably the best example of an ecosystem
adding [rate limits][Rate limit announcement] to it's main package registry and
requiring heavy users to use mirrors instead. I don't know if this was due to
funding issues or due to VC preassure, but the end result is that CI systems
needed to setup mirrors to stop themselves from hitting the rate limits.

[Rate limit announcement]: <https://www.docker.com/blog/revisiting-docker-hub-policies-prioritizing-developer-experience/> "Rate limit announcement post"

Mirrors deduplicate requests for a specific package; the mirror is a single,
albeit heavy, user of the main package repository, but it can serve hundreds or
thousand of users, reducing the load on the main package repository.

### Aside on registries and repositories

I've been using the words interchangeably, but there is a small difference
between registries and repositories; registries hold the package metadata, while
repositories hold the actual package data.

Registries need to handle many small requests for metadata, thus they tend to be
throughput limited, while repositories need to handle fewer (but still many)
large transfers of data, so they tend to be bandwidth limited.

### Mirror security

{% aside() %}
Assuming you don't use a broken hash function like [md5] or [sha1].
{% end %}

[md5]: <https://en.wikipedia.org/wiki/MD5#Overview_of_security_issues>
"Wikipedia page on MD5 and its security issues"

[sha1]: <https://en.wikipedia.org/wiki/SHA-1#Attacks> "Wikipedia page on SHA1
attacks breaking its security"

If you want to have a secure mirror, you only need to sign the registry
metadata, since the metadata contains a hash of the package, signing it ensures
the package itself wasn't tampered.

### Packaging format

Some loose guidelines on packaging formats that you should follow (if I learn
more about this, I might even write a full blog post on the matter).

#### Metadata

Besides the usual name, version, description, etc. your package's metadata
should contain:

- <details><summary>A hash of the compressed package data</summary>

  This is used to verify the package download and, in case you sign the
  metadata, it also ensures the package hasn't been tampered with.

  There should be a hash for every compression scheme the package manager
  supports (e.g. `gz`, `zstd` and `brotli`).

  Consider embedding tool versions and compression options into the compression
  scheme name, in case a new version produces different compressed archives or
  you want to compress with higher settings without invalidating the previous
  hash.

  </details>

- <details><summary>Use a secure hash function</summary>

  Don't use insecure hash functions like [md5] or [sha1].

  </details>

- <details><summary>Think about the future</summary>

  Things like hash functions, signatures and compression schemes evolve, make
  sure your package metadata is able to evolve with them; specifically, you
  should consider allowing for multiple versions of each of these items:

  An example metadata format:

  ```jsonc
  {
    "metadata": {
      "name": "mypackage",
      "version": "1.2.3",
      // ...
      "hashes": {
        // format - version - compression-level
        "gzip-1.14-compress-1": {
          "sha256": "...",
          "sha384": "..."
          // ...
        },
        "gzip-1.14-compress-9": {
          "sha256": "...",
          "sha384": "..."
          // ...
        }
        // ...
      }
    },
    // Signatures over the metadata
    "signatures": {
      "ed25519": "...",
      "ecdsa-p256-sha256-asn1": "..."
      // ...
    }
  }
  ```

  </details>

- <details><summary>Publication date of the package</summary>

  [crates.io] [recently added it to it's registry][pubdate on crates.io]. Add it
  on day one so you don't have to deal with backwards compatibility issues.

  </details>

[pubdate on crates.io]:
<https://blog.rust-lang.org/2026/01/21/crates-io-development-update/#publication-time-in-index>
"Blog announcing adding the publication date of a package to the crates.io index"

#### Package data

Packages are usually a special directory structure with some extra information
wrapped in a tarball and compressed, this works well enough, but there are some
pitfalls.

- <details><summary>Make sure the tarball is reproducible</summary>

  Specifically, strip out the `*time` (`atime`, `ctime`, `mtime`, etc.) data
  from the files (set it to the UNIX Epoch). When decompressing, you can replace
  it with the publication date of the package.

  Sort the file names so they are always added in the same order. Tarballs add
  files in the specified order, which might be random depending on how your
  filesystem iterates over a directory. Sorting the files before adding them
  ensures this doesn't happen.

  You can copy nix's homework by looking at [NAR files] (Nix ARchives), which are
  an adaptation of the TAR format to make sure they are reproducible.

  </details>

[NAR files]: <https://nix.dev/manual/nix/2.33/protocols/nix-archive/index.html>
"NAR format specification"

- <details><summary>Prepare for multiple compression schemes</summary>

  A better compression scheme will appear, prepare for it by making your tools
  able to handle different compression/decompression schemes.

  </details>

## Types of mirrors

These are the types of mirrors I know of (and that I believe are important for
you to know about).

### Public Mirror

A public mirror is a mirror you can access through the internet without any
credentials.

The Arch package mirrors I mentioned are examples of public mirrors.

### Private Mirrors

These either need credentials or are inside a private network making them only
usable by a specific set of people.

Some organizations and individuals might run private mirrors to protect against
hostile takeovers of the main repo, or because the local network is faster than
the connection to the internet.

### Full Mirrors

These contain a copy of every package in the main repository, they are the most
common type of mirror in the Linux package mirror scene.

### Partial Mirrors

These contain a partial view of the packages in the main repository, for
example, they might only have 64-bit packages, or they might only have Python
packages.

I'm not familiar with public partial mirrors, IMHO, they make more sense for
private mirrors used by small organizations or individuals.

### Pull mirrors (caches)

These are [partial mirrors](#partial-mirrors) that only store packages that were
requested by a package managers (instead of using a curated list).

I believe these are the best mirrors for small organizations and individuals.

### Push mirrors

These are mirrors that receive updates via a push notification system; instead
of the mirror requesting a sync, it subscribes to updates from the main
package registry and only syncs when the main registry notifies it of an update.

I don't know about practical uses of this type of mirror, but it is included for
completeness.

## I wanna build a package manager, do you have some recommendations?

Why yes, I do! Here's a small list, loosely in order of importance for a
project:

- <details><summary><b>Provide an official(ly endorsed) mirror with your package manager</b></summary>

    It doesn't have to be great, but it should work and be supported by the
    ecosystem of tools.

    Having something is a great way to get people to build more of it, by
    providing a official way to mirror the main repository, you pave the way for
    others to build mirrors that better suit their needs.

  </details>

- <details><summary><b>Make the mirror easy to install/setup</b></summary>

    Ideally, you can test it by running `docker run my-mirror` maybe setting an
    env variable or two.

    A documented configuration file is mandatory, as well as documentation for
    common setups:

    - Running it behind a proxy (`nginx` and `caddy` as a bare minimum)
    - Running it with `docker`/`docker-compose`
    - Running it inside `kubernetes`
    - Running it inside `proxmox`
    - Running it as a `systemd` service
    - ~Running it as a NixOS module~ (I can dream T-T)

  </details>

- <details><summary><b>Make it easy to use a custom mirror</b></summary>

    Your package manager and associated tools should make it easy to use a
    custom mirror.

    Ideally this means you can set an environment variable with the mirror url
    (maybe as a list of fallbacks) and setup a default in a configuration file.

    Think about CI systems and how to make it easy for people to setup the mirror
    there.

    Example environment variable:

    ```bash
    export MYTOOL_MIRRORS="https://custom-mirror.example.com,https://fallback.example.com"
    ```

  </details>

- <details><summary><b>Also mirror associated tools</b></summary>

    In the case of Rust, you tend to download toolchains through `rustup` and
    packages through `cargo`. These tools are different, but a user who wants to
    cache packages will most likely also want to cache toolchains.

    Provide a way to cache both with the same software.

  </details>

-  <details><summary><b>Provide both a <a href="#full-mirrors">full</a> and a <a
    href="#partial-mirrors">partial</a> <a href="#pull-mirrors-caches">pull</a>
    mirror mode at least.</b></summary>

    A full mirror mode is required to fully distribute the load on the system,
    but small organization and individuals will probably lack the resources to
    store a full mirror of the main package repository, as they tend to be
    Terabytes in size (three years ago all of crates.io was about [half a
    Terabyte](https://the-lean-crate.github.io/waste/)).

  </details>

- <details><summary><b>Automatic syncing</b></summary>

    Check for new versions of the packages and update the mirror.

  </details>

- <details><summary><b>Efficient syncing</b></summary>

    Use an [Rsync] like method to allow to efficiently copy over an update to the
    mirror.

    [Rsync]: <https://en.wikipedia.org/wiki/Rsync> "Wikipedia page about Rsync"

  </details>

- <details><summary><b>Consider providing a private package registry as part of the mirror</b></summary>

    People who wish to run a mirror, will most likely also want to have a private
    package registry, making it simple to run a package registry alongside the
    mirror (maybe even making it part of the same project) is a great way to have
    people setup a mirror.

  </details>

- <details><summary><b>Big org wishlist</b></summary>

    These are things only big organizations would want, so its probably best to
    not optimize for it very early, but keeping these things in mind is good:

    - Filtering packages by license

      Many orgs are reluctant to use certain licenses

    - Filter by tags (e.g. disallow unsafe Rust)
    - Only allow manually vetted packages (specifically, new versions are not
      automatically synced)

      This would make new versions of a package behave like [yanked
      crates](https://doc.rust-lang.org/cargo/commands/cargo-yank.html#how-yank-works)
      in Rust.

    - Add a review UI

      Lets you browse the source code of a package and diff it with a previous
      version. This would making auditing new versions of the used packages
      easier.

  </details>

Once you've done this and the ecosystem has adepted to using mirrors, you can
consider setting heavy limits on your main package registry. E.g. you can only
do ten downloads of a specific package version and only 10k different packages
downloads per hour. Assuming your package manager caches the packages locally,
you can be sure only CI systems and orgs with many developers using the same IP
will be hitting these limits. These orgs are probably able to host their own
private mirror and would benefit from having a faster connection while reducing
the load on public infrastructure.

## Conclusion

I feel like we've forgotten about mirrors in the chase of scale. A programming
language's main package registry shouldn't handle Petabytes of data monthly, we
should distribute the load among that use it.

The biggest culprits are public CI systems like GitHub actions and organizations
with private CI systems or a large team of developers. In either case, they have
the resources to setup a mirror and reduce the load on public infrastructure
like the main package repository of a programming language.

If you are building a new package repository, consider providing tools to mirror
it, it might help reduce the load on your repo and justify aggressive rate
limiting to keep your infrastructure costs down.

I want the small web to be healthy and providing tools to reduce the load on
the public infrastructure seems like the best way I can help.
