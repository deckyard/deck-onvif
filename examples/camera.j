#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.28.0

/**
 * Show a camera's identity, clock and profiles with their stream addresses,
 * and save the first profile's snapshot:
 *
 *   ONVIF_USER=admin ONVIF_PASSWORD=... jennifer run examples/camera.j \
 *       http://192.168.1.64/onvif/device_service [snapshot.jpg]
 */
use fs;
use io;
use os;

import "../src/onvif.j" as onvif;

if (len(os.ARGS) < 2) {
    io.eprintf("usage: camera.j DEVICE-SERVICE-URL [snapshot.jpg]\n");
    exit 2;
}
def cam as onvif.Device init onvif.connect(
    onvif.device(os.ARGS[1], os.getEnv("ONVIF_USER"), os.getEnv("ONVIF_PASSWORD")));
def info as onvif.DeviceInfo init onvif.deviceInformation($cam);
io.printf("%s %s, firmware %s\n", $info.manufacturer, $info.model, $info.firmwareVersion);
io.printf("clock %s, offset %d ms\n", onvif.systemDateAndTime($cam).utc, $cam.offsetMs);
def profiles as list of onvif.Profile init onvif.profiles($cam);
for (def p in $profiles) {
    io.printf(
        "%s  %s %dx%d  %s\n",
        $p.token,
        $p.encoding,
        $p.width,
        $p.height,
        onvif.streamUri($cam, $p.token).rebased);
}
if (len(os.ARGS) > 2 and len($profiles) > 0) {
    def jpg as bytes init onvif.snapshot($cam, $profiles[0].token);
    fs.writeBytes(os.ARGS[2], $jpg);
    io.printf("wrote %s, %d bytes\n", os.ARGS[2], len($jpg));
}
