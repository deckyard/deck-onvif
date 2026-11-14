#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * List the ONVIF devices on the local network:
 * jennifer run examples/discover.j [interface]
 *
 * One WS-Discovery Probe per device type, answers collected for 3 seconds.
 */
use io;
use os;

import "../src/onvif.j" as onvif;

def o as onvif.DiscoveryOptions init onvif.discoveryOptions();
if (len(os.ARGS) > 1) {
    $o.iface = os.ARGS[1];
}
def found as list of onvif.Discovered init onvif.discoverWith($o);
for (def d in $found) {
    io.printf("%s  %s  %s (%s)\n", $d.from, $d.address, $d.name, $d.hardware);
}
io.printf("%d device(s)\n", len($found));
