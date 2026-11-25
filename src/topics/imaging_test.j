# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.28.0

# onvif - white-box tests for the imaging topic. Spliced into onvif_test.j via
# include.

func testImagingSettings() {
    def f as Fake init simFake({
        "/onvif/imaging_service GetImagingSettings": [SIM_IMAGING, EZ_IMAGING, DH_NO_SOURCE]
    });
    def d as Device init connect(fakeDevice($f));
    testing.assertEqual(
        imagingSettings($d, "VideoSourceToken"),
        ImagingSettings{
            values: {"Brightness": 0.5, "ColorSaturation": 0.5, "Contrast": 0.5, "Sharpness": 0.5},
            focusMode: "MANUAL",
            irCutFilter: "ON"
        });
    def ez as ImagingSettings init imagingSettings($d, "VideoSource_1");
    testing.assertEqual($ez.values["Brightness"], 50.0);
    testing.assertEqual($ez.irCutFilter, "AUTO");
    try {
        imagingSettings($d, "nope");
        missed("no source");
    } catch (e) {
        # Dahua sends this fault with HTTP 200
        testing.assertEqual($e.status, 200);
        testing.assertEqual($e.subcodes, ["ter:InvalidArgVal", "ter:NoSource"]);
    }
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(field($seen[2].body, "VideoSourceToken"), "VideoSourceToken");
}

func testBrightness() {
    def f as Fake init simFake({
        "/onvif/imaging_service GetOptions": [
            SIM_IMAGING_OPTIONS,
            SIM_IMAGING_OPTIONS,
            SIM_IMAGING_OPTIONS,
            EZ_IMAGING_OPTIONS
        ],
        "/onvif/imaging_service SetImagingSettings": [SIM_SET_IMAGING]
    });
    def d as Device init connect(fakeDevice($f));
    testing.assertEqual(brightnessRange($d, "VideoSourceToken"), Range{min: 0.0, max: 1.0});
    setBrightness($d, "VideoSourceToken", 0.6);
    try {
        setBrightness($d, "VideoSourceToken", 60.0);
        missed("range");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: the brightness is 0.0 to 1.0, got 60.0");
    }
    testing.assertEqual(brightnessRange($d, "VideoSource_1"), Range{min: 0.0, max: 100.0});
    def seen as list of Seen init stopFake($f);
    # the out-of-range value was never sent
    testing.assertEqual(len($seen), 7);
    testing.assertEqual($seen[5].op, "GetOptions");
    testing.assertEqual(field($seen[4].body, "Brightness"), "0.6");
    testing.assertEqual(field($seen[4].body, "ForcePersistence"), "true");
}

func testFocus() {
    def f as Fake init simFake({
        "/onvif/imaging_service GetMoveOptions": [SIM_MOVE_OPTIONS],
        "/onvif/imaging_service Move": [SIM_FOCUS_MOVE],
        "/onvif/imaging_service Stop": [SIM_FOCUS_STOP],
        "/onvif/imaging_service SetImagingSettings": [SIM_SET_IMAGING]
    });
    def d as Device init connect(fakeDevice($f));
    setFocusMode($d, "VideoSourceToken", "MANUAL");
    testing.assertEqual(focusSpeedRange($d, "VideoSourceToken"), Range{min: -1.0, max: 1.0});
    focusMove($d, "VideoSourceToken", -0.5);
    focusStop($d, "VideoSourceToken");
    try {
        focusMove($d, "VideoSourceToken", 2.0);
        missed("speed");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: a focus speed is -1.0 to 1.0, got 2.0");
    }
    try {
        setFocusMode($d, "VideoSourceToken", "auto");
        missed("mode");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(field($seen[2].body, "AutoFocusMode"), "MANUAL");
    testing.assertEqual(field($seen[5].body, "Speed"), "-0.5");
    testing.assertEqual($seen[6].op, "Stop");
    testing.assertEqual(len($seen), 8);
}

func testRangesAreChecked() {
    def a as Answer init Answer{
        body: xml.decode('<r><b><Min>5</Min><Max>1</Max></b><c><Min>1</Min></c></r>'),
        status: 200,
        digest: false
    };
    try {
        rangeOf(xml.get($a.body, "b"), "B", $a);
        missed("min above max");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: r: B Min is above Max");
    }
    try {
        rangeOf(xml.get($a.body, "c"), "C", $a);
        missed("no max");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: r: the reply has no Max");
    }
}
