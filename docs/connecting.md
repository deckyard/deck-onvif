<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Connecting: auth, the clock, plain http

A `Device` is a value: `onvif.device` builds one without touching the
network, the `with*` functions return changed copies, and `onvif.connect`
returns one with the clock offset, the service addresses and the auth
method filled in.

```jennifer
def cam as onvif.Device init onvif.device(
    "http://192.168.1.64/onvif/device_service", "admin", $password);
$cam = onvif.withTimeout($cam, 5000);
$cam = onvif.connect($cam);
io.printf("media service: %s\n", onvif.serviceAddress($cam, $cam.media));
```

The address is the device service URL, as WS-Discovery's `XAddrs` or the
vendor's manual gives it; most cameras use `/onvif/device_service`. It must
be `http(s)://host[:port]/path` without credentials, query or fragment. A
`Device` holds the password: never print one.

## WS-Security and the camera's clock

Every request carries a `UsernameToken` header block:

```xml
<wsse:Security>
  <wsse:UsernameToken>
    <wsse:Username>admin</wsse:Username>
    <wsse:Password Type="...#PasswordDigest">tuOSpGlFlIXsozq4HFNeeGeFLEI=</wsse:Password>
    <wsse:Nonce EncodingType="...#Base64Binary">LKqI6G/AikKCQrN0zqZFlg==</wsse:Nonce>
    <wsu:Created>2010-09-16T07:50:45Z</wsu:Created>
  </wsse:UsernameToken>
</wsse:Security>
```

The digest is `base64(sha1(nonce + created + password))` (the values above
are the example of the ONVIF Application Programmer's Guide;
`onvif.passwordDigest` computes it). The nonce is 16 random bytes, new for
every request, so a recorded request cannot be replayed once the camera has
seen it, and `Created` is new too: the header is built per request.

The block carries no `mustUnderstand`, on purpose: a camera that signs in
by HTTP Digest alone must be free to ignore it. With `mustUnderstand="1"`
such a camera answers a MustUnderstand fault instead of the Digest
challenge the fallback below waits for.

Cameras reject a `Created` outside a window around their own clock (often a
few seconds to minutes), so the deck writes `Created` in the camera's time:
this machine's clock plus `offsetMs`. `onvif.connect` measures the offset
with `GetSystemDateAndTime`, which ONVIF requires a camera to answer without
authentication; a camera that refuses is asked once more, signed with this
machine's clock. Clocks drift: a program that runs for days calls
`onvif.syncClock` now and then. A camera that sends no UTC time leaves the
offset at 0 and `clockSynced` false. `ter:NotAuthorized` means a wrong user
or password, or clocks too far apart.

## HTTP Digest and the auth method

Some cameras (newer Hikvision firmware, NVRs) also guard the SOAP endpoint
with HTTP Digest. `Device.auth` says how signed calls sign in:

| `auth` | Signed calls | A `401` |
|---|---|---|
| `"wsse"` | WS-Security | fails at once |
| `"digest"` | WS-Security plus HTTP Digest (unsigned calls get Digest too) | fails at once |
| `""` | WS-Security | with a Digest challenge: sent once more answering it; without one: fails |

`onvif.connect` settles it from its first signed call (`GetServices`):
`"digest"` when that needed HTTP Digest, else `"wsse"`, so every later call
costs one sign-in and a wrong password one failed login, not two or three.
The `Device` is a value, so a call cannot record what it learned in the
caller's copy: a device used without `onvif.connect` keeps `auth` `""` and
finds out on every call (up to two sign-ins when the camera wants Digest).
`onvif.withAuth($cam, "digest")` (or `"wsse"`) fixes the method for such a
device; `connect` keeps a method set that way. `onvif.syncClock` settles it
too when it had to read the clock signed. Digest never sends the password
either.

The snapshot download (`onvif.snapshot`) is a plain GET; its `401` is
answered with `http.digestAuthorization`. A camera that offers only HTTP
Basic gets the password only over `https`: over plain `http` the snapshot
is refused with an `OnvifError` (status 401) instead of sending the password
readable.

## Plain http

ONVIF cameras serve plain `http` on the LAN, and the WS-Security digest is
built for that: the password never travels. The rest of each exchange
(stream addresses, settings, events) is readable and could be changed on
the way, which is the LAN's risk to take, not the internet's. So:

- `http://` is allowed to IP literals in private (RFC 1918, IPv6 ULA
  `fc00::/7`), link-local (`169.254.0.0/16`, `fe80::/10`) and loopback
  ranges.
- `http://` to a host name or a public address needs `onvif.withPlainHttp`.
- `https://` is always allowed and verifies the certificate; a camera's
  self-signed one is trusted with `onvif.withCaCert`, or (last resort)
  `onvif.withInsecure`.

## Service addresses

`onvif.connect` reads `GetServices` (or `GetCapabilities` where a device
answers `GetServices` with a fault) and keeps the addresses of the services
in `onvif.SERVICES` by name. An address that names the host of the device
address you gave is used as reported, its port (and scheme) included: the
camera says where it serves. One that names another host (an inner address
behind NAT or a port forward) keeps its path and query but takes the
scheme, host and port of the device address, so the credentials go only
where you pointed them. A camera reached over `https` that names its own
host over plain `http` is moved too, so TLS is never dropped. The same rule
places a subscription's address and the snapshot address.

`onvif.withService` sets one by hand, before or after `connect`: an address
set that way wins over what the device reports, and `connect` keeps it. The
`device` service's address is also where the clock is read.
`onvif.services` lists everything the device reports, with versions.

Where a device has Media2 the media calls use it, else Media;
`onvif.withMedia($cam, "media")` picks the older one.

## Limits

| Setting | Default | Function |
|---|---|---|
| idle timeout per request | 10 s (`DEFAULT_TIMEOUT_MS`) | `onvif.withTimeout` |
| SOAP reply cap | 8 MiB (`DEFAULT_MAX_BYTES`) | `onvif.withMaxBytes` |
| snapshot cap | 16 MiB (`DEFAULT_MAX_MEDIA_BYTES`) | `onvif.withMaxMediaBytes` |

The timeout bounds each read and write, not the whole call; a pull adds its
own wait on top. Nothing is retried except the one HTTP Digest round while
`auth` is not known, and no redirect is followed.
