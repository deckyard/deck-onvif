# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.27.0

# onvif - white-box tests for the events topic. Spliced into onvif_test.j via
# include.

/** The simulator's event answers, in the order of a subscription's life. */
def const SIM_EVENTS as map of string to list of string init {
    "/onvif/events_service CreatePullPointSubscription": [SIM_SUBSCRIBE],
    "/onvif/events_service?sub=1 PullMessages": [SIM_PULL, SIM_PULL_MOTION, SIM_RESOURCE_UNKNOWN],
    "/onvif/events_service?sub=1 Renew": [SIM_RENEW],
    "/onvif/events_service?sub=1 Unsubscribe": [SIM_UNSUBSCRIBE]
};

func testASubscriptionsLife() {
    def f as Fake init simFake(SIM_EVENTS);
    def d as Device init connect(fakeDevice($f));
    def sub as Subscription init subscribe($d, 60);
    testing.assertEqual(
        $sub,
        Subscription{
            address: $f.base + "/onvif/events_service?sub=1",
            reference: $f.base + "/onvif/events_service?sub=1",
            parameters: [],
            currentTime: "2026-11-14T19:32:05Z",
            terminationTime: "2026-11-14T19:33:05Z"
        });
    def p1 as Pulled init pull($d, $sub, 2, 10);
    def first as list of Event init $p1.events;
    testing.assertEqual(len($first), 3);
    testing.assertEqual(
        $first[0],
        Event{
            topic: "tns1:VideoSource/MotionAlarm",
            utcTime: "2026-11-14T19:32:05Z",
            operation: "Initialized",
            source: {"Source": "VideoSourceToken"},
            key: {},
            data: {"State": "false"}
        });
    testing.assertEqual($first[2].topic, "tns1:Device/Trigger/Relay");
    testing.assertEqual($first[2].data, {"LogicalState": "inactive"});
    def p2 as Pulled init pull($d, $p1.subscription, 2, 10);
    def motion as list of Event init $p2.events;
    testing.assertEqual($p2.subscription.currentTime, "2026-11-14T19:32:09Z");
    testing.assertEqual($motion[0].operation, "Changed");
    testing.assertEqual($motion[0].data["State"], "true");
    $sub = renew($d, $sub, 120);
    testing.assertEqual($sub.terminationTime, "2026-11-14T19:34:09Z");
    testing.assertEqual($sub.currentTime, "2026-11-14T19:32:09Z");
    unsubscribe($d, $sub);
    try {
        pull($d, $sub, 1, 10);
        missed("after unsubscribe");
    } catch (e) {
        testing.assertEqual($e.code, "Receiver");
        testing.assertEqual(
            $e.subcode,
            '{http://docs.oasis-open.org/wsrf/rw-2}ResourceUnknownFault');
    }
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(field($seen[2].body, "InitialTerminationTime"), "PT60S");
    testing.assertContains($seen[2].contentType, "action=\"" + CREATE_ACTION + "\"");
    testing.assertEqual(field($seen[3].body, "Timeout"), "PT2S");
    testing.assertEqual(field($seen[3].body, "MessageLimit"), "10");
    testing.assertEqual(field($seen[3].body, "Action"), PULL_ACTION);
    testing.assertEqual(field($seen[3].body, "To"), $f.base + "/onvif/events_service?sub=1");
    testing.assertContains(field($seen[3].body, "MessageID"), "urn:uuid:");
    testing.assertContains($seen[3].body, "UsernameToken");
    testing.assertEqual(field($seen[5].body, "TerminationTime"), "PT120S");
    testing.assertEqual($seen[6].op, "Unsubscribe");
}

func testEventInputIsChecked() {
    def d as Device init withService(
        device("http://10.0.0.1/onvif/device_service", USER, PASSWORD),
        "events",
        "http://10.0.0.1/e");
    def sub as Subscription init Subscription{
        address: "http://10.0.0.1/s",
        reference: "http://10.0.0.1/s",
        parameters: [],
        currentTime: "",
        terminationTime: ""
    };
    for (def n in [9, 86401]) {
        try {
            subscribe($d, $n);
            missed("subscribe");
        } catch (e) {
            testing.assertContains($e.message, "10 to 86400 seconds");
        }
        try {
            renew($d, $sub, $n);
            missed("renew");
        } catch (e) {
            testing.assertContains($e.message, "10 to 86400 seconds");
        }
    }
    for (def bad in [[0, 1], [61, 1], [1, 0], [1, 1025]]) {
        try {
            pull($d, $sub, $bad[0], $bad[1]);
            missed("pull");
        } catch (e) {
            testing.assertEqual($e.kind, ERROR_KIND);
        }
    }
    try {
        subscribe(device("http://10.0.0.1/onvif/device_service", USER, PASSWORD), 60);
        missed("no events");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: the device has no events service");
    }
}

