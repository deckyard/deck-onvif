# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.27.0

# onvif - white-box tests for the ptz topic. Spliced into onvif_test.j via
# include.

func testMoves() {
    def f as Fake init simFake({
        "/onvif/ptz_service ContinuousMove": [SIM_CONTINUOUS],
        "/onvif/ptz_service AbsoluteMove": [SIM_ABSOLUTE, SIM_INVALID_POSITION, EZ_ABSOLUTE],
        "/onvif/ptz_service RelativeMove": [SIM_RELATIVE],
        "/onvif/ptz_service Stop": [SIM_STOP]
    });
    def d as Device init connect(fakeDevice($f));
    continuousMove($d, "Profile_0", 0.5, -1.0, 0.0);
    continuousMove($d, "Profile_0", 0.0, 0.0, 0.25);
    absoluteMove($d, "Profile_0", -1.0, 1.0, 0.5);
    try {
        absoluteMove($d, "Profile_0", 0.25, -0.5, 0.0);
        missed("invalid position");
    } catch (e) {
        testing.assertEqual($e.subcodes, ["ter:InvalidArgVal", "ter:InvalidPosition"]);
        testing.assertEqual($e.status, 500);
    }
    try {
        absoluteMove($d, "Profile_0", 0.25, -0.5, 0.0);
        missed("space not supported");
    } catch (e) {
        testing.assertEqual($e.subcodes, ["ter:InvalidArgVal", "ter:SpaceNotSupported"]);
    }
    relativeMove($d, "Profile_0", 0.1, -0.1, 0.0);
    stopMove($d, "Profile_0");
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(len($seen), 9);
    testing.assertContains(
        $seen[2].body,
        "<tptz:ProfileToken>Profile_0</tptz:ProfileToken><tptz:Velocity>");
    testing.assertContains($seen[2].body, "PanTilt x=\"0.5\" y=\"-1.0\"");
    testing.assertFalse(strings.contains($seen[2].body, "Zoom"));
    testing.assertContains($seen[3].body, "Zoom x=\"0.25\"");
    testing.assertContains($seen[4].body, "<tptz:Position>");
    testing.assertContains($seen[4].body, "<tt:Zoom x=\"0.5\"");
    testing.assertContains($seen[7].body, "<tptz:Translation>");
    testing.assertContains(
        $seen[8].body,
        "<tptz:PanTilt>true</tptz:PanTilt><tptz:Zoom>true</tptz:Zoom>");
    testing.assertContains(
        $seen[8].contentType,
        "action=\"http://www.onvif.org/ver20/ptz/wsdl/Stop\"");
}

# Ranges and tokens are checked before anything is sent.
func testMovesCheckTheirInput() {
    def d as Device init withService(
        device("http://192.168.1.64/onvif/device_service", USER, PASSWORD),
        "ptz",
        "http://192.168.1.64/onvif/PTZ");
    def bad as list of list of float init [[1.5, 0.0, 0.0], [0.0, -1.01, 0.0], [0.0, 0.0, 2.0]];
    for (def v in $bad) {
        try {
            continuousMove($d, "Profile_0", $v[0], $v[1], $v[2]);
            missed("velocity");
        } catch (e) {
            testing.assertEqual($e.kind, ERROR_KIND);
            testing.assertEqual($e.status, 0);
        }
        try {
            relativeMove($d, "Profile_0", $v[0], $v[1], $v[2]);
            missed("translation");
        } catch (e) {
            testing.assertContains($e.message, " step is -1.0 to 1.0");
        }
    }
    try {
        absoluteMove($d, "Profile_0", 0.0, 0.0, -0.5);
        missed("zoom");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: a zoom position is 0.0 to 1.0, got -0.5");
    }
    for (def token in ["", strings.replicate("p", 65)]) {
        try {
            stopMove($d, $token);
            missed("token");
        } catch (e) {
            testing.assertContains($e.message, "profile token");
        }
    }
    try {
        stopMove(device("http://192.168.1.64/onvif/device_service", USER, PASSWORD), "Profile_0");
        missed("no ptz");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: the device has no ptz service");
    }
}

