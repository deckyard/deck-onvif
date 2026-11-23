# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.27.0

# onvif - white-box tests for the media topic. Spliced into onvif_test.j via
# include.

/** The simulator's answers for both media services. */
def const SIM_MEDIA as map of string to list of string init {
    "/onvif/media2_service GetProfiles": [SIM_PROFILES2],
    "/onvif/media2_service GetStreamUri": [SIM_STREAM2],
    "/onvif/media2_service GetSnapshotUri": [SIM_SNAPSHOT_URI2],
    "/onvif/media_service GetProfiles": [SIM_PROFILES],
    "/onvif/media_service GetStreamUri": [SIM_STREAM],
    "/onvif/media_service GetSnapshotUri": [SIM_SNAPSHOT_URI]
};

func testProfilesOfBothMediaServices() {
    def f as Fake init simFake(SIM_MEDIA);
    def d as Device init connect(fakeDevice($f));
    def want as Profile init Profile{
        token: "Profile_0",
        name: "Profile_0",
        fixed: true,
        videoSource: "VideoSourceToken",
        encoding: "H264",
        width: 1920,
        height: 1080,
        ptz: "PTZCfgToken"
    };
    def two as list of Profile init profiles($d);
    testing.assertEqual(len($two), 2);
    testing.assertEqual($two[0], $want);
    testing.assertEqual($two[1].width, 640);
    def one as list of Profile init profiles(withMedia($d, "media"));
    testing.assertEqual($one[0], $want);
    testing.assertEqual($one[1].height, 360);
    def seen as list of Seen init stopFake($f);
    testing.assertContains($seen[2].body, "<tr2:Type>All</tr2:Type>");
    testing.assertEqual($seen[3].path, "/onvif/media_service");
}

