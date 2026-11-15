<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Design

## Scope

The deck is one client for IP cameras and NVRs of every vendor that
implements the ONVIF profiles (S streaming, T advanced streaming, G
recording), over SOAP 1.2 web services:

- WS-Discovery: find devices on the local network;
- Device: information, services, scopes, time, reboot;
- Media and Media2: profiles, stream and snapshot URIs, snapshots;
- PTZ: continuous, absolute and relative moves, stop, status, presets;
- Imaging: settings, brightness, focus;
- Events through a pull-point subscription, so no callback server is needed;
- `call` for every other operation.

It needs the `net` capability.

Out of scope:

- **RTSP and video decoding.** The deck returns stream URLs; a player,
  `ffmpeg` or a recorder consumes them.
- **Base-notification push events.** They need an HTTP endpoint the camera
  can reach; pull-point subscriptions cover events instead.
- **Profile M analytics**, and helpers for device configuration (users,
  network, OSD), which stay reachable through `call`.

## Decisions

- **SOAP 1.2 over `http` directly.** Requests are built with the bundled
  `soap` module's envelope helpers and parsed with its parser, but posted
  through `http` in one place. `soap.send` would drop the reply headers,
  and the deck needs the `WWW-Authenticate` header of a `401` to choose
  HTTP Digest. Reading the reply follows `soap.send` (same messages, the
  generic kinds passed on). If `soap` ever exposes reply headers, the deck
  can go back to it.
- **WS-Security `UsernameToken` with `PasswordDigest`.** The digest is
  `base64(sha1(nonce + created + password))` with a fresh 16-byte nonce and
  `Created` time per request, so the password is never sent;
  `passwordDigest` exposes the computation. The Security block carries no
  `mustUnderstand`: a camera without WS-Security must ignore it and answer
  with its HTTP Digest challenge, where `mustUnderstand="1"` would get a
  MustUnderstand fault instead.
- **The camera's clock decides.** `connect` reads `GetSystemDateAndTime`
  unsigned, as ONVIF requires, and keeps the offset (taken at the midpoint
  of the round trip) to correct `Created`. A camera that refuses the
  unsigned read is asked again signed with the local clock. A camera that
  sends no UTC time gets offset 0 and `clockSynced` false; the POSIX time
  zone is not interpreted. There is no automatic re-sync on
  `ter:NotAuthorized`, because a retry would double failed logins and some
  cameras lock accounts; `syncClock` is the caller's call.
- **One failed login at most per call.** `Device.auth` is `""` (not known
  yet), `"wsse"` or `"digest"`, set by `withAuth` or settled by `connect`
  and `syncClock` when it is still `""`. With `""`, a signed call answered
  `401` with a Digest challenge is resent once with
  `http.digestAuthorization`; a `401` without one fails at once. With
  `"wsse"` or `"digest"` there is one attempt. `Device` is a value, so a
  call cannot record what worked; a device used without `connect` finds out
  per call. Earlier every `401` was retried with Digest, two to three failed
  logins per call on a wrong password.
- **Snapshot auth.** The snapshot GET answers a `401` with HTTP Digest, and
  with Basic only over `https` (refused over plain `http`). The deck never
  offers Basic on SOAP. User info in a snapshot URI is stripped and never
  used, sent or shown; the device's own credentials answer the challenge.
- **Plain `http` only on the local network.** Plain `http` is allowed to IP
  literals that are private, link-local or loopback; host names and public
  addresses need `withPlainHttp`. Cameras serve `http` on the LAN, and the
  digest never sends the password, but credentials should not cross the
  internet in the clear.
- **Addresses are rebased onto the device's host.** Service addresses,
  subscription addresses and snapshot URLs from the camera that name the
  device URL's host are kept as reported, port and scheme included. One
  that names another host takes the device URL's scheme, host and port, so
  credentials only go to the host the caller named and NAT setups work. A
  device reached over `https` that reports plain `http` on the same host is
  moved too, so there is no TLS downgrade. Paths and queries are kept
  verbatim. `streamUri` returns `Stream{address, rebased}`: the address as
  given, and the same with only the host swapped.
- **Explicit services win.** `withService` records its override, and
  `connect` puts it back after reading the services.
- **Replies are read by local name.** Vendors differ in prefixes (Media2
  is sometimes bound to `trt2`), so elements are matched by local name.
- **Strict input.** Tokens are 1 to 64 characters without control
  characters; PTZ values are in the generic normalized spaces (velocity and
  translation -1 to 1, absolute pan and tilt -1 to 1, zoom 0 to 1), and
  every move names its generic space; brightness and focus speed are
  checked against the device's own option ranges (one extra request);
  subscriptions last 10 to 86400 s and a pull waits 1 to 60 s for 1 to 1024
  events. Numbers in replies must be `xs:float` text.