func testStatus() {
    def f as Fake init simFake({"/onvif/ptz_service GetStatus": [SIM_PTZ_STATUS, EZ_PTZ_STATUS]});
    def d as Device init connect(fakeDevice($f));
    testing.assertEqual(
        ptzStatus($d, "Profile_0"),
        PtzStatus{
            pan: 180.0,
            tilt: 90.0,
            zoom: 0.0,
            panTiltMoving: false,
            zoomMoving: false,
            error: "",
            utcTime: "2026-11-14T19:32:04Z"
        });
    def ez as PtzStatus init ptzStatus($d, "Profile_0");
    testing.assertTrue($ez.panTiltMoving);
    testing.assertTrue($ez.zoomMoving);
    testing.assertEqual($ez.error, "NO error");
    testing.assertEqual($ez.pan, 0.0);
    stopFake($f);
}

func testPresets() {
    def f as Fake init simFake({
        "/onvif/ptz_service GetPresets": [SIM_PRESETS, EZ_PRESETS],
        "/onvif/ptz_service SetPreset": [SIM_SET_PRESET],
        "/onvif/ptz_service GotoPreset": [SIM_GOTO_PRESET, SIM_NO_TOKEN, EZ_GOTO_MISSING],
        "/onvif/ptz_service RemovePreset": [SIM_REMOVE_PRESET]
    });
    def d as Device init connect(fakeDevice($f));
    testing.assertEqual(setPreset($d, "Profile_0", "Door"), "PresetToken_1");
    testing.assertEqual(
        presets($d, "Profile_0"),
        [Preset{token: "PresetToken_1", name: "Door", pan: 90.0, tilt: 45.0, zoom: 0.0}]);
    testing.assertEqual(
        presets($d, "Profile_0"),
        [Preset{token: "1", name: "onviftest", pan: 0.0, tilt: 0.0, zoom: 0.0}]);
    gotoPreset($d, "Profile_0", "PresetToken_1");
    try {
        gotoPreset($d, "Profile_0", "PresetToken_1");
        missed("no token");
    } catch (e) {
        testing.assertEqual($e.subcodes, ["ter:InvalidArgVal", "ter:NoToken"]);
    }
    try {
        gotoPreset($d, "Profile_0", "99");
        missed("illegal");
    } catch (e) {
        testing.assertEqual($e.subcodes, ["ter:InvalidArgVal", "ter:InvalidParameter"]);
        testing.assertEqual($e.reason, "the parameter value is illegal");
    }
    removePreset($d, "Profile_0", "PresetToken_1");
    testing.assertThrowsArgs("removePreset", [$d, "Profile_0", ""], ERROR_KIND);
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(field($seen[2].body, "PresetName"), "Door");
    testing.assertEqual(field($seen[5].body, "PresetToken"), "PresetToken_1");
    testing.assertEqual(field($seen[8].body, "PresetToken"), "PresetToken_1");
}

# Every move names its generic space, so the -1..1 (zoom 0..1) checks mean
# what the head reads; without it the head used its default space, degrees
# on the simulator. A head without the space refuses with a fault
# (recorded on EZVIZ).
func testMovesNameTheGenericSpaces() {
    def f as Fake init simFake({
        "/onvif/ptz_service ContinuousMove": [SIM_CONTINUOUS],
        "/onvif/ptz_service AbsoluteMove": [SIM_ABSOLUTE, EZ_ABSOLUTE],
        "/onvif/ptz_service RelativeMove": [SIM_RELATIVE]
    });
    def d as Device init connect(fakeDevice($f));
    continuousMove($d, "Profile_0", 0.5, 0.0, 0.25);
    absoluteMove($d, "Profile_0", 0.5, 0.5, 0.5);
    relativeMove($d, "Profile_0", 0.1, 0.1, 0.1);
    try {
        absoluteMove($d, "Profile_0", 0.0, 0.0, 0.0);
        missed("space not supported");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
        testing.assertEqual($e.subcode, "ter:InvalidArgVal");
        testing.assertTrue(lists.contains($e.subcodes, "ter:SpaceNotSupported"));
    }
    def seen as list of Seen init stopFake($f);
    def kinds as list of string init ["Velocity", "Position", "Translation"];
    for (def i in 0..3) {
        def body as string init $seen[$i + 2].body;
        testing.assertContains($body, "space=\"" + PANTILT_SPACES + $kinds[$i] + "GenericSpace\"");
        testing.assertContains($body, "space=\"" + ZOOM_SPACES + $kinds[$i] + "GenericSpace\"");
    }
    testing.assertEqual(PANTILT_SPACES, "http://www.onvif.org/ver10/tptz/PanTiltSpaces/");
    testing.assertEqual(ZOOM_SPACES, "http://www.onvif.org/ver10/tptz/ZoomSpaces/");
}
