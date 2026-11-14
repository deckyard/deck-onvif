<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# PTZ

The PTZ calls take a profile token whose profile has a PTZ configuration
(`Profile.ptz` not "").

```jennifer
onvif.continuousMove($cam, $profile, 0.3, 0.0, 0.0);   # pan right
time.sleep(time.fromMilliseconds(800));
onvif.stopMove($cam, $profile);
def s as onvif.PtzStatus init onvif.ptzStatus($cam, $profile);
io.printf("at %f %f, zoom %f, moving %t\n", $s.pan, $s.tilt, $s.zoom, $s.panTiltMoving);
```

| Call | Space | Range |
|---|---|---|
| `onvif.continuousMove(dev, profile, pan, tilt, zoom)` | generic velocity | each -1.0 to 1.0 |
| `onvif.absoluteMove(dev, profile, pan, tilt, zoom)` | generic position | pan, tilt -1.0 to 1.0; zoom 0.0 to 1.0 |
| `onvif.relativeMove(dev, profile, pan, tilt, zoom)` | generic translation | each -1.0 to 1.0 |

The ranges are ONVIF's normalized generic spaces and are checked before
anything is sent. Every request names its space (`space` on `PanTilt` and
`Zoom`: `PANTILT_SPACES` / `ZOOM_SPACES` followed by
`VelocityGenericSpace`, `PositionGenericSpace` or `TranslationGenericSpace`),
so the head reads the numbers in that range rather than in the default
space of its PTZ configuration. No `Speed` is sent with absolute and
relative moves: the head uses its default speed. Positive pan turns right, positive tilt up, positive zoom
in. A zoom of 0.0 in a continuous or relative move is left out of the
request, for heads without zoom. A head that does not support a space
answers with a fault, an `OnvifError` with `subcode` `ter:InvalidArgVal`
and `ter:SpaceNotSupported` in `subcodes` (seen on Hikvision for absolute
and relative moves), or `ter:InvalidPosition` (onvif_simple_server, which
reads its generic space in degrees, 0 to 360, whatever the request names).

`onvif.stopMove` stops pan, tilt and zoom. `onvif.ptzStatus` reports the
position where the device gives one (0.0 otherwise), whether pan/tilt and
zoom are `MOVING`, and the device's error text.

## Presets

```jennifer
def door as string init onvif.setPreset($cam, $profile, "Door");
for (def p in onvif.presets($cam, $profile)) {
    io.printf("%s %s\n", $p.token, $p.name);
}
onvif.gotoPreset($cam, $profile, $door);
onvif.removePreset($cam, $profile, $door);
```

An unknown preset is a fault: `ter:InvalidArgVal` with `ter:NoToken`
(ONVIF's code) or another second level (`ter:InvalidParameter` on
Hikvision); test `$e.subcode == "ter:InvalidArgVal"`.
