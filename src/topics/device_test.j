# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.28.0

# onvif - white-box tests for the device topic. Spliced into onvif_test.j via
# include.

func testConnectReadsTheClockAndServices() {
    def f as Fake init simFake({});
    def before as int init time.unixMilliseconds(time.now());
    def d as Device init connect(fakeDevice($f));
    def after as int init time.unixMilliseconds(time.now());
    stopFake($f);
    testing.assertTrue($d.clockSynced);
    def camera as int init time.unixMilliseconds(time.fromIso("2026-11-14T19:32:04Z"));
    testing.assertTrue($d.offsetMs <= $camera - $before and $d.offsetMs >= $camera - $after);
    testing.assertEqual($d.media, "media2");
    testing.assertEqual($d.auth, "wsse");
    testing.assertEqual(
        maps.keys($d.services),
        ["device", "events", "ptz", "media", "deviceio", "media2", "imaging"]);
    testing.assertEqual($d.services["ptz"], $f.base + "/onvif/ptz_service");
    testing.assertEqual($d.services["device"], $f.base + "/onvif/device_service");
}

func testConnectFallsBackToCapabilities() {
    def f as Fake init simFake({
        "/onvif/device_service GetServices": [SIM_NOT_SUPPORTED],
        "/onvif/device_service GetCapabilities": [SIM_CAPABILITIES]
    });
    def d as Device init connect(fakeDevice($f));
    stopFake($f);
    testing.assertEqual($d.media, "media");
    testing.assertFalse(maps.has($d.services, "media2"));
    testing.assertEqual($d.services["imaging"], $f.base + "/onvif/imaging_service");
    testing.assertEqual($d.services["events"], $f.base + "/onvif/events_service");
    def g as Fake init startFake({
        "/onvif/device_service GetSystemDateAndTime": [DH_TIME],
        "/onvif/device_service GetServices": [SIM_NOT_SUPPORTED],
        "/onvif/device_service GetCapabilities": [DH_CAPABILITIES]
    });
    def dh as Device init connect(fakeDevice($g));
    stopFake($g);
    testing.assertEqual($dh.services["events"], $g.base + "/onvif/event_service");
    testing.assertEqual($dh.services["deviceio"], $g.base + "/onvif/deviceIO_service");
}

# An authentication failure is no reason to try GetCapabilities.
func testConnectStopsOnAuthFailures() {
    def f as Fake init simFake({"/onvif/device_service GetServices": [SIM_NOT_AUTHORIZED]});
    try {
        connect(fakeDevice($f));
        missed("connect");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
        testing.assertEqual($e.subcode, "ter:NotAuthorized");
    }
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(len($seen), 2);
}

# A camera that refuses the unsigned clock read is asked once more, signed.
func testTheClockIsReadSignedWhenRefused() {
    def f as Fake init startFake({
        "/onvif/device_service GetSystemDateAndTime": [EZ_UNAUTHORIZED, EZ_TIME],
        "/onvif/device_service GetServices": [EZ_SERVICES]
    });
    def d as Device init connect(fakeDevice($f));
    def seen as list of Seen init stopFake($f);
    testing.assertFalse(strings.contains($seen[0].body, "UsernameToken"));
    testing.assertContains($seen[1].body, "UsernameToken");
    testing.assertTrue($d.clockSynced);
    testing.assertEqual($d.media, "media2");
    testing.assertEqual($d.services["search"], $f.base + "/onvif/SearchRecording");
    testing.assertEqual($d.services["media"], $f.base + "/onvif/Media");
}

func testVendorClocks() {
    def f as Fake init startFake({
        "/ez GetSystemDateAndTime": [EZ_TIME],
        "/dh GetSystemDateAndTime": [DH_TIME],
        "/sim GetSystemDateAndTime": [SIM_TIME]
    });
    def ez as Clock init systemDateAndTime(device($f.base + "/ez", USER, PASSWORD));
    testing.assertEqual(
        $ez,
        Clock{
            utc: "2026-10-07T17:46:20Z",
            dateTimeType: "NTP",
            daylightSavings: true,
            timeZone: "EST-1:00:00"
        });
    def dh as Clock init systemDateAndTime(device($f.base + "/dh", USER, PASSWORD));
    testing.assertEqual(
        $dh,
        Clock{
            utc: "2026-10-15T17:40:09Z",
            dateTimeType: "Manual",
            daylightSavings: false,
            timeZone: "GMT+01:00"
        });
    testing.assertEqual(
        systemDateAndTime(device($f.base + "/sim", "", "")).utc,
        "2026-11-14T19:32:04Z");
    stopFake($f);
}

