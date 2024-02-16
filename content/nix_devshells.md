+++
title = "Direnv and Nix devShells: A match made in heaven"
date = "2024-02-10"
description = "Deep dive into nix dev shells"
[taxonomies]
tags = ["dev", "shell", "nix", "programming"]
+++

I use [NixOS][1] since last year and I recently started making
use of `devShells` (development shells). They are very useful and more people
should know about them! Especially in combination with
[`direnv`][2].

<!-- more -->

# Direnv and Nix devShells: A match made in heaven

Lets start with a quick introduction to the tools.

- [`direnv`][2]: A shell hook that runs when you enter a directory containing a
  `.enrvc` file.
- [`nix`][1]: The `nix` package manager. Works on (mostly) any Linux distro and
  MacOS.
- [`nixpkgs`][3]: The main `nix` packages repository.
- [`NixOS`][1]: A Linux distro based around `nixpkgs` and the `nix` package
  manager.
- `flakes`: An "experimental" (pretty much the default) feature of the `nix`
  package manager.
- `devShells`: A shell environment defined by a `flake` and created by `nix`.

## Obtaining the Nix package manager

Although [`nix`][1] has an installer, the DeterminateSystems's
[`nix-installer`][4] is faster, enables flakes out of the box, and is easier to
uninstall (although why would you want to do that?).

I recommend you install `nix` before proceeding so you can follow along c:.

## Obtaining direnv

You can install [`direnv`][2] through your distro's package manager, but you'll
need at least version `2.29` for the rest of this, so let's instead install it
through `nix`!

```console
$ nix profile install nixpkgs#direnv
```

Profiles are package sets that can be updated independently from each other. You
can install packages to your profile using `nix profile install`. The specific
package you want to install needs to be specified as a *Flake URI*.

> A Flake URI is the repository # the package. In the previous case we are
> installing `direnv` from [`nixpkgs`][3], so we specify `nixpkgs#direnv`. This
> will use the default `nixpkgs` version, but you could specify it explicitly:
> `nixpkgs/nixos-unstable#direnv` would install the `nixos-unstable` (latest)
> version of `direnv`. You could instead install `nixpkgs/nixos-23.11#direnv`
> which would install the current version of direnv in the stable channel
> (`nixos-23.11` as of time of writing).

Once you install [`direnv`][2] you should [hook it into your shell][5].

## Getting started with Flakes

Flakes are a simple file format used by [`nix`][1] to configure certain stuff.
They tend to be used to build packages, but today we will be using them to
create `devShells` instead:

```nix
{
  description = "A friendly introduction to devShells";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    devShells."x86_64-linux".default = { };
  };
}
```

The anatomy of a flake is very simple: We first add a friendly description
(optional). Then we specify the inputs by giving them a name and specifying
their url (the rules for urls are complicated, but we'll go through them when we
need to). Then we define the outputs in terms of the inputs (in this case only
`self` and `nixpkgs`). Note that a devShell needs to know which system it is
running on (`x86_64-linux` in our case), because it uses packages for that
specific operating system.

To create a `devShell` we need to first get a version of nixpkgs for our system:

```nix
{
  # ...
  outputs = { self, nixpkgs }: {
    devShells."x86_64-linux".default = (import nixpkgs { system = "x86_64-linux"; }).mkShell { };
  };
}
```

Let's remove some redundancy:

```nix
{
  # ...
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
    in
    {
      devShells.${system}.default = (import nixpkgs { system = system; }).mkShell { };
    };
}
```

And a bit more refactoring:

```nix
{
  # ...
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell { };
    };
}
```

And we arrive to a basic flake with an empty `devShell`:

```nix
{
  description = "A friendly introduction to devShells";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell { };
    };
}
```

Now, this is not very useful as of now. So let's add some packages:

```nix
{
  # ...
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.python3 ];
      };
    };
}
```

Save the file as `flake.nix` into an empty directory and then you can make use
of it:

```console
$ cat > flake.nix <<EOF
{
  description = "A friendly introduction to devShells";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.python3 ];
      };
    };
}
EOF
$ python3 --version
zsh:1: command not found: python3
$ nix develop
$ python3 --version
Python 3.11.7
```

As you can see, once I enter the `devShell` with `nix develop` I have access to
the `python3` binary. If I exit the `devShell` with `CTRL+D` I again lose access
to `python3`.

[1]: <https://nixos.org> "NixOS"
[2]: <https://github.com/direnv/direnv> "direnv GitHub"
[3]: <https://github.com/NixOS/nixpkgs> "nixpkgs GitHub"
[4]: <https://github.com/DeterminateSystems/nix-installer> "DeterminateSystems nix-installer"
[5]: <https://github.com/direnv/direnv/blob/master/docs/hook.md> "Hook direnv into your shell"
