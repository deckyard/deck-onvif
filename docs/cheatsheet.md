<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# onvif cheatsheet

Every export of `@deckyard/onvif`. Guides are listed in
[the introduction](index.md).

```jennifer
import "@deckyard/onvif/" as onvif;
```

## Device and settings

| Function | Returns | Does |
|---|---|---|
| `device(address, user, password)` | `Device` | a device, not contacted yet; `user` "" for none |
| `connect(dev)` | `Device` | read the clock offset, find the services, settle the auth method |
| `withPlainHttp(dev)` | `Device` | allow plain `http` to any host |
| `withCaCert(dev, pem)` | `Device` | trust a certificate for `https` |
| `withInsecure(dev)` | `Device` | accept any certificate |
| `withTimeout(dev, ms)` | `Device` | idle timeout per request, 100 to 300000 ms |
| `withMaxBytes(dev, n)` | `Device` | SOAP reply cap |
| `withMaxMediaBytes(dev, n)` | `Device` | snapshot cap |
| `withAuth(dev, method)` | `Device` | `"wsse"`, `"digest"` (plus HTTP Digest) or `""` (find out per call) |
| `withService(dev, name, address)` | `Device` | set a service address by hand; `connect` keeps it |
| `withMedia(dev, name)` | `Device` | use `media` or `media2` |
| `serviceAddress(dev, name)` | `string` | a service's URL |
| `passwordDigest(nonce, created, password)` | `string` | the WS-Security PasswordDigest |
| `call(dev, service, action, body)` | `xml.Value` | any operation; the reply's first Body element |

## Device service

| Function | Returns | Does |
|---|---|---|
| `systemDateAndTime(dev)` | `Clock` | the camera's clock (unsigned) |
| `syncClock(dev)` | `Device` | measure the clock offset again |
| `deviceInformation(dev)` | `DeviceInfo` | manufacturer, model, firmware, serial |
| `services(dev)` | `list of Service` | every service with address and version |
| `scopes(dev)` | `list of string` | the scope URIs |
| `reboot(dev)` | `string` | restart; the device's message |

## Discovery

| Function | Returns | Does |
|---|---|---|
| `discover(timeoutMs)` | `list of Discovered` | Probe the LAN, collect answers |
| `discoveryOptions()` | `DiscoveryOptions` | 3 s, the multicast group, both types |
| `discoverWith(options)` | `list of Discovered` | Probe with options |

## Media

| Function | Returns | Does |
|---|---|---|
| `profiles(dev)` | `list of Profile` | the media profiles (Media2, else Media) |
| `streamUri(dev, profile)` | `Stream` | the RTSP URL as given and on the device's host |
| `snapshotUri(dev, profile)` | `string` | the snapshot URL, without user information |
| `snapshot(dev, profile)` | `bytes` | the snapshot image |

## PTZ

| Function | Returns | Does |
|---|---|---|
| `continuousMove(dev, profile, pan, tilt, zoom)` | | move at a speed, -1.0 to 1.0 (`VelocityGenericSpace`) |
| `absoluteMove(dev, profile, pan, tilt, zoom)` | | move to a position (`PositionGenericSpace`) |
| `relativeMove(dev, profile, pan, tilt, zoom)` | | move by an amount (`TranslationGenericSpace`) |
| `stopMove(dev, profile)` | | stop pan, tilt and zoom |
| `ptzStatus(dev, profile)` | `PtzStatus` | position and movement |
| `presets(dev, profile)` | `list of Preset` | the stored positions |
| `gotoPreset(dev, profile, preset)` | | move to a preset |
| `setPreset(dev, profile, name)` | `string` | store the position; the new token |
| `removePreset(dev, profile, preset)` | | delete a preset |

## Imaging

| Function | Returns | Does |
|---|---|---|
| `imagingSettings(dev, source)` | `ImagingSettings` | brightness, contrast, ..., focus mode |
| `brightnessRange(dev, source)` | `Range` | the brightness range |
| `setBrightness(dev, source, value)` | | set it, checked against the range |
| `setFocusMode(dev, source, mode)` | | `AUTO` or `MANUAL` |
| `focusSpeedRange(dev, source)` | `Range` | the continuous focus speed range |
| `focusMove(dev, source, speed)` | | start a continuous focus move |
| `focusStop(dev, source)` | | stop it |

## Events

| Function | Returns | Does |
|---|---|---|
| `subscribe(dev, seconds)` | `Subscription` | create a pull-point subscription |
| `pull(dev, sub, timeoutSeconds, limit)` | `Pulled` | wait for events; the subscription with its new times |
| `renew(dev, sub, seconds)` | `Subscription` | extend it |
| `unsubscribe(dev, sub)` | | end it |

## Constants

| Name | Value |
|---|---|
| `ERROR_KIND` | `"onvif"` |
| `NS_DEVICE` | `"http://www.onvif.org/ver10/device/wsdl"` |
| `NS_MEDIA` | `"http://www.onvif.org/ver10/media/wsdl"` |
| `NS_MEDIA2` | `"http://www.onvif.org/ver20/media/wsdl"` |
| `NS_PTZ` | `"http://www.onvif.org/ver20/ptz/wsdl"` |
| `NS_IMAGING` | `"http://www.onvif.org/ver20/imaging/wsdl"` |
| `NS_EVENTS` | `"http://www.onvif.org/ver10/events/wsdl"` |
| `NS_SCHEMA` | `"http://www.onvif.org/ver10/schema"` |
| `NS_ERROR` | `"http://www.onvif.org/ver10/error"` |
| `SERVICES` | `{"device": NS_DEVICE, "media": NS_MEDIA, ...}`: device, media, media2, ptz, imaging, events, deviceio, recording, search, replay, analytics |
| `DEFAULT_TIMEOUT_MS` | `10000` |
| `DEFAULT_MAX_BYTES` | `8388608` |
| `DEFAULT_MAX_MEDIA_BYTES` | `16777216` |
| `DISCOVERY_ADDRESS` | `"239.255.255.250:3702"` |
| `MAX_DEVICES` | `256` |
| `PANTILT_SPACES` | `"http://www.onvif.org/ver10/tptz/PanTiltSpaces/"` |
| `ZOOM_SPACES` | `"http://www.onvif.org/ver10/tptz/ZoomSpaces/"` |

