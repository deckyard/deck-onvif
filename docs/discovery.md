<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Discovery

```jennifer
for (def d in onvif.discover(3000)) {
    io.printf("%s %s (%s)\n", $d.address, $d.name, $d.hardware);
}
```

`onvif.discover` sends WS-Discovery (2005/04) `Probe` messages to the
multicast group `239.255.255.250:3702` and collects the `ProbeMatches` for
the given milliseconds (100 to 30000). Devices answer by unicast to the
sending socket, so no multicast group is joined and no privilege is needed.
UDP may drop a datagram: a device missing from one run may answer the next.

Two Probes go out, one per type: `dn:NetworkVideoTransmitter` (cameras) and
`tds:Device` (any ONVIF™ device, NVRs included). A device that matches both
is listed once, by its endpoint reference.

Each `Discovered` has the device's `endpoint` (a stable `urn:uuid:`), the
first `http(s)` `address` among its `xaddrs` (some list an IPv6 link-local
address too), its `types` and `scopes`, and the `name` and `hardware` scopes
decoded. `from` is where the answer came from.

## Options

```jennifer
def o as onvif.DiscoveryOptions init onvif.discoveryOptions();
$o.iface = "eth1";               # send on this interface (Linux)
$o.types = ["NetworkVideoTransmitter"];
$o.timeoutMs = 5000;
def found as list of onvif.Discovered init onvif.discoverWith($o);
```

- `iface` binds the socket to one interface (`SO_BINDTODEVICE`), for a host
  with several networks; the routing table picks one otherwise.
- `target` is where the Probes go: the multicast group by default, or one
  device's `host:3702` to probe it by unicast (useful across a router that
  does not forward multicast).

## What is skipped

An answer that is no ProbeMatches for these Probes (another message, a reply
to someone else's Probe, malformed XML, a datagram cut at 64 KiB) is
skipped, not an error: any device on the LAN can send to the socket. At most
`MAX_DEVICES` (256) devices are returned.
