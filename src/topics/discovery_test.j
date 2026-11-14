# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

# onvif - white-box tests for the discovery topic. Spliced into onvif_test.j via
# include.

/**
 * Answer two Probes on a loopback UDP socket: a datagram that is no XML, a
 * ProbeMatches for someone else, then the recorded ProbeMatches for each
 * Probe (the same device twice).
 *
 * @param sock {net.UDPSocket} the socket
 * @return {list of string} the Probes received
 */
func serveProbes(sock as net.UDPSocket) {
    def got as list of string init [];
    for (def i in 0..2) {
        def dg as net.Datagram init net.recvFrom($sock, 65535);
        def text as string init convert.stringFromBytes("utf-8", $dg.data);
        $got[] = $text;
        def id as string init field($text, "MessageID");
        net.sendTo($sock, $dg.peer, convert.bytesFromString("utf-8", "not xml"));
        net.sendTo($sock, $dg.peer, convert.bytesFromString("utf-8", SIM_PROBE_MATCHES));
        net.sendTo(
            $sock,
            $dg.peer,
            convert.bytesFromString("utf-8", strings.replace(SIM_PROBE_MATCHES, SIM_PROBE_ID, $id)));
    }
    return $got;
}

func testProbeMessage() {
    def env as soap.Envelope init soap.parse(probeMessage("urn:uuid:1", "NetworkVideoTransmitter"));
    testing.assertEqual($env.version, "1.2");
    testing.assertEqual(len($env.headers), 3);
    testing.assertEqual(xml.namespace($env.headers[0]), WSA04_NS);
    testing.assertEqual(xml.text($env.headers[0]), "urn:uuid:1");
    testing.assertEqual(xml.text($env.headers[1]), "urn:schemas-xmlsoap-org:ws:2005:04:discovery");
    testing.assertEqual(xml.text($env.headers[2]), PROBE_ACTION);
    def types as xml.Value init xml.get($env.body[0], "*:Types");
    testing.assertEqual(xml.namespace($env.body[0]), WSD_NS);
    testing.assertEqual(xml.text($types), "dn:NetworkVideoTransmitter");
    testing.assertEqual(xml.lookupPrefix($types, "dn"), NETWORK_NS);
    def dev as soap.Envelope init soap.parse(probeMessage("urn:uuid:2", "Device"));
    def t2 as xml.Value init xml.get($dev.body[0], "*:Types");
    testing.assertEqual(xml.text($t2), "tds:Device");
    testing.assertEqual(xml.lookupPrefix($t2, "tds"), NS_DEVICE);
}

func testParseMatches() {
    def sim as list of Discovered init parseMatches(
        SIM_PROBE_MATCHES,
        [SIM_PROBE_ID],
        "10.0.0.9:3702");
    testing.assertEqual(len($sim), 1);
    testing.assertEqual(
        $sim[0],
        Discovered{
            endpoint: "urn:uuid:7942f1d6-13d6-5a0f-aad3-40accdebcb0d",
            address: "http://172.17.0.3:8080/onvif/device_service",
            xaddrs: ["http://172.17.0.3:8080/onvif/device_service"],
            types: ["tdn:NetworkVideoTransmitter"],
            scopes: [
                "onvif://www.onvif.org/Profile/Streaming",
                "onvif://www.onvif.org/Profile/T",
                "onvif://www.onvif.org/hardware/SimCam",
                "onvif://www.onvif.org/name/OnvifSim"
            ],
            name: "OnvifSim",
            hardware: "SimCam",
            from: "10.0.0.9:3702"
        });
    testing.assertEqual(len(parseMatches(SIM_PROBE_MATCHES, ["urn:uuid:other"], "x")), 0);
    testing.assertEqual(len(parseMatches("<x/>", [SIM_PROBE_ID], "x")), 0);
    testing.assertEqual(
        len(parseMatches(
            strings.replace(SIM_PROBE_MATCHES, "/ProbeMatches<", "/Hello<"),
            [SIM_PROBE_ID],
            "x")),
        0);
    def ez as string init bodyOf(EZ_PROBE_MATCHES);
    def ezId as string init field($ez, "RelatesTo");
    def found as list of Discovered init parseMatches($ez, [$ezId], "x");
    testing.assertEqual(len($found), 1);
    testing.assertEqual($found[0].address, "http://192.0.2.13/onvif/device_service");
    testing.assertEqual($found[0].name, "REDACTED5");
    def dvc as string init bodyOf(DVC_PROBE_MATCHES);
    def two as list of Discovered init parseMatches($dvc, [field($dvc, "RelatesTo")], "x");
    testing.assertEqual(len($two[0].xaddrs), 2);
    testing.assertContains($two[0].xaddrs[1], "[fe80::");
}