func testMalformedClocks() {
    def noUtc as string init regex.replace('(?s)<tt:UTCDateTime>.*</tt:UTCDateTime>', SIM_TIME, "");
    def f as Fake init startFake({
        "/hour GetSystemDateAndTime": [
            strings.replace(SIM_TIME, "<tt:Hour>19</tt:Hour>", "<tt:Hour>25</tt:Hour>")
        ],
        "/day GetSystemDateAndTime": [
            strings.replace(SIM_TIME, "<tt:Day>14</tt:Day>", "<tt:Day>x</tt:Day>")
        ],
        "/feb GetSystemDateAndTime": [
            strings.replace(
                strings.replace(SIM_TIME, "<tt:Day>14</tt:Day>", "<tt:Day>31</tt:Day>"),
                "<tt:Month>11</tt:Month>",
                "<tt:Month>2</tt:Month>")
        ],
        "/none GetSystemDateAndTime": [$noUtc],
        "/empty GetSystemDateAndTime": [
            ok('<e:Envelope xmlns:e="http://www.w3.org/2003/05/soap-envelope"><e:Body><x:GetSystemDateAndTimeResponse xmlns:x="urn:x"/></e:Body></e:Envelope>')
        ]
    });
    for (def p in ["/hour", "/day", "/feb", "/empty"]) {
        try {
            syncClock(device($f.base + $p, USER, PASSWORD));
            missed($p);
        } catch (e) {
            testing.assertEqual($e.kind, ERROR_KIND);
            testing.assertEqual($e.status, 200);
            testing.assertContains($e.message, "onvif: GetSystemDateAndTime: ");
        }
    }
    def d as Device init syncClock(device($f.base + "/none", USER, PASSWORD));
    testing.assertFalse($d.clockSynced);
    testing.assertEqual($d.offsetMs, 0);
    stopFake($f);
}

func testDeviceInformation() {
    def f as Fake init simFake({"/onvif/device_service GetDeviceInformation": [SIM_INFO, EZ_INFO]});
    def d as Device init connect(fakeDevice($f));
    testing.assertEqual(
        deviceInformation($d),
        DeviceInfo{
            manufacturer: "OnvifSim",
            model: "SimCam",
            firmwareVersion: "0.0.1-sim",
            serialNumber: "SIM0000000001",
            hardwareId: "SIMHW1"
        });
    testing.assertEqual(
        deviceInformation($d),
        DeviceInfo{
            manufacturer: "EZVIZ",
            model: "DS-2DE2C400IG-W-W",
            firmwareVersion: "V5.3.8 build 260123",
            serialNumber: "REDACTED1",
            hardwareId: "88"
        });
    stopFake($f);
}

func testServicesScopesReboot() {
    def f as Fake init simFake({
        "/onvif/device_service GetScopes": [SIM_SCOPES],
        "/onvif/device_service SystemReboot": [SIM_REBOOT]
    });
    def d as Device init connect(fakeDevice($f));
    def all as list of Service init services($d);
    testing.assertEqual(len($all), 7);
    testing.assertEqual(
        $all[0],
        Service{
            name: "device",
            namespace: NS_DEVICE,
            address: $f.base + "/onvif/device_service",
            version: "19.12"
        });
    testing.assertEqual(
        scopes($d),
        [
            "onvif://www.onvif.org/Profile/Streaming",
            "onvif://www.onvif.org/Profile/T",
            "onvif://www.onvif.org/hardware/SimCam",
            "onvif://www.onvif.org/name/OnvifSim"
        ]);
    testing.assertEqual(reboot($d), "Rebooting...");
    def seen as list of Seen init stopFake($f);
    testing.assertContains($seen[2].body, "<tds:IncludeCapability>false</tds:IncludeCapability>");
}

func testVendorServices() {
    def f as Fake init startFake({
        "/ez GetServices": [EZ_SERVICES],
        "/dh GetServices": [DH_SERVICES],
        "/bad GetServices": [
            ok('<e:Envelope xmlns:e="http://www.w3.org/2003/05/soap-envelope"><e:Body><x:GetServicesResponse xmlns:x="urn:x"/></e:Body></e:Envelope>')
        ]
    });
    def ez as list of Service init services(device($f.base + "/ez", USER, PASSWORD));
    testing.assertEqual(len($ez), 11);
    testing.assertEqual($ez[2].name, "media2");
    testing.assertEqual($ez[2].address, $f.base + "/onvif/Media2");
    def dh as list of Service init services(device($f.base + "/dh", USER, PASSWORD));
    testing.assertEqual($dh[6].name, "events");
    try {
        services(device($f.base + "/bad", USER, PASSWORD));
        missed("no service");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: GetServices: the reply lists no service");
    }
    stopFake($f);
}

# Explicit settings win over discovery: a service set by withService before
# connect keeps its address (connect used to replace every service).
func testOverridesSurviveConnect() {
    def f as Fake init simFake({});
    def d as Device init withService(fakeDevice($f), "ptz", $f.base + "/my/ptz");
    $d = withService($d, "analytics", $f.base + "/my/analytics");
    $d = connect($d);
    stopFake($f);
    testing.assertEqual($d.services["ptz"], $f.base + "/my/ptz");
    testing.assertEqual($d.services["analytics"], $f.base + "/my/analytics");
    testing.assertEqual($d.services["media2"], $f.base + "/onvif/media2_service");
    testing.assertEqual($d.overrides, ["ptz", "analytics"]);
    testing.assertEqual(withService($d, "ptz", $f.base + "/p2").overrides, ["ptz", "analytics"]);
}

# The clock is read from the device service's address, which withService
# moves; it used to be read from the address given to device.
func testTheClockFollowsTheDeviceService() {
    def f as Fake init startFake({
        "/real/device GetSystemDateAndTime": [SIM_TIME],
        "/real/device GetServices": [SIM_SERVICES]
    });
    def d as Device init withService(fakeDevice($f), "device", $f.base + "/real/device");
    testing.assertTrue(syncClock($d).clockSynced);
    def c as Device init connect($d);
    testing.assertEqual($c.services["device"], $f.base + "/real/device");
    def seen as list of Seen init stopFake($f);
    for (def s in $seen) {
        testing.assertEqual($s.path, "/real/device");
    }
    testing.assertEqual(len($seen), 3);
}
