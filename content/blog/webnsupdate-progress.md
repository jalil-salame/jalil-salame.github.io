+++
title = "Building WebNSUpdate"
date = "2025-10-05"
description = "What I've been doing in my free time recently"
[taxonomies]
tags = ["dev", "rust", "self-hosting", "programming"]
+++
 
I have't been programming much outside of work. Mostly 'cause life's gotten in
the way, but also, my personal project, [`webnsupdate`], has been very stable
lately so I haven't needed to do anything to it.

## My self-hosting journey

I've been self-hosting some things since I got my Raspberry Pi 4 around 2022,
but I only really got into it once I switched to NixOS and got a small mini PC
to become a more powerful server.

When I started self-hosting I didn't have an income, I got some money working as
a student assistant at University which is how I saved enough to buy the
Raspberry Pi 4, but I didn't have enough money nor the need to justify paying
for a VPS provider and a static IP address. So I used free services like CloudNS
and [freedns.afraid.org](https://freedns.afraid.org/) to connect to my server
while it was behind a Dynamic IP.

I eventually graduated and started earning a decent income so I got myself a
Mini PC and started running more services which meant I ran out of free
subdomains on the mentioned services. Around that time I got this domain
(salame.cl), since I had to help my Dad buy his own domain, and I decided it
would be fun to self-host my own Dynamic DNS service.

My searching skills must've gotten rusty since I failed to find any open source
project that did something like this, so I made my own in Rust, and that's how
we got [`webnsupdate`].

## Basic architecture

Now I might be implementing my own DynDNS service, but since I would be relying
on it for my self-hosted CI and Git server I wanted it to be as reliable as
possible. Which meant not implementing a DNS server, instead I created a small
web interface to BIND 9's `nsupdate` CLI tool, this way the heavy lifting is
done by the much better tested BIND 9 server, and the only thing [`webnsupdate`]
handles is the updates to the Dynamic IP.

WebNSUpdate takes care of requests to the `/update` endpoint by checking the IP
of the request (usually the right-most IP in the `X-Forwarded-for` header set by
nginx) and verifying the password set in HTTP Basic Auth, then forwarding the IP
to `nsupdate` and making it update the BIND zone file.

WebNSUpdate intentionally doesn't handle HTTPS traffic. Since I'm the only one
maintaining it I didn't want to mess something up by misconfiguring it or having
to scramble to update it since a Rust library had a high-severity vulnerability.
This is why you are expected to run it behind a reverse proxy like Caddy or
nginx.

I did have to store a password since I didn't want anyone hitting the `/update`
endpoint being able to trigger an update to my DNS server, but since the systemd
unit doesn't run as root there is not much damage that can be done through this
service.

## Challenges

The "It's always DNS" meme is way too accurate, I've had many issues with DNS
and with how it interacts with IPv6. That and the propagation potentially taking
days is rough for testing.

Having NixOS integration tests is great though, I can test some common
configurations using full VMs instead of simple integration tests. I do still
come across issues in my production server that the tests didn't catch, but they
do make me way more confident that by the time I push an update the basic
functionality is there.

I do want to create a coverage report to help with testing more of the codebase,
I know I have some blindspots in my testsuite, but I would like something more
substantial than a gut feeling to keep track of the untested code.

## Future Work

Some things I'd like to add are:

### Multi-user support

Currently I have a single password that allows updating all domains, since I
only have one machine this works fine, but for it to be easier to host for a
group of friends or similar, it would be better if you couldn't accidentally
point someone else's domain to your server.

I already started work on this by allowing multiple DynIP records allowing
different machines to use the same webnsupdate server, but they still must share
the same password.

### Extended AVM FritzBox Router support

Here in Germany, AVM's FritzBox routers are very popular and they have some nice
features like automatic DynDNS handling; you can give them a URL to send a GET
request once they get a new IP address. They even allow for templating of Query
Parameters so you can set the IP it was updated to and other useful information.

I would like to test this area more thoroughly and start making use of it.

### Use IPv6 in production

IPv6 has been a headache, but I would like to start using it in my own server.
For this I probably want to have more confidence in my testsuite first since
issues with DNS are annoying to solve.

### Writing Documentation

I'd like to have some public docs I could point people (and my future self) to
so the information in this blog post and more details would be easily accessible
to them.

Ideally this would ensure people can install it outside NixOS without issues.

### Publishing the project

I should publish the project to crates.io and nixpkgs at least and make a public
announcement so people know it exists and is ready to be used.

## Final thoughts

Honestly, none of that sounds very exciting, but I'm very proud of my project
and the end result would be learinig a bunch of useful things.

I don't know where this will end up, but maybe check back in a year and things
might have been done? Maybe that's a bit too optimistic...

Hope this was fun to read through, I decided I needed to write something for my
blog and get some practice with my new keyboard so I wrote this.

[`webnsupdate`]: https://github.com/jalil-salame/webnsupdate "WebNSUpdate source
code on GitHub"