- **Camera text returned as data is kept whole.** Event items, scopes,
  names, tokens and the like keep every script; only control characters
  become `?`. Text quoted in error messages is cut and made printable ASCII.
- **Discovery.** Two Probes (`NetworkVideoTransmitter`, `Device`) go to
  `DISCOVERY_ADDRESS` from one unicast UDP socket; no multicast group is
  joined. Answers are matched on `RelatesTo` and action, deduplicated by
  endpoint, capped at `MAX_DEVICES`, and junk is skipped, since any host
  can send to the socket.
- **Events.** Requests carry WS-Addressing `Action`, `To` and `MessageID`;
  reference parameters (such as Axis's subscription id) are sent back as
  given. `pull` returns `Pulled{events, subscription}` with the updated
  termination time.

## Errors

A request the camera refused, or that failed, throws `OnvifError` (kind
`"onvif"`, `ERROR_KIND`) with `status` (the HTTP status, 0 for a local
check or an unreadable reply), the SOAP fault `code`, the first `subcode`,
every level in `subcodes` (read from the fault element, since `soap` keeps
only the first) and the camera's `reason`. Local checks throw `OnvifError`
with status 0 before anything is sent. Callers compare `subcode` or
`subcodes`, never the message.

Generic kinds pass through:

- `"limit"` (a reply over `maxBytes`, a snapshot over `maxMediaBytes`, a
  decoding cap), `"timeout"` and `"closed"` are rethrown with the same kind
  and a message that names the operation;
- `"net"`, a camera that cannot be reached, is the `net.NetError` `http`
  raised, passed on with `reason`, `op`, `sent` and `replied` intact.
  Discovery passes on the `net.NetError` of a socket that cannot be bound
  or send;
- `"cancelled"` goes on as it is.

The deck repeats no request after a transport failure.

## Security and limits

- The password is never sent on SOAP (only its digest) and never appears
  in a message. Messages never show a URL's user info or query, and a
  `net.NetError` whose message would name the URL gets the shortened URL
  instead.
- Replies are capped at `DEFAULT_MAX_BYTES` (8 MiB) and snapshots at
  `DEFAULT_MAX_MEDIA_BYTES` (16 MiB), adjustable with `withMaxBytes` and
  `withMaxMediaBytes`; the idle timeout is `DEFAULT_TIMEOUT_MS` (10 s),
  adjustable with `withTimeout`.
- Discovery answers are capped by count and datagram size; anything that is
  not a matching ProbeMatches is ignored.
- Text a camera sends is treated as hostile: cut and made printable in
  messages, control characters replaced in data.
- TLS certificates are checked unless the caller opts out with
  `withInsecure`; `withCaCert` adds a private CA.

## Testing and validation

- The overlays run against a loopback fake camera that answers each request
  by path and operation and records what it received, so tests check what
  the deck sends (the signed header, the digest, the body) as well as how it
  reads replies. Fixtures are constants under `src/topics/fixtures/`, so the
  overlays run from a bare copy of `src/`.
- Replies were recorded on 2026-11-14 from onvif_simple_server (a C ONVIF
  server used in camera firmware, run in a container, which checks the
  PasswordDigest), and taken from published captures of EZVIZ (Hikvision
  firmware), Dahua and gSOAP cameras and the ONVIF Application Programmer's
  Guide (Axis). The PasswordDigest matches the Guide's vector.
- Validated on 2026-11-14 against the simulator: every export and the
  examples, including a port-mapped setup that showed the rebase rules
  working. Raw captures from Axis, Bosch and Reolink cameras parse without
  error.
- Transport failures are tested against a closed loopback port.
- The examples need a camera and are only parse-checked in the gate. There
  is no automated test against a real camera.

Not covered: a successful Renew from a real camera, a SOAP 1.1 fault, a
Media2 snapshot over Digest on a real camera, TLS to a camera, and a
multicast Probe answered on a real LAN (none answered during validation;
unicast Probes work).

## Known limitations and open questions

- `absoluteMove` on the simulator answers `ter:InvalidPosition`, since it
  reads degrees whatever space the request names.
- HTTP Digest on SOAP (`"digest"`) costs two round trips per call: `http`
  keeps no nonce cache.
- The posted request is built by the deck rather than `soap.send`, as long
  as `soap` does not expose reply headers.

## Dependencies on the interpreter

- The bundled `soap` module and HTTP Digest in `http` (0.26.0, the floor).
- The bundled modules passing `"limit"`, `"timeout"` and `"closed"` on.
- `net.NetError` and the `"net"` kind (`jennifer`'s M28.65, transport
  errors have their own kind), with the decoder caps of M28.68 as
  `"limit"`.
- Thrown error structs and lint's L104 for `OnvifError`.