# More events than asked for is an error, not a silent cut.
func testPullHonoursTheLimit() {
    def f as Fake init simFake(SIM_EVENTS);
    def d as Device init connect(fakeDevice($f));
    try {
        pull($d, subscribe($d, 60), 2, 2);
        missed("limit");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: PullMessages: 3 events, over the limit of 2");
    }
    stopFake($f);
}

# A Hikvision address with a raw % is used as given; Dahua's carries a query.
func testVendorSubscriptions() {
    def f as Fake init startFake({
        "/onvif/Events CreatePullPointSubscription": [EZ_SUBSCRIBE],
        # httpd hands the path over decoded: %17 is U+0017
        "/onvif/Events/PullSubManager_2026-10-07\u0017:46:23_0 PullMessages": [EZ_PULL_MOTION],
        "/onvif/event_service CreatePullPointSubscription": [DH_SUBSCRIBE],
        "/onvif/Subscription?Idx=0 PullMessages": [DH_PULL],
        "/onvif/Subscription?Idx=0 Unsubscribe": [DH_UNSUBSCRIBE]
    });
    def ez as Device init withService(fakeDevice($f), "events", $f.base + "/onvif/Events");
    def es as Subscription init subscribe($ez, 60);
    testing.assertEqual(
        $es.address,
        $f.base + "/onvif/Events/PullSubManager_2026-10-07%17:46:23_0");
    def got as list of Event init pull($ez, $es, 5, 10).events;
    testing.assertEqual($got[0].source, {"Source": "VideoSource_1"});
    testing.assertEqual($got[0].data, {"State": "true"});
    def dh as Device init withService(fakeDevice($f), "events", $f.base + "/onvif/event_service");
    def ds as Subscription init subscribe($dh, 60);
    def all as list of Event init pull($dh, $ds, 5, 100).events;
    testing.assertEqual($all[0].topic, "tns1:RuleEngine/CellMotionDetector/Motion");
    testing.assertEqual($all[0].source["Rule"], "00000");
    testing.assertEqual($all[0].data, {"IsMotion": "false"});
    unsubscribe($dh, $ds);
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(len($seen), 5);
    testing.assertEqual($seen[1].path, "/onvif/Events/PullSubManager_2026-10-07\u0017:46:23_0");
}

# Axis (the ONVIF guide) names the subscription by a reference parameter,
# which goes back as a header block on every call.
func testReferenceParametersGoBack() {
    def f as Fake init startFake({
        "/onvif/services CreatePullPointSubscription": [APG_SUBSCRIBE],
        "/onvif/services PullMessages": [APG_PULL]
    });
    def d as Device init withService(fakeDevice($f), "events", $f.base + "/onvif/services");
    def sub as Subscription init subscribe($d, 60);
    testing.assertEqual($sub.address, $f.base + "/onvif/services");
    testing.assertEqual(len($sub.parameters), 1);
    def got as list of Event init pull($d, $sub, 5, 10).events;
    testing.assertEqual($got[0].topic, "tns1:Device/tnsvendor:IO/VirtualPort");
    testing.assertEqual($got[0].source, {"port": "0"});
    testing.assertEqual($got[0].key, {});
    testing.assertEqual($got[0].data, {"state": "0"});
    def seen as list of Seen init stopFake($f);
    def env as soap.Envelope init soap.parse($seen[1].body);
    def ref as xml.Value init $env.headers[4];
    testing.assertEqual(xml.localName($ref), "SubscriptionId");
    testing.assertEqual(xml.namespace($ref), "http://www.example.com/2009/event");
    testing.assertEqual(xml.text($ref), "6");
    testing.assertEqual(xml.attrNS($ref, WSA_NS, "IsReferenceParameter"), "true");
}

