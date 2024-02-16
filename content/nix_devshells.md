+++
title = "Direnv and Nix devShells: A match made in heaven"
date = "2024-02-10"
description = "Deep dive into nix dev shells"
[taxonomies]
tags = ["dev", "shell", "nix", "programming"]
+++

I use [NixOS][1] since last year and I recently started making use of
`devShells` (development shells). They are very useful and more people should
know about them! Especially when used in combination with [`direnv`][2].

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

## Getting started with Flakes and devShells

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

You might get a different version of Python if you do this at a future date,
that is why flakes come with a lock file `flake.lock`. For example, this is the
lock file I am using:

```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1707956935,
        "narHash": "sha256-ZL2TrjVsiFNKOYwYQozpbvQSwvtV/3Me7Zwhmdsfyu4=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "a4d4fe8c5002202493e87ec8dbc91335ff55552c",
        "type": "github"
      },
      "original": {
        "id": "nixpkgs",
        "ref": "nixos-unstable",
        "type": "indirect"
      }
    },
    "root": {
      "inputs": {
        "nixpkgs": "nixpkgs"
      }
    }
  },
  "root": "root",
  "version": 7
}
```

If anything I do here doesn't work for you. Try replacing your lockfile with
this one.

### Full dependency management with Nix

Now, getting Python through a devShell is interesting, but not impressive. You
can do that already by installing Python locally, and adding it to your `PATH`
using something like `direnv`:

```sh
# .envrc
PATH_add /path/to/python3/bin
```

This prepends `/path/to/python3/bin` to the `PATH` environment variable, thus
making any binaries in `/path/to/python3/bin` take precedence; i.e. if you
installed Python 3.10 globally, but `/path/to/python3/bin` has Python 3.11,
whenever you run `python3` you will get Python 3.11 instead of Python 3.10.

A `devShell` does something similar. We can take a look at what happens to the
`PATH` variable before and after running `nix develop`:

```console
$ echo $PATH | tr ':' '\n'
/run/wrappers/bin
/home/jalil/.local/share/flatpak/exports/bin
/var/lib/flatpak/exports/bin
/home/jalil/.nix-profile/bin
/nix/profile/bin
/home/jalil/.local/state/nix/profile/bin
/etc/profiles/per-user/jalil/bin
/nix/var/nix/profiles/default/bin
/run/current-system/sw/bin
$ nix develop
$ echo $PATH | tr ':' '\n'
/nix/store/y027d3bvlaizbri04c1bzh28hqd6lj01-python3-3.11.7/bin
/nix/store/v3b4la4kh5l7dqzdyraqb1lyfrajfl5w-patchelf-0.15.0/bin
/nix/store/4cjqvbp1jbkps185wl8qnbjpf8bdy8j9-gcc-wrapper-13.2.0/bin
/nix/store/qs1nwzbp2ml3cxzsxihn82hl0w73snr0-gcc-13.2.0/bin
/nix/store/36wymklsa60bigdhb0p3139ws02r46lw-glibc-2.38-44-bin/bin
/nix/store/bicmg5gd50q6igk0y5mga1v0p1lk8f26-coreutils-9.4/bin
/nix/store/c53f8hagyblvx52zylsnqcc0b3nxbrcl-binutils-wrapper-2.40/bin
/nix/store/2ab5740x0cy1d74qvbpl5s28qikmppl5-binutils-2.40/bin
/nix/store/bicmg5gd50q6igk0y5mga1v0p1lk8f26-coreutils-9.4/bin
/nix/store/p6fd7piqrin2h0mqxzmvyxyr6pyivndj-findutils-4.9.0/bin
/nix/store/2d582qba31ii28nyrww9bzb00aq06d1g-diffutils-3.10/bin
/nix/store/vd92lhcxs39hbdnzj8ycak5wvj466s3l-gnused-4.9/bin
/nix/store/mn911d51n5lklwr3zy4mdhxa77wzancb-gnugrep-3.11/bin
/nix/store/h53ycc406fmbq3ff0n0rjxdzb6lk9zcn-gawk-5.2.2/bin
/nix/store/1ds6c0i7z4advdr0z210sxgvmq786h09-gnutar-1.35/bin
/nix/store/nf4fhdqgjka360nkibx1yg14gybwb018-gzip-1.13/bin
/nix/store/v3hp6kidlb9yz6j51a0wlbnpclqpi94f-bzip2-1.0.8-bin/bin
/nix/store/15xrks0frcgils8qxfkhspyg6gi9rxdh-gnumake-4.4.1/bin
/nix/store/5l50g7kzj7v0rdhshld1vx46rf2k5lf9-bash-5.2p26/bin
/nix/store/2pi9hb31np2vhy8r9lfih47rf9n51crz-patch-2.7.6/bin
/nix/store/h8vfiwhq6kmvrnj96w52n36c6qm4lbyl-xz-5.4.6-bin/bin
/nix/store/rn6yfzxwp12z0zqavxx1841mh0ypr7jg-file-5.45/bin
/run/wrappers/bin
/home/jalil/.local/share/flatpak/exports/bin
/var/lib/flatpak/exports/bin
/home/jalil/.nix-profile/bin
/nix/profile/bin
/home/jalil/.local/state/nix/profile/bin
/etc/profiles/per-user/jalil/bin
/nix/var/nix/profiles/default/bin
/run/current-system/sw/bin
```

As you can see, there are a bunch of `/nix/store/.../bin` paths. This is how nix
manages packages. Let's inspect the Python package
(`/nix/store/y027d3bvlaizbri04c1bzh28hqd6lj01-python3-3.11.7/bin`):

```console
$ ls -1 /nix/store/y027d3bvlaizbri04c1bzh28hqd6lj01-python3-3.11.7/bin
2to3 -> 2to3-3.11
2to3-3.11
idle -> idle3.11
idle3 -> idle3.11
idle3.11
pydoc -> pydoc3.11
pydoc3 -> pydoc3.11
pydoc3.11
python -> python3.11
python-config -> python3.11-config
python3 -> python3.11
python3-config -> python3.11-config
python3.11
python3.11-config
```

We can see that the `bin` folder of the Python package contains the executable
for `python` (called `python3.11`). We also see paths to `gcc`, `gnumake` and
various other utilities, but we didn't specify those anywhere... How come? Well,
`pkgs.mkShell` adds those to our path because they are part of the standard
environment (`stdenv`) and are generally useful to have around when developing
packages (which is the main use of `devShells`).

[1]: <https://nixos.org> "NixOS"
[2]: <https://github.com/direnv/direnv> "direnv GitHub"
[3]: <https://github.com/NixOS/nixpkgs> "nixpkgs GitHub"
[4]: <https://github.com/DeterminateSystems/nix-installer> "DeterminateSystems nix-installer"
[5]: <https://github.com/direnv/direnv/blob/master/docs/hook.md> "Hook direnv into your shell"
