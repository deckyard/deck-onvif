<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Media: profiles, streams, snapshots

A media profile ties a video source, an encoder and (optionally) a PTZ
configuration together; its token is what the media and PTZ calls take.

```jennifer
for (def p in onvif.profiles($cam)) {
    io.printf("%s %s %s %dx%d ptz=%s\n", $p.token, $p.name, $p.encoding, $p.width, $p.height, $p.ptz);
}
```

The calls use Media2 (`ver20/media`) where the device offers it, else Media
(`ver10/media`); the answers are the same `Profile`. `videoSource` is the
token the [imaging](imaging.md) calls take; `ptz` is "" for a profile
without PTZ.

## Stream and snapshot addresses

```jennifer
def s as onvif.Stream init onvif.streamUri($cam, $p.token);
io.printf("%s\n(from outside: %s)\n", $s.address, $s.rebased);
def jpegUrl as string init onvif.snapshotUri($cam, $p.token);
```

`onvif.streamUri` asks for RTP unicast over RTSP and returns a `Stream`:
`address` is the `rtsp://` (or `rtsps://`) URL exactly as the camera gave
it, often with a query (`?channel=1&subtype=0`); `rebased` is the same URL
with its host replaced by the host of the device address, the RTSP port and
everything else kept. On the camera's own network the two are the same or
`address` works; behind NAT `address` names the camera's inner address and
`rebased` reaches it when the RTSP port is forwarded on the same number.
The deck adds no credentials: the player signs in to RTSP itself. Playing
the stream is out of scope.

`onvif.snapshotUri` returns the snapshot URL without the user information
(`user:password@`) some cameras put in it.

## Snapshots

```jennifer
fs.writeBytes("front.jpg", onvif.snapshot($cam, $p.token));
```

`onvif.snapshot` asks for the snapshot address and downloads it. The address
is placed like the service addresses (see [Connecting](connecting.md)):
used as given when it names the device's host, else moved onto the device's
scheme, host and port with its path and query kept, so the credentials go
nowhere else and a camera behind NAT works. User information in the address
is dropped: it is never used, sent or shown. A `401` is answered once with
the device's own credentials: HTTP Digest always, HTTP Basic only over
`https`. The answer
must be an image (an `image/*` type, or bytes that start like a JPEG or PNG
file): a login page is an error. Images over 16 MiB are kind `"limit"`
(`onvif.withMaxMediaBytes`).
