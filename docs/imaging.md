<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Imaging

The imaging calls take a video source token: `Profile.videoSource`.

```jennifer
def src as string init onvif.profiles($cam)[0].videoSource;
def s as onvif.ImagingSettings init onvif.imagingSettings($cam, $src);
io.printf("brightness %f, focus %s\n", $s.values["Brightness"], $s.focusMode);
```

`values` holds the numbers the device reports among `Brightness`,
`ColorSaturation`, `Contrast` and `Sharpness`, on the device's own scale
(0 to 100 on Hikvision, 0 to 1 elsewhere); read it with `maps.has` first.

## Brightness

```jennifer
def r as onvif.Range init onvif.brightnessRange($cam, $src);
onvif.setBrightness($cam, $src, ($r.min + $r.max) / 2.0);
```

`onvif.setBrightness` reads the range first (`GetOptions`) and refuses a
value outside it before sending `SetImagingSettings` (with
`ForcePersistence`, so the value survives a restart).

## Focus

```jennifer
onvif.setFocusMode($cam, $src, "MANUAL");
onvif.focusMove($cam, $src, 0.5);     # farther; negative is nearer
time.sleep(time.fromMilliseconds(300));
onvif.focusStop($cam, $src);
```

`onvif.focusMove` is a continuous move; its speed is checked against
`onvif.focusSpeedRange` (`GetMoveOptions`). Most cameras move focus only with
autofocus off. Other imaging settings go through `onvif.call` with an
`ImagingSettings` element (see [Other operations](errors.md)).