## Structs

### `Device`

| Field | |
|---|---|
| `address as string` | the device service URL |
| `user as string` | the user name |
| `password as string` | the password |
| `offsetMs as int` | camera clock minus this machine's |
| `clockSynced as bool` | the offset was read from the camera |
| `services as map of string to string` | service name to URL |
| `media as string` | `media2` or `media` |
| `auth as string` | `"wsse"`, `"digest"`, or `""` not known yet |
| `plainHttp as bool` | plain `http` to any host |
| `tls as http.TlsOptions` | certificate checking |
| `timeoutMs as int` | idle timeout per request |
| `maxBytes as int` | SOAP reply cap |
| `maxMediaBytes as int` | snapshot cap |
| `overrides as list of string` | services set by `withService` |

### `OnvifError`

| Field | |
|---|---|
| `kind as string` | `"onvif"` |
| `message as string` | `onvif: ...` |
| `status as int` | HTTP status; 0 for none |
| `code as string` | SOAP fault code, `Sender` / `Receiver` |
| `subcode as string` | first subcode, `ter:NotAuthorized` |
| `subcodes as list of string` | every subcode level |
| `reason as string` | the camera's reason |

### `Clock`

| Field | |
|---|---|
| `utc as string` | `YYYY-MM-DDTHH:MM:SSZ`; "" when not sent |
| `dateTimeType as string` | `NTP` or `Manual` |
| `daylightSavings as bool` | DST on |
| `timeZone as string` | POSIX time zone |

### `DeviceInfo`

| Field | |
|---|---|
| `manufacturer as string` | |
| `model as string` | |
| `firmwareVersion as string` | |
| `serialNumber as string` | |
| `hardwareId as string` | |

### `Service`

| Field | |
|---|---|
| `name as string` | name in `SERVICES`; "" for others |
| `namespace as string` | the service namespace |
| `address as string` | its URL; on the device's origin when it names another host |
| `version as string` | `MAJOR.MINOR` |

### `Discovered`

| Field | |
|---|---|
| `endpoint as string` | `urn:uuid:...` |
| `address as string` | the first http(s) XAddr |
| `xaddrs as list of string` | every XAddr |
| `types as list of string` | the types |
| `scopes as list of string` | the scope URIs |
| `name as string` | the name scope, decoded |
| `hardware as string` | the hardware scope, decoded |
| `from as string` | the answering `host:port` |

### `DiscoveryOptions`

| Field | |
|---|---|
| `timeoutMs as int` | 100 to 30000 |
| `target as string` | `host:port` the Probes go to |
| `iface as string` | interface to send on; "" for any |
| `types as list of string` | `NetworkVideoTransmitter`, `Device` |

### `Profile`

| Field | |
|---|---|
| `token as string` | the profile token |
| `name as string` | |
| `fixed as bool` | not deletable |
| `videoSource as string` | the video source token |
| `encoding as string` | `H264`, `H265`, `JPEG`, ... |
| `width as int` | |
| `height as int` | |
| `ptz as string` | PTZ configuration token; "" for none |

### `PtzStatus`

| Field | |
|---|---|
| `pan as float` | |
| `tilt as float` | |
| `zoom as float` | |
| `panTiltMoving as bool` | |
| `zoomMoving as bool` | |
| `error as string` | the device's error text |
| `utcTime as string` | |

### `Preset`

| Field | |
|---|---|
| `token as string` | the preset token |
| `name as string` | |
| `pan as float` | |
| `tilt as float` | |
| `zoom as float` | |

### `ImagingSettings`

| Field | |
|---|---|
| `values as map of string to float` | `Brightness`, `ColorSaturation`, `Contrast`, `Sharpness` |
| `focusMode as string` | `AUTO` / `MANUAL` |
| `irCutFilter as string` | `ON` / `OFF` / `AUTO` |

### `Range`

| Field | |
|---|---|
| `min as float` | |
| `max as float` | |

### `Subscription`

| Field | |
|---|---|
| `address as string` | the subscription manager's URL, where requests go |
| `reference as string` | the address as the camera gave it, sent as `To` |
| `parameters as list of string` | reference parameters, as XML |
| `currentTime as string` | |
| `terminationTime as string` | |

### `Pulled`

| Field | |
|---|---|
| `events as list of Event` | oldest first; empty when none came |
| `subscription as Subscription` | with the reply's `currentTime` and `terminationTime` |

### `Stream`

| Field | |
|---|---|
| `address as string` | the RTSP URI as the camera gave it |
| `rebased as string` | the same on the device's host, port kept |

### `Event`

| Field | |
|---|---|
| `topic as string` | `tns1:VideoSource/MotionAlarm` |
| `utcTime as string` | |
| `operation as string` | `Initialized`, `Changed`, `Deleted` |
| `source as map of string to string` | |
| `key as map of string to string` | |
| `data as map of string to string` | |
