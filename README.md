# My Personal Page

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jalil-salame/jalil-salame.github.io/nix-build.yaml)
![GitHub deployments](https://img.shields.io/github/deployments/jalil-salame/jalil-salame.github.io/github-pages)

Code to my [github page](https://jalil-salame.github.io), it currently hosts
some (WIP) blogposts about some learning projects I am working on.

## Building

You can build this page in multiple ways:

### Using Zola

Using [Zola](https://getzola.org) you can build this site:

```console
$ zola build
...
```

The output will be in the `./public` directory.

Install zola using the instructions [here](https://www.getzola.org/documentation/getting-started/installation/).

### Using Nix

If you have `nix` then it is very easy to build/run this website:

```console
$ nix build
...
```

Or just run it:

```console
$ nix run
...
```

You can install `nix` following [these](https://nixos.wiki/wiki/Nix_Installation_Guide) instructions.
