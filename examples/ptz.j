#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * Pan right for a second, stop, and list the presets of the first PTZ
 * profile:
 *
 *   ONVIF_USER=admin ONVIF_PASSWORD=... jennifer run examples/ptz.j \
 *       http://192.168.1.64/onvif/device_service
 */
use io;
use os;
use time;

import "../src/onvif.j" as onvif;

if (len(os.ARGS) < 2) {
    io.eprintf("usage: ptz.j DEVICE-SERVICE-URL\n");
    exit 2;
}
def cam as onvif.Device init onvif.connect(
    onvif.device(os.ARGS[1], os.getEnv("ONVIF_USER"), os.getEnv("ONVIF_PASSWORD")));
def token as string init "";
for (def p in onvif.profiles($cam)) {
    if ($token == "" and $p.ptz != "") {
        $token = $p.token;
    }
}
if ($token == "") {
    io.eprintf("no profile with PTZ\n");
    exit 1;
}
onvif.continuousMove($cam, $token, 0.3, 0.0, 0.0);
time.sleep(time.fromMilliseconds(1000));
onvif.stopMove($cam, $token);
def s as onvif.PtzStatus init onvif.ptzStatus($cam, $token);
io.printf("pan %f tilt %f zoom %f\n", $s.pan, $s.tilt, $s.zoom);
for (def preset in onvif.presets($cam, $token)) {
    io.printf("preset %s  %s\n", $preset.token, $preset.name);
}