func testTopics() {
    def t as xml.Value init xml.decode('<w:Topic xmlns:w="urn:w" xmlns:o="http://www.onvif.org/ver10/topics">o:VideoSource/MotionAlarm</w:Topic>');
    testing.assertEqual(topicOf($t), "tns1:VideoSource/MotionAlarm");
    def v as xml.Value init xml.decode('<w:Topic xmlns:w="urn:w" xmlns:v="urn:vendor">v:Thing/Else</w:Topic>');
    testing.assertEqual(topicOf($v), "v:Thing/Else");
    testing.assertEqual(topicOf(xml.decode('<Topic>p:Unbound</Topic>')), "p:Unbound");
    testing.assertEqual(duration(60), "PT60S");
}

# Event values are data: kept whole and in any script, only control
# characters replaced (they were cut at 120 characters and non-ASCII
# turned into ?).
func testEventTextIsKeptWhole() {
    def long as string init strings.replicate("0123456789", 20);
    def pulled as string init strings.replace(
        SIM_PULL_MOTION,
        'Name="State" Value="true"',
        'Name="Zone S&#252;d" Value="' + $long + '&#x9b;"');
    def f as Fake init simFake({
        "/onvif/events_service CreatePullPointSubscription": [SIM_SUBSCRIBE],
        "/onvif/events_service?sub=1 PullMessages": [$pulled]
    });
    def d as Device init connect(fakeDevice($f));
    def got as list of Event init pull($d, subscribe($d, 60), 2, 10).events;
    stopFake($f);
    testing.assertEqual($got[0].data, {"Zone Süd": $long + "?"});
}

# A pull hands back the times the device sent with the events: a device may
# extend a subscription that is pulled (the old pull dropped them).
func testPullReportsTheTerminationTime() {
    def later as string init strings.replace(
        SIM_PULL_MOTION,
        "<tev:TerminationTime>2026-11-14T19:33:05Z<",
        "<tev:TerminationTime>2026-11-14T19:43:05Z<");
    def f as Fake init simFake({
        "/onvif/events_service CreatePullPointSubscription": [SIM_SUBSCRIBE],
        "/onvif/events_service?sub=1 PullMessages": [$later]
    });
    def d as Device init connect(fakeDevice($f));
    def sub as Subscription init subscribe($d, 60);
    testing.assertEqual($sub.terminationTime, "2026-11-14T19:33:05Z");
    def p as Pulled init pull($d, $sub, 2, 10);
    stopFake($f);
    testing.assertEqual(len($p.events), 1);
    testing.assertEqual($p.subscription.terminationTime, "2026-11-14T19:43:05Z");
    testing.assertEqual($p.subscription.currentTime, "2026-11-14T19:32:09Z");
    testing.assertEqual($p.subscription.address, $sub.address);
}

# Behind NAT the requests go to the device's origin, but WS-Addressing To
# names the subscription as the camera gave it (it was the rebased one).
func testToIsTheCamerasAddress() {
    def inner as string init "http://192.0.2.77:8080/onvif/events_service?sub=1";
    def f as Fake init simFake({
        "/onvif/events_service CreatePullPointSubscription": [
            strings.replace(
                SIM_SUBSCRIBE,
                "http://172.17.0.3:8080/onvif/events_service?sub=1",
                $inner)
        ],
        "/onvif/events_service?sub=1 PullMessages": [SIM_PULL],
        "/onvif/events_service?sub=1 Renew": [SIM_RENEW],
        "/onvif/events_service?sub=1 Unsubscribe": [SIM_UNSUBSCRIBE]
    });
    def d as Device init connect(fakeDevice($f));
    def sub as Subscription init subscribe($d, 60);
    testing.assertEqual($sub.address, $f.base + "/onvif/events_service?sub=1");
    testing.assertEqual($sub.reference, $inner);
    $sub = pull($d, $sub, 2, 10).subscription;
    $sub = renew($d, $sub, 60);
    unsubscribe($d, $sub);
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(len($seen), 6);
    for (def i in 3..6) {
        testing.assertEqual($seen[$i].path, "/onvif/events_service?sub=1");
        testing.assertEqual(field($seen[$i].body, "To"), $inner);
    }
}
