<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Events

Events come through a pull-point subscription: the deck asks, the camera
answers, so no callback server is needed.

```jennifer
def sub as onvif.Subscription init onvif.subscribe($cam, 120);
while (true) {
    def got as onvif.Pulled init onvif.pull($cam, $sub, 10, 100);
    $sub = $got.subscription;
    for (def e in $got.events) {
        if ($e.topic == "tns1:VideoSource/MotionAlarm" and maps.has($e.data, "State")) {
            io.printf("%s motion %s\n", $e.utcTime, $e.data["State"]);
        }
    }
    $sub = onvif.renew($cam, $sub, 120);
}
```

- `onvif.subscribe` (`CreatePullPointSubscription`) subscribes to every
  topic for the given seconds (10 to 86400). The subscription ends by itself
  then unless renewed.
- `onvif.pull` (`PullMessages`) waits up to `timeoutSeconds` (1 to 60) for
  events and returns as soon as there are any, as a `Pulled`: `events` (an
  empty list means none came) and `subscription`, the subscription with the
  `currentTime` and `terminationTime` the reply carried (a device may extend
  a subscription that is pulled). Keep that subscription for the next call.
  The first pull brings the current state of every property
  (`operation` `Initialized`); later ones the changes (`Changed`). More events
  than `limit` is an error.
- `onvif.renew` extends it; `onvif.unsubscribe` ends it. A pull on an ended
  subscription is a fault (`ResourceUnknownFault` in the WS-RF namespace on
  onvif_simple_server).

## Events

An `Event` has the `topic` with the ONVIF topic namespace written `tns1:`
whatever prefix the camera used (`tns1:RuleEngine/CellMotionDetector/Motion`,
`tns1:VideoSource/MotionAlarm`), the `utcTime` and `operation`, and the
`source`, `key` and `data` simple items as maps. Topics differ by vendor:
cell motion on Dahua is `IsMotion` under `tns1:RuleEngine/CellMotionDetector/Motion`,
Hikvision and onvif_simple_server send `State` under
`tns1:VideoSource/MotionAlarm`.

## Addressing

Calls on a subscription go to its `address`, placed like the service
addresses (on the device's origin when the camera names another host), with
WS-Addressing `Action`, `To` and `MessageID` header blocks. `To` is
`reference`, the address exactly as the camera gave it, which is what a
camera behind NAT expects to see. A camera that names the subscription by
reference parameters (Axis: `SubscriptionId`) gets them back as header
blocks marked `IsReferenceParameter`. The address keeps its path and query
as given, even a Hikvision one with a raw `%` in it, on the device's scheme,
host and port.

Push notifications (`Subscribe` with a consumer address) are out of scope.
