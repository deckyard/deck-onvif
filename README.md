# @deckyard/onvif

[![test](https://github.com/deckyard/deck-onvif/actions/workflows/test.yml/badge.svg)](https://github.com/deckyard/deck-onvif/actions/workflows/test.yml)
[![Documentation](https://img.shields.io/badge/docs-github%20pages-blue)](https://deckyard.github.io/deck-onvif/)
[![release](https://img.shields.io/github/v/release/deckyard/deck-onvif)](https://github.com/deckyard/deck-onvif/releases/latest)

IP cameras and NVRs over ONVIF for [Jennifer](https://jennifer-lang.dev/)
programs: WS-Discovery on the LAN, device information and clock, media
profiles with RTSP and snapshot URLs, snapshots, PTZ moves and presets,
brightness and focus, and events from a pull-point subscription. One client
for every vendor that implements the ONVIF profiles; `call` reaches any
other operation.

**[Documentation](https://deckyard.github.io/deck-onvif/)**

## Install

```sh
jvc add @deckyard/onvif
```

This vendors the deck to `vendor/<scope>/onvif/`. Without `jvc`, unpack the
`src/` subtree of a release archive (`<scope>-onvif-<version>.tar.gz`) there.

## Usage

```jennifer
import "@deckyard/onvif/" as onvif;

for (def d in onvif.discover(3000)) {
    io.printf("%s %s\n", $d.address, $d.name);
}

def cam as onvif.Device init onvif.connect(
    onvif.device("http://192.168.1.64/onvif/device_service", "admin", $password));
for (def p in onvif.profiles($cam)) {
    io.printf("%s %s\n", $p.name, onvif.streamUri($cam, $p.token).address);
}
fs.writeBytes("snapshot.jpg", onvif.snapshot($cam, onvif.profiles($cam)[0].token));
```

Requests are signed with a WS-Security PasswordDigest built per request on
the camera's clock (the password never travels); HTTP Digest is answered
where a camera asks for it. Plain `http` is allowed to private, link-local
and loopback addresses; anything else needs `withPlainHttp`.

## Requirements

Jennifer 0.27.0 or newer and the capability `net` (SOAP over HTTP, WS-Discovery
over UDP), so not `jennifer-tiny`. No other deck. RTSP and video decoding are
out of scope: the deck returns the stream URLs.

## Development

```sh
tools/check-all.sh                   # the full gate, as CI runs it
jennifer test src/onvif_test.j       # the test overlay (a loopback fake camera)
tools/check-docs.sh                  # docs against the code
tools/pack.sh dist                   # build the release archive
```

## Licence

LGPL-3.0-only, see [LICENSE](LICENSE). Copyright (C) 2026 mplx &lt;mplx@jennifer-lang.dev&gt;.
