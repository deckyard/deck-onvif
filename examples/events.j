#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * Print a camera's events for a minute, through a pull-point subscription:
 *
 *   ONVIF_USER=admin ONVIF_PASSWORD=... jennifer run examples/events.j \
 *       http://192.168.1.64/onvif/device_service
 */
use io;
use os;
use time;

import "../src/onvif.j" as onvif;

if (len(os.ARGS) < 2) {
    io.eprintf("usage: events.j DEVICE-SERVICE-URL\n");
    exit 2;
}
def cam as onvif.Device init onvif.connect(
    onvif.device(os.ARGS[1], os.getEnv("ONVIF_USER"), os.getEnv("ONVIF_PASSWORD")));
def sub as onvif.Subscription init onvif.subscribe($cam, 120);
def stopAt as int init time.unixMillis(time.now()) + 60000;
while (time.unixMillis(time.now()) < $stopAt) {
    def got as onvif.Pulled init onvif.pull($cam, $sub, 10, 100);
    $sub = $got.subscription;
    for (def e in $got.events) {
        io.printf("%s %s %s %a %a\n", $e.utcTime, $e.operation, $e.topic, $e.source, $e.data);
    }
    $sub = onvif.renew($cam, $sub, 120);
}
onvif.unsubscribe($cam, $sub);
