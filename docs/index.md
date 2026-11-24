<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# @deckyard/onvif

IP cameras and NVRs over ONVIF™, the SOAP web services every vendor that
implements the ONVIF profiles (S streaming, T advanced streaming, G
recording) speaks. One client for all of them: find devices on the LAN, read
their identity and clock, list the media profiles with their RTSP and
snapshot addresses, fetch a snapshot, move a PTZ head and recall presets,
set brightness and focus, and pull events. `onvif.call` reaches every other
operation.

```jennifer
import "@deckyard/onvif/" as onvif;

def cam as onvif.Device init onvif.connect(
    onvif.device("http://192.168.1.64/onvif/device_service", "admin", $password));
for (def p in onvif.profiles($cam)) {
    io.printf("%s %dx%d %s\n", $p.name, $p.width, $p.height, onvif.streamUri($cam, $p.token).address);
}
```

Snippets assume that import. The trailing slash resolves to the entry module.

## What happens on the wire

- **Discovery.** `onvif.discover(3000)` sends a WS-Discovery `Probe` to
  `239.255.255.250:3702` from a plain UDP socket and collects the
  `ProbeMatches` the devices send back by unicast. Each answer names the
  device service URL (`address`) to pass to `onvif.device`. See
  [Discovery](discovery.md).
- **Auth and the clock.** Every request is SOAP 1.2 over the bundled `soap`
  module and carries a WS-Security `UsernameToken` with a `PasswordDigest`:
  `base64(sha1(nonce + created + password))`, with a fresh 16-byte nonce
  and `Created` per request. The password itself is never sent. A camera
  refuses a `Created` far from its own clock, so `onvif.connect` first reads
  the camera's time (`GetSystemDateAndTime`, unsigned) and keeps the offset.
  A camera that also wants HTTP Digest answers `401` and gets it. See
  [Connecting](connecting.md).
- **Services.** `onvif.connect` asks the device service where the others
  are (`GetServices`, or `GetCapabilities` on old firmware): Media and
  Media2 for profiles and stream addresses, PTZ, Imaging, Events. Their
  addresses are moved onto the scheme, host and port you gave, since a
  camera behind NAT names its inner address.
- **Plain http.** ONVIF cameras serve plain `http` on the LAN, so the deck
  allows it to private, link-local and loopback IP addresses; a host name or
  a public address needs `onvif.withPlainHttp`. HTTP Basic is never sent
  over plain `http`.

## Errors

A request the camera refused, or that failed, throws `onvif.OnvifError`,
kind `"onvif"`, with the HTTP `status`, the SOAP fault `code` (`Sender`,
`Receiver`), its first `subcode` and every level in `subcodes`
(`["ter:InvalidArgVal", "ter:NoProfile"]`), and the camera's `reason`. A
reply over the size cap is kind `"limit"`, a camera that does not answer in
time `"timeout"`, one that closes the connection mid-answer `"closed"`; a
camera that cannot be reached is the transport's `net.NetError` (kind
`"net"`, with `reason`, `sent` and `replied`), and a cancelled task stays
`"cancelled"`. Local checks (a bad URL, a token over
64 characters, a PTZ speed outside -1 to 1) are `OnvifError` with status 0,
thrown before anything is sent. No message carries a password or the query
of a URL. See [Other operations and errors](errors.md).

```jennifer
try {
    onvif.gotoPreset($cam, $profile, "7");
} catch (e) {
    if ($e.kind == "onvif" and $e.subcode == "ter:NotAuthorized") {
        io.printf("wrong user or password, or the clocks differ\n");
    } else {
        throw $e;
    }
}
```

## Out of scope

- RTSP and video: the deck returns stream URLs; `ffmpeg`, a player, or
  Frigate™ (`@deckyard/frigate`) consume them.
- Push notifications (`Subscribe` with a consumer address): they need an
  HTTP endpoint the camera can reach. Pull-point subscriptions cover events.
- Profile M analytics, recording search and replay, device configuration
  (users, network, OSD): reachable through `onvif.call`, without helpers.

## Trademarks

ONVIF™ is a trademark of ONVIF, Inc. Hikvision™ is a trademark of Hangzhou
Hikvision Digital Technology Co., Ltd. EZVIZ™ is a trademark of Hangzhou
EZVIZ Network Co., Ltd. Dahua™ is a trademark of Zhejiang Dahua Technology
Co., Ltd. Axis™ is a trademark of Axis AB. Other product and company names
may be trademarks of their respective owners. They are used only to identify
the products this deck works with. This deck is an independent project, not
affiliated with, sponsored or endorsed by ONVIF, Inc. or any camera vendor.