func testStreamAndSnapshotUris() {
    def f as Fake init simFake(SIM_MEDIA);
    def d as Device init connect(fakeDevice($f));
    def host as string init uri.parse($f.base).host;
    testing.assertEqual(
        streamUri($d, "Profile_0"),
        Stream{
            address: "rtsp://172.17.0.3:554/ch0_0.h264",
            rebased: "rtsp://" + $host + ":554/ch0_0.h264"
        });
    testing.assertEqual(snapshotUri($d, "Profile_0"), $f.base + "/snapshot/snap.jpg");
    def m1 as Device init withMedia($d, "media");
    testing.assertEqual(streamUri($m1, "Profile_0"), streamUri($d, "Profile_0"));
    testing.assertEqual(snapshotUri($m1, "Profile_0"), $f.base + "/snapshot/snap.jpg");
    try {
        streamUri($d, "");
        missed("empty token");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    def seen as list of Seen init stopFake($f);
    testing.assertContains(
        $seen[2].body,
        "<tr2:Protocol>RtspUnicast</tr2:Protocol><tr2:ProfileToken>Profile_0</tr2:ProfileToken>");
    testing.assertEqual(field($seen[4].body, "Stream"), "RTP-Unicast");
    testing.assertEqual(field($seen[4].body, "Protocol"), "RTSP");
    testing.assertEqual(len($seen), 7);
}

func testVendorMedia() {
    def f as Fake init startFake({
        "/onvif/Media GetProfiles": [EZ_PROFILES],
        "/onvif/Media GetStreamUri": [EZ_STREAM],
        "/onvif/Media GetSnapshotUri": [EZ_SNAPSHOT_URI],
        "/onvif/media2_service GetProfiles": [DH_PROFILES2],
        "/onvif/media2_service GetStreamUri": [DH_STREAM2, DH_RTSPS_FAULT],
        "/onvif/media2_service GetSnapshotUri": [DH_SNAPSHOT_URI2],
        "/dvc GetProfiles": [DVC_PROFILES2]
    });
    def ez as Device init withService(fakeDevice($f), "media", $f.base + "/onvif/Media");
    def ezp as list of Profile init profiles($ez);
    testing.assertEqual(len($ezp), 2);
    testing.assertEqual($ezp[0].token, "Profile_1");
    testing.assertEqual($ezp[0].encoding, "H264");
    testing.assertEqual($ezp[0].ptz, "PTZToken");
    testing.assertEqual(
        streamUri($ez, "Profile_1").address,
        "rtsp://192.0.2.13:554/Streaming/Channels/101?transportmode=unicast&profile=Profile_1");
    testing.assertEqual(snapshotUri($ez, "Profile_1"), $f.base + "/onvif/snapshot?Profile_1");
    def dh as Device init withService(fakeDevice($f), "media2", $f.base + "/onvif/media2_service");
    def dhp as list of Profile init profiles($dh);
    testing.assertEqual($dhp[0].token, "MediaProfile00000");
    testing.assertEqual($dhp[0].videoSource, "00000");
    testing.assertEqual(
        streamUri($dh, "MediaProfile00000").address,
        "rtsp://192.0.2.13:554/cam/realmonitor?channel=1&subtype=0&unicast=true&proto=Onvif");
    try {
        streamUri($dh, "MediaProfile00000");
        missed("rtsps");
    } catch (e) {
        testing.assertEqual($e.subcodes, ["ter:InvalidArgVal", "ter:InvalidStreamSetup"]);
    }
    testing.assertEqual(
        snapshotUri($dh, "MediaProfile00000"),
        "https://192.0.2.13/onvif/snapshot?channel=1&subtype=0");
    def dvc as Device init withService(fakeDevice($f), "media2", $f.base + "/dvc");
    def dvcp as list of Profile init profiles($dvc);
    testing.assertTrue(len($dvcp) > 0);
    testing.assertTrue($dvcp[0].width > 0);
    stopFake($f);
}

func testMediaNeedsAService() {
    try {
        profiles(device("http://10.0.0.1/onvif/device_service", USER, PASSWORD));
        missed("no media");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: the device has no media service; connect first");
    }
}

func testMediaUrisAreChecked() {
    def bad as string init strings.replace(
        SIM_STREAM2,
        "rtsp://172.17.0.3:554/ch0_0.h264",
        "javascript:alert(1)");
    def f as Fake init simFake({
        "/onvif/media2_service GetStreamUri": [$bad],
        "/onvif/media2_service GetSnapshotUri": [SIM_STREAM2]
    });
    def d as Device init connect(fakeDevice($f));
    try {
        streamUri($d, "Profile_0");
        missed("bad uri");
    } catch (e) {
        testing.assertEqual($e.status, 200);
        testing.assertContains($e.message, "not a rtsps? URI");
    }
    try {
        snapshotUri($d, "Profile_0");
        missed("rtsp snapshot");
    } catch (e) {
        testing.assertContains($e.message, "not a https? URI");
    }
    stopFake($f);
}

# A snapshot URL nothing answers on is the transport's net.NetError.
func testSnapshotTransportFailurePassesOn() {
    def f as Fake init simFake({
        "/onvif/media2_service GetSnapshotUri": [
            strings.replace(SIM_SNAPSHOT_URI2, "172.17.0.3:8080", closedAddress())
        ]
    });
    def d as Device init connect(fakeDevice($f));
    try {
        snapshot($d, "Profile_0");
        missed("net");
    } catch (e) {
        testing.assertEqual($e.kind, "net");
        def n as net.NetError init $e;
        testing.assertEqual($n.reason, "refused");
        testing.assertFalse($n.sent);
    }
    stopFake($f);
}

func testSnapshotWithHttpDigest() {
    def f as Fake init simFake({
        "/onvif/media2_service GetSnapshotUri": [SIM_SNAPSHOT_URI2],
        "/snapshot/snap.jpg GET": [
            "401\nWWW-Authenticate: " + SIM_CHALLENGE +
                "\nContent-Type: text/html\n\n<html>401</html>",
            "200\nContent-Type: image/jpeg\n\nbase64:" + SIM_JPEG
        ]
    });
    def d as Device init connect(fakeDevice($f));
    def jpg as bytes init snapshot($d, "Profile_0");
    testing.assertEqual($jpg, encoding.fromText("base64", SIM_JPEG));
    testing.assertEqual(len($jpg), 677);
    def seen as list of Seen init stopFake($f);
    testing.assertEqual($seen[3].authorization, "");
    def auth as string init $seen[4].authorization;
    testing.assertContains(
        $auth,
        "Digest username=\"admin\", realm=\"OnvifSim\", uri=\"/snapshot/snap.jpg\", algorithm=MD5");
    testing.assertContains($auth, "qop=auth");
    testing.assertFalse(strings.contains($auth, PASSWORD));
}

func testSnapshotFailures() {
    def page as string init "200\nContent-Type: text/html\n\n<html>login</html>";
    def f as Fake init simFake({
        "/onvif/media2_service GetSnapshotUri": [SIM_SNAPSHOT_URI2],
        "/snapshot/snap.jpg GET": [
            "401\nWWW-Authenticate: Basic realm=\"cam\"\nContent-Type: text/html\n\n401",
            $page,
            "404\nContent-Type: text/html\n\nnone",
            "401\nWWW-Authenticate: Bearer\nContent-Type: text/html\n\n401",
            "200\nContent-Type: application/octet-stream\n\nbase64:" + SIM_JPEG,
            "200\nContent-Type: image/jpeg\n\n" + strings.replicate("x", 5000)
        ]
    });
    def d as Device init connect(fakeDevice($f));
    try {
        snapshot($d, "Profile_0");
        missed("basic over http");
    } catch (e) {
        testing.assertEqual($e.status, 401);
        testing.assertContains($e.message, "HTTP Basic over plain http");
    }
    try {
        snapshot($d, "Profile_0");
        missed("a page");
    } catch (e) {
        testing.assertEqual(
            $e.message,
            "onvif: snapshot: the answer is not an image (\"text/html\")");
    }
    try {
        snapshot($d, "Profile_0");
        missed("404");
    } catch (e) {
        testing.assertEqual($e.status, 404);
    }
    try {
        snapshot($d, "Profile_0");
        missed("bearer");
    } catch (e) {
        testing.assertContains($e.message, "without a Digest or Basic challenge");
    }
    # a JPEG without an image type still passes: its first bytes say JPEG
    testing.assertEqual(len(snapshot($d, "Profile_0")), 677);
    try {
        snapshot(withMaxMediaBytes($d, 4096), "Profile_0");
        missed("limit");
    } catch (e) {
        testing.assertEqual($e.kind, "limit");
        testing.assertContains($e.message, "onvif: snapshot: GET ");
    }
    stopFake($f);
}

# A stream comes back as the camera gave it and on the device's host, the
# RTSP port and everything else kept (it was the camera's URL alone).
func testStreamIsAlsoRebased() {
    def d as Device init device("http://10.0.0.5:8080/onvif/device_service", USER, PASSWORD);
    testing.assertEqual(
        onDeviceHost($d, "rtsp://u:p@192.168.1.64:554/Streaming/101?a=1", "x"),
        "rtsp://u:p@10.0.0.5:554/Streaming/101?a=1");
    testing.assertEqual(
        onDeviceHost($d, "rtsps://[fd00::7]:322/live", "x"),
        "rtsps://10.0.0.5:322/live");
    def v6 as Device init device("http://[fe80::1]:8080/onvif/device_service", USER, PASSWORD);
    testing.assertEqual(onDeviceHost($v6, "rtsp://192.168.1.64/x", "x"), "rtsp://[fe80::1]/x");
}

# The snapshot address is placed like the service addresses: kept on the
# device's host (its own port), else moved onto the device's origin; it used
# to keep a foreign port, which a NAT does not forward.
func testSnapshotFollowsTheServiceRule() {
    def d as Device init device("http://10.0.0.5:8080/onvif/device_service", USER, PASSWORD);
    testing.assertEqual(
        rebase($d, "http://203.0.113.9:81/snap.jpg?x=1", "x"),
        "http://10.0.0.5:8080/snap.jpg?x=1");
    testing.assertEqual(
        rebase($d, "http://10.0.0.5:81/snap.jpg?x=1", "x"),
        "http://10.0.0.5:81/snap.jpg?x=1");
    testing.assertEqual(
        rebase($d, "https://172.17.0.3/snap.jpg", "x"),
        "http://10.0.0.5:8080/snap.jpg");
    testing.assertTrue(isImage(encoding.fromText("base64", SIM_JPEG)));
    testing.assertTrue(isImage(encoding.fromText("hex", "89504e470d0a1a0a")));
    testing.assertFalse(isImage(encoding.encode("utf-8", "<html>")));
}

# User information in a snapshot URI is dropped: never sent, never shown;
# the device's own credentials answer the challenge (it was refused).
func testSnapshotDropsUserInfo() {
    def withUser as string init strings.replace(
        SIM_SNAPSHOT_URI2,
        "http://172.17.0.3:8080/snapshot/snap.jpg",
        "http://viewer:hunter2@172.17.0.3:8080/snapshot/snap.jpg");
    def f as Fake init simFake({
        "/onvif/media2_service GetSnapshotUri": [$withUser],
        "/snapshot/snap.jpg GET": [
            "401\nWWW-Authenticate: " + SIM_CHALLENGE +
                "\nContent-Type: text/html\n\n<html>401</html>",
            "200\nContent-Type: image/jpeg\n\nbase64:" + SIM_JPEG,
            "404\nContent-Type: text/html\n\nnone"
        ]
    });
    def d as Device init connect(fakeDevice($f));
    testing.assertEqual(snapshotUri($d, "Profile_0"), $f.base + "/snapshot/snap.jpg");
    testing.assertEqual(len(snapshot($d, "Profile_0")), 677);
    try {
        snapshot($d, "Profile_0");
        missed("404");
    } catch (e) {
        testing.assertEqual($e.status, 404);
        testing.assertFalse(strings.contains($e.message, "hunter2"));
        testing.assertFalse(strings.contains($e.message, "viewer"));
    }
    def seen as list of Seen init stopFake($f);
    for (def s in $seen) {
        testing.assertFalse(strings.contains($s.authorization, "hunter2"));
        testing.assertFalse(strings.contains($s.authorization, "viewer"));
    }
    testing.assertContains($seen[5].authorization, "Digest username=\"admin\"");
    testing.assertEqual(
        withoutUserInfo(" http://a:b@[fd00::1]:81/s.jpg?u=1 ", "x"),
        "http://[fd00::1]:81/s.jpg?u=1");
    try {
        withoutUserInfo("snap.jpg", "a snapshot address");
        missed("relative");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
}
