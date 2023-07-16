# My Personal Page

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jalil-salame/jalil-salame.github.io/nix-build.yaml)
![GitHub deployments](https://img.shields.io/github/deployments/jalil-salame/jalil-salame.github.io/github-pages)

Code to my [github page](https://jalil-salame.github.io), it currently hosts
some (WIP) blogposts about some learning projects I am working on.

## Building

### Using Nix

You can install `nix` following
[these](https://nixos.wiki/wiki/Nix_Installation_Guide) instructions.

```console
$ nix build -L
jalil-salame.github.io> unpacking sources
jalil-salame.github.io> unpacking source archive /nix/store/mq9h3gx5m227zwd75xalq4j55i6nhi9h-fw6fwm4dm4v9wr8nx1nsxli6s48af5x6-source
jalil-salame.github.io> source root is fw6fwm4dm4v9wr8nx1nsxli6s48af5x6-source
jalil-salame.github.io> patching sources
jalil-salame.github.io> configuring
jalil-salame.github.io> building
jalil-salame.github.io> Building site...
jalil-salame.github.io> Checking all internal links with anchors.
jalil-salame.github.io> > Successfully checked 1 internal link(s) with anchors.
jalil-salame.github.io> -> Creating 5 pages (0 orphan) and 0 sections
jalil-salame.github.io> Done in 109ms.
jalil-salame.github.io>
jalil-salame.github.io> installing
jalil-salame.github.io> no Makefile or custom installPhase, doing nothing
jalil-salame.github.io> post-installation fixup
jalil-salame.github.io> shrinking RPATHs of ELF executables and libraries in /nix/store/d56i76rk7ijq04k393y6d54cxdpvgn40-jalil-salame.github.io-2023-07-15
jalil-salame.github.io> checking for references to /build/ in /nix/store/d56i76rk7ijq04k393y6d54cxdpvgn40-jalil-salame.github.io-2023-07-15...
jalil-salame.github.io> patching script interpreter paths in /nix/store/d56i76rk7ijq04k393y6d54cxdpvgn40-jalil-salame.github.io-2023-07-15
```

Or just run it (this will use `miniserve` to host the website on
`localhost:8080`):

```console
$ nix run
miniserve v0.23.2
Bound to 127.0.0.1:8080
Serving path /nix/store/br70z4h2qgrnvk32b05iraglnfabjc92-jalil-salame.github.io-2023-07-15
Available at (non-exhaustive list):
    http://127.0.0.1:8080
```

## Local development

For local development you should use this command:

```console
$ nix develop --ignore-environment --command zola serve
Building site...
Checking all internal links with anchors.
> Successfully checked 1 internal link(s) with anchors.
-> Creating 5 pages (0 orphan) and 0 sections
Done in 51ms.

Listening for changes in /home/jalil/Dev/jalil-salame.github.io/{config.toml,content,static,templates,themes}
Press Ctrl+C to stop

Web server is available at http://127.0.0.1:1111
```

It will watch for changes in the website and rebuild it when necessary.