func testScopeValues() {
    testing.assertEqual(
        scopeValue(["onvif://www.onvif.org/name/Front%20Gate"], "onvif://www.onvif.org/name/"),
        "Front Gate");
    testing.assertEqual(
        scopeValue(["onvif://www.onvif.org/Name/x%zz"], "onvif://www.onvif.org/name/"),
        "x%zz");
    testing.assertEqual(
        scopeValue(["onvif://www.onvif.org/name/"], "onvif://www.onvif.org/name/"),
        "");
    testing.assertEqual(words("  a \n b\tc "), ["a", "b", "c"]);
}

# Scopes are data: a percent-encoded UTF-8 name decodes to its letters, and
# a long scope is kept whole (both came back as ? and cut at 120).
func testScopesAreKeptWhole() {
    testing.assertEqual(
        scopeValue(
            ["onvif://www.onvif.org/name/Kamera%20G%C3%A4rten"],
            "onvif://www.onvif.org/name/"),
        "Kamera G\u00e4rten");
    testing.assertEqual(
        scopeValue(["onvif://www.onvif.org/name/a%1Bb%C2%9Bc"], "onvif://www.onvif.org/name/"),
        "a?b?c");
    def long as string init "onvif://www.onvif.org/location/" + strings.repeat("x", 150);
    def found as list of Discovered init parseMatches(
        strings.replace(SIM_PROBE_MATCHES, "onvif://www.onvif.org/Profile/T", $long),
        [SIM_PROBE_ID],
        "x");
    testing.assertEqual($found[0].scopes[1], $long);
}

func testDiscoverOverLoopback() {
    def sock as net.UDPSocket init net.listenUDP("127.0.0.1:0");
    def t as task of list of string init spawn {
        return serveProbes($sock);
    };
    def o as DiscoveryOptions init discoveryOptions();
    testing.assertEqual($o.target, DISCOVERY_ADDRESS);
    $o.target = net.address($sock);
    $o.timeoutMs = 800;
    def started as int init time.unixMillis(time.now());
    def found as list of Discovered init discoverWith($o);
    def took as int init time.unixMillis(time.now()) - $started;
    def probes as list of string init task.wait($t);
    net.close($sock);
    testing.assertEqual(len($found), 1);
    testing.assertEqual($found[0].name, "OnvifSim");
    testing.assertEqual($found[0].from, $o.target);
    testing.assertTrue($took >= 700 and $took < 3000);
    testing.assertContains($probes[0], "dn:NetworkVideoTransmitter");
    testing.assertContains($probes[1], "tds:Device");
    testing.assertTrue(field($probes[0], "MessageID") != field($probes[1], "MessageID"));
}

func testDiscoverWithNobodyThere() {
    def sock as net.UDPSocket init net.listenUDP("127.0.0.1:0");
    def target as string init net.address($sock);
    net.close($sock);
    def o as DiscoveryOptions init discoveryOptions();
    $o.target = $target;
    $o.timeoutMs = 200;
    $o.types = ["Device"];
    testing.assertEqual(len(discoverWith($o)), 0);
}

func testDiscoveryChecksItsOptions() {
    def o as DiscoveryOptions init discoveryOptions();
    def bad as list of DiscoveryOptions init [];
    $o.timeoutMs = 99;
    $bad[] = $o;
    $o = discoveryOptions();
    $o.timeoutMs = 30001;
    $bad[] = $o;
    $o = discoveryOptions();
    $o.target = "239.255.255.250";
    $bad[] = $o;
    $o = discoveryOptions();
    $o.types = [];
    $bad[] = $o;
    $o = discoveryOptions();
    $o.types = ["Printer"];
    $bad[] = $o;
    $o = discoveryOptions();
    $o.iface = "eth0;x";
    $bad[] = $o;
    for (def b in $bad) {
        try {
            discoverWith($b);
            missed("options");
        } catch (e) {
            testing.assertEqual($e.kind, ERROR_KIND);
        }
    }
    try {
        discover(50);
        missed("timeout");
    } catch (e) {
        testing.assertContains($e.message, "100 to 30000 ms");
    }
}
