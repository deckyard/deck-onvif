# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

# onvif - white-box tests for the core topic, and the fake camera the other
# overlays use. Spliced into onvif_test.j via include.

def const USER as string init "admin";
def const PASSWORD as string init "Secret123";

# the hosts the recorded replies name, which the fake replaces by its own
def const RECORDED_HOSTS as list of string init ["172.17.0.3:8080", "http://192.0.2.13/"];

/**
 * One request as the fake saw it.
 *
 * @field path {string} the path
 * @field op {string} the operation (the Body's first element), or the
 *   method for a request without a SOAP body
 * @field contentType {string} the Content-Type header
 * @field authorization {string} the Authorization header
 * @field body {string} the body
 */
def struct Seen {
    path as string,
    op as string,
    contentType as string,
    authorization as string,
    body as string
};

/**
 * A running fake camera.
 *
 * @field srv {httpd.Server} the server
 * @field base {string} its base URL, `http://127.0.0.1:PORT`
 * @field t {task of list of Seen} the task serving it
 */
def struct Fake {
    srv as httpd.Server,
    base as string,
    t as task of list of Seen
};

/**
 * Mark a call that should have thrown.
 *
 * @param what {string} what got through
 * @throws {Error} always, kind "missed"
 */
func missed(what as string) {
    throw Error{kind: "missed", message: $what};
}

/**
 * Start a fake camera. A request is answered by `PATH OPERATION` (or
 * `PATH GET` for a request without body): the first answer in the list the
 * first time, the next one the next time, the last one from then on. An
 * answer is the status, a newline, header lines `Name: value`, an empty line
 * and the body; a body `base64:...` is sent as those bytes, a status `SLEEP`
 * waits 3 s first. The hosts in RECORDED_HOSTS are replaced by the fake's
 * own. A request with no answer gets 404.
 *
 * @param answers {map of string to list of string} the answers
 * @return {Fake} the fake
 */
func startFake(answers as map of string to list of string) {
    def srv as httpd.Server init httpd.listen("127.0.0.1:0");
    def host as string init httpd.address($srv);
    def t as task of list of Seen init spawn {
        return serveFake($srv, $host, $answers);
    };
    return Fake{srv: $srv, base: "http://" + $host, t: $t};
}

/**
 * The operation a request body names.
 *
 * @param body {string} the body
 * @param method {string} the method
 * @return {string} the local name of the Body's first child, or the method
 */
func operationOf(body as string, method as string) {
    if ($body == "") {
        return $method;
    }
    try {
        def env as soap.Envelope init soap.parse($body);
        return xml.localName($env.body[0]);
    } catch (e) {
        return "?";
    }
    return "?";
}

/**
 * Serve requests until the server shuts down.
 *
 * @param srv {httpd.Server} the server
 * @param host {string} its host:port
 * @param answers {map of string to list of string} the answers
 * @return {list of Seen} the requests
 */
func serveFake(srv as httpd.Server, host as string, answers as map of string to list of string) {
    def seen as list of Seen init [];
    def used as map of string to int init {};
    while (true) {
        def req as httpd.Request;
        try {
            $req = httpd.accept($srv);
        } catch (e) {
            return $seen;
        }
        def body as string init convert.stringFromBytes("utf-8", httpd.body($req));
        def target as string init httpd.path($req);
        if (httpd.rawQuery($req) != "") {
            $target = $target + "?" + httpd.rawQuery($req);
        }
        def s as Seen init Seen{
            path: $target,
            op: operationOf($body, httpd.method($req)),
            contentType: httpd.header($req, "Content-Type"),
            authorization: httpd.header($req, "Authorization"),
            body: $body
        };
        $seen[] = $s;
        def key as string init $target + " " + $s.op;
        def spec as string init "404\nContent-Type: text/plain\n\nno answer for " + $key;
        if (maps.has($answers, $key)) {
            def n as int init 0;
            if (maps.has($used, $key)) {
                $n = $used[$key];
            }
            $used[$key] = $n + 1;
            def list2 as list of string init $answers[$key];
            if ($n >= len($list2)) {
                $n = len($list2) - 1;
            }
            $spec = $list2[$n];
        }
        $spec = strings.replace($spec, RECORDED_HOSTS[0], $host);
        $spec = strings.replace($spec, RECORDED_HOSTS[1], "http://" + $host + "/");
        def split as int init strings.indexOf($spec, "\n\n");
        def head as list of string init strings.split($spec[..$split], "\n");
        for (def h in $head[1..]) {
            def at as int init strings.indexOf($h, ": ");
            httpd.setHeader($req, $h[..$at], $h[$at + 2..]);
        }
        def rest as string init $spec[$split + 2..];
        def status as string init $head[0];
        if ($status == "SLEEP") {
            time.sleep(time.fromMilliseconds(3000));
            $status = "200";
        }
        if (strings.startsWith($rest, "base64:")) {
            httpd.respond($req, convert.toInt($status), encoding.fromText("base64", $rest[7..]));
        } else {
            httpd.respond($req, convert.toInt($status), $rest);
        }
    }
    return $seen;
}

/**
 * Stop a fake and return what it saw.
 *
 * @param f {Fake} the fake
 * @return {list of Seen} the requests
 */
func stopFake(f as Fake) {
    httpd.shutdown($f.srv);
    return task.wait($f.t);
}

/**
 * A device on a fake, not yet connected.
 *
 * @param f {Fake} the fake
 * @return {Device} the device
 */
func fakeDevice(f as Fake) {
    return device($f.base + "/onvif/device_service", USER, PASSWORD);
}

/**
 * The simulator's clock and services, and more answers.
 *
 * @param more {map of string to list of string} answers to add
 * @return {map of string to list of string} the answers
 */
func simAnswers(more as map of string to list of string) {
    def out as map of string to list of string init {
        "/onvif/device_service GetSystemDateAndTime": [SIM_TIME],
        "/onvif/device_service GetServices": [SIM_SERVICES]
    };
    for (def k in $more) {
        $out[$k] = $more[$k];
    }
    return $out;
}

/**
 * Start a fake simulator and connect to it.
 *
 * @param more {map of string to list of string} answers besides the clock
 *   and services
 * @return {Fake} the fake
 */
func simFake(more as map of string to list of string) {
    return startFake(simAnswers($more));
}

/**
 * A 200 answer with a SOAP 1.2 body.
 *
 * @param body {string} the envelope
 * @return {string} the answer
 */
func ok(body as string) {
    return "200\nContent-Type: application/soap+xml\n\n" + $body;
}

/**
 * The body of a fake answer.
 *
 * @param spec {string} the answer
 * @return {string} its body
 */
func bodyOf(spec as string) {
    return $spec[strings.indexOf($spec, "\n\n") + 2..];
}

/**
 * The text of the first element with a local name in a request body.
 *
 * @param body {string} the request
 * @param name {string} the local name
 * @return {string} its text, "" when missing
 */
func field(body as string, name as string) {
    def m as regex.Match init regex.find('<[A-Za-z0-9]+:' + $name + '[ >][^<]*', $body);
    if ($m.start == -1) {
        return "";
    }
    return strings.split($m.text, ">")[1];
}

func testPasswordDigestMatchesPublishedVectors() {
    # ONVIF Application Programmer's Guide 1.0, 6.1.1.3
    testing.assertEqual(
        passwordDigest(
            encoding.fromText("base64", "LKqI6G/AikKCQrN0zqZFlg=="),
            "2010-09-16T07:50:45Z",
            "userpassword"),
        "tuOSpGlFlIXsozq4HFNeeGeFLEI=");
    # computed with Python's hashlib, independently of this deck
    testing.assertEqual(
        passwordDigest(
            convert.bytesFromString("utf-8", "0123456789abcdef"),
            "2026-11-14T19:32:05Z",
            PASSWORD),
        "Auwox7Q9uQMEeyNqjM8gI6zJElE=");
}

func testSecurityHeaderShape() {
    def nonce as bytes init convert.bytesFromString("utf-8", "0123456789abcdef");
    def h as xml.Value init securityHeader("ad<min", PASSWORD, $nonce, "2026-11-14T19:32:05Z");
    def text as string init xml.encode($h);
    testing.assertEqual(xml.namespace($h), WSSE_NS);
    testing.assertEqual(xml.text(xml.get($h, "*:UsernameToken/*:Username")), "ad<min");
    def pw as xml.Value init xml.get($h, "*:UsernameToken/*:Password");
    testing.assertEqual(xml.attr($pw, "Type"), DIGEST_TYPE);
    testing.assertEqual(xml.text($pw), "Auwox7Q9uQMEeyNqjM8gI6zJElE=");
    testing.assertEqual(
        xml.text(xml.get($h, "*:UsernameToken/*:Nonce")),
        encoding.toText("base64", $nonce));
    def created as xml.Value init xml.get($h, "*:UsernameToken/*:Created");
    testing.assertEqual(xml.namespace($created), WSU_NS);
    testing.assertEqual(xml.text($created), "2026-11-14T19:32:05Z");
    testing.assertFalse(strings.contains($text, PASSWORD));
    testing.assertContains($text, "ad&lt;min");
}

func testCreatedFollowsTheOffset() {
    def d as Device init device("http://192.168.1.64/onvif/device_service", USER, PASSWORD);
    $d.offsetMs = -86400000;
    def created as string init createdNow($d);
    testing.assertTrue(regex.matches(
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$',
        $created));
    def gap as int init time.unixMillis(time.now()) - time.unixMillis(time.fromIso($created));
    testing.assertTrue($gap > 86398000 and $gap < 86402000);
}

func testDeviceChecksItsInput() {
    def d as Device init device("http://192.168.1.64/onvif/device_service", USER, PASSWORD);
    testing.assertEqual($d.services, {"device": "http://192.168.1.64/onvif/device_service"});
    testing.assertEqual($d.timeoutMs, DEFAULT_TIMEOUT_MS);
    testing.assertEqual($d.maxBytes, DEFAULT_MAX_BYTES);
    testing.assertEqual($d.maxMediaBytes, DEFAULT_MAX_MEDIA_BYTES);
    testing.assertFalse($d.plainHttp);
    testing.assertEqual(device("https://cam.example/onvif/device_service", "", "").user, "");
    for (def bad in [
        "ftp://192.168.1.64/onvif",
        "http://admin:pw@192.168.1.64/onvif",
        "http://192.168.1.64/onvif#x",
        "http:///onvif",
        "http://192.168.1.64:99999999/onvif",
        "http://192.168.1.64/on vif",
        "192.168.1.64",
        "http://192.168.1.64/onvif\n"
    ]) {
        try {
            device($bad, USER, PASSWORD);
            missed($bad);
        } catch (e) {
            testing.assertEqual($e.kind, ERROR_KIND);
            testing.assertEqual($e.status, 0);
            testing.assertFalse(strings.contains($e.message, "pw@"));
        }
    }
    try {
        device("http://192.168.1.64/onvif", "", PASSWORD);
        missed("a password without user");
    } catch (e) {
        testing.assertEqual($e.message, "onvif: a password needs a user name");
    }
    try {
        device("http://192.168.1.64/onvif", "ad\nmin", PASSWORD);
        missed("a control character");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
}

func testSettings() {
    def d as Device init device("http://192.168.1.64/onvif/device_service", USER, PASSWORD);
    testing.assertEqual(withTimeout($d, 2500).timeoutMs, 2500);
    testing.assertEqual(withMaxBytes($d, 65536).maxBytes, 65536);
    testing.assertEqual(withMaxMediaBytes($d, 65536).maxMediaBytes, 65536);
    testing.assertTrue(withPlainHttp($d).plainHttp);
    testing.assertEqual(withAuth($d, "digest").auth, "digest");
    testing.assertEqual(withAuth(withAuth($d, "wsse"), "").auth, "");
    testing.assertTrue(withInsecure($d).tls.skipVerify);
    def pem as bytes init convert.bytesFromString("utf-8", "-----BEGIN CERTIFICATE-----");
    def withCa as Device init withCaCert(withInsecure($d), $pem);
    testing.assertEqual($withCa.tls.caCert, $pem);
    testing.assertFalse($withCa.tls.skipVerify);
    def svc as Device init withService($d, "ptz", "http://192.168.1.64/onvif/PTZ");
    testing.assertEqual(serviceAddress($svc, "ptz"), "http://192.168.1.64/onvif/PTZ");
    def media as Device init withService(
        withService($d, "media", "http://192.168.1.64/m1"),
        "media2",
        "http://192.168.1.64/m2");
    testing.assertEqual($media.media, "media2");
    testing.assertEqual(withMedia($media, "media").media, "media");
    try {
        withTimeout($d, 99);
        missed("withTimeout");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        withTimeout($d, 300001);
        missed("withTimeout");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        withMaxBytes($d, 4095);
        missed("withMaxBytes");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        withMaxMediaBytes($d, 268435457);
        missed("withMaxMediaBytes");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        withAuth(device("http://192.168.1.64/onvif", "", ""), "digest");
        missed("withAuth without a user");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        withAuth($d, "basic");
        missed("withAuth basic");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        withService($d, "nvr", "http://192.168.1.64/x");
        missed("withService");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        withService($d, "ptz", "http://u:p@192.168.1.64/x");
        missed("withService");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        withMedia($d, "media");
        missed("withMedia");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        withMedia($media, "media3");
        missed("withMedia");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        serviceAddress($d, "ptz");
        missed("serviceAddress");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        serviceAddress($d, "camera");
        missed("serviceAddress");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
}

func testPlainHttpGoesOnlyToTheLocalNetwork() {
    for (def h in [
        "127.0.0.1",
        "10.1.2.3",
        "172.16.0.9",
        "192.168.1.64",
        "169.254.1.1",
        "[::1]",
        "[fd00::5]",
        "[fe80::1]"
    ]) {
        testing.assertTrue(isLocalHost($h));
    }
    for (def h in [
        "192.0.2.13",
        "8.8.8.8",
        "camera.lan",
        "localhost",
        "[2001:db8::1]",
        "172.32.0.1"
    ]) {
        testing.assertFalse(isLocalHost($h));
    }
    def d as Device init device("http://camera.lan/onvif/device_service", USER, PASSWORD);
    try {
        deviceInformation($d);
        missed("plain http to a name");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
        testing.assertContains($e.message, "use https or withPlainHttp");
    }
    checkReachable(withPlainHttp($d), "http://camera.lan/onvif/device_service", "x");
    checkReachable($d, "https://camera.lan/onvif/device_service", "x");
    checkReachable($d, "http://10.0.0.2/onvif/device_service", "x");
}

# A service on the host the caller used keeps its own port (and scheme):
# no NAT is in play. Another host moves onto the device's origin, and plain
# http on the device's host is not taken when the device is reached by
# https. All of them used to take the device's port.
func testRebaseKeepsAPortOnTheSameHost() {
    def d as Device init device("http://10.0.0.5:8080/onvif/device_service", USER, PASSWORD);
    testing.assertEqual(
        rebase($d, "http://10.0.0.5:80/onvif/Media", "x"),
        "http://10.0.0.5:80/onvif/Media");
    testing.assertEqual(
        rebase($d, "https://10.0.0.5/onvif/Events", "x"),
        "https://10.0.0.5/onvif/Events");
    testing.assertEqual(rebase($d, "http://10.0.0.5/onvif/PTZ", "x"), "http://10.0.0.5/onvif/PTZ");
    def n as Device init device("http://Cam.Lan:8000/onvif/device_service", USER, PASSWORD);
    testing.assertEqual(
        rebase($n, "http://cam.lan:80/onvif/Media", "x"),
        "http://cam.lan:80/onvif/Media");
    def t as Device init device("https://10.0.0.5:8443/onvif/device_service", USER, PASSWORD);
    testing.assertEqual(
        rebase($t, "http://10.0.0.5:80/onvif/Media", "x"),
        "https://10.0.0.5:8443/onvif/Media");
    testing.assertEqual(
        rebase($t, "https://10.0.0.5:443/onvif/Media", "x"),
        "https://10.0.0.5:443/onvif/Media");
}

# Once connect has settled the method, a 401 fails at once: one sign-in per
# call, even when the camera now offers Digest. A device without connect
# learns per call and never twice in a row without a Digest challenge.
func testTheAuthMethodIsLearnedOnce() {
    def challenge as string init "401\nWWW-Authenticate: " + SIM_CHALLENGE +
        "\nContent-Type: text/html\n\n<html>401</html>";
    def f as Fake init simFake({
        "/onvif/device_service GetDeviceInformation": [$challenge, $challenge, SIM_INFO]
    });
    def d as Device init connect(fakeDevice($f));
    testing.assertEqual($d.auth, "wsse");
    try {
        deviceInformation($d);
        missed("known wsse");
    } catch (e) {
        testing.assertEqual($e.status, 401);
    }
    # not known: the challenge is answered once
    testing.assertEqual(deviceInformation(fakeDevice($f)).model, "SimCam");
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(len($seen), 5);
    testing.assertEqual($seen[2].authorization, "");
    testing.assertEqual($seen[3].authorization, "");
    testing.assertContains($seen[4].authorization, "Digest username=\"admin\"");
    # without a user nothing is signed, so nothing is learned
    def g as Fake init simFake({});
    testing.assertEqual(connect(device($g.base + "/onvif/device_service", "", "")).auth, "");
    stopFake($g);
}

func testRebaseKeepsTheDeviceOrigin() {
    def d as Device init device("http://10.0.0.5:8080/onvif/device_service", USER, PASSWORD);
    testing.assertEqual(
        rebase($d, "http://192.168.1.64/onvif/Media", "x"),
        "http://10.0.0.5:8080/onvif/Media");
    testing.assertEqual(
        rebase($d, " http://192.0.2.13:80/onvif/Subscription?Idx=0 ", "x"),
        "http://10.0.0.5:8080/onvif/Subscription?Idx=0");
    testing.assertEqual(
        rebase($d, "http://192.0.2.13/onvif/Events/PullSubManager_2026-10-07%17:46:23_0", "x"),
        "http://10.0.0.5:8080/onvif/Events/PullSubManager_2026-10-07%17:46:23_0");
    testing.assertEqual(rebase($d, "https://192.0.2.13", "x"), "http://10.0.0.5:8080/");
    def s as Device init device("https://[fd00::5]/onvif/device_service", USER, PASSWORD);
    testing.assertEqual(
        rebase($s, "http://192.168.1.64:80/onvif/PTZ", "x"),
        "https://[fd00::5]/onvif/PTZ");
    try {
        rebase($d, "rtsp://192.168.1.64/x", "x");
        missed("rebase");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        rebase($d, "http://u:p@192.168.1.64/x", "x");
        missed("rebase");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
}

func testMessagesShowNoCredentials() {
    testing.assertEqual(
        shownUrl("http://admin:pw@10.0.0.1:81/snap.jpg?user=admin&pwd=pw"),
        "http://10.0.0.1:81/snap.jpg");
    testing.assertEqual(plain("a\u001b[31mb"), "a?[31mb");
    testing.assertEqual(len(plain(strings.repeat("x", 500))), SHOWN + 3);
}

func testCheckToken() {
    checkToken("Profile_0", "profile token");
    checkToken(strings.repeat("t", 64), "profile token");
    for (def bad in ["", strings.repeat("t", 65), "a\tb"]) {
        try {
            checkToken($bad, "profile token");
            missed($bad);
        } catch (e) {
            testing.assertEqual($e.kind, ERROR_KIND);
            testing.assertContains($e.message, "profile token is 1 to 64 characters");
        }
    }
}

# Every request but the clock carries a fresh UsernameToken whose digest
# checks out, with Created on the camera's clock; the password is never sent.
func testEveryRequestIsSigned() {
    def f as Fake init simFake({"/onvif/device_service GetDeviceInformation": [SIM_INFO]});
    def d as Device init connect(fakeDevice($f));
    deviceInformation($d);
    deviceInformation($d);
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(len($seen), 4);
    testing.assertEqual($seen[0].op, "GetSystemDateAndTime");
    testing.assertFalse(strings.contains($seen[0].body, "Security"));
    testing.assertEqual(
        $seen[0].contentType,
        "application/soap+xml; charset=utf-8; action=\"http://www.onvif.org/ver10/device/wsdl/GetSystemDateAndTime\"");
    def nonces as list of string init [];
    # the simulator's clock in SIM_TIME
    def camera as int init time.unixMillis(time.fromIso("2026-11-14T19:32:03Z"));
    for (def s in $seen[1..]) {
        testing.assertEqual(field($s.body, "Username"), USER);
        def nonce as string init field($s.body, "Nonce");
        def created as string init field($s.body, "Created");
        def digest as bytes init hash.compute(
            "sha1",
            binary.concat(
                encoding.fromText("base64", $nonce),
                convert.bytesFromString("utf-8", $created + PASSWORD)));
        testing.assertEqual(field($s.body, "Password"), encoding.toText("base64", $digest));
        testing.assertFalse(lists.contains($nonces, $nonce));
        $nonces[] = $nonce;
        def gap as int init time.unixMillis(time.fromIso($created)) - $camera;
        testing.assertTrue($gap >= -1000 and $gap < 10000);
        testing.assertFalse(strings.contains($s.body, PASSWORD));
        testing.assertEqual($s.authorization, "");
    }
    testing.assertEqual(len(encoding.fromText("base64", $nonces[0])), 16);
}

# A fault becomes an OnvifError with the HTTP status, the code and every
# subcode level.
func testFaultsBecomeOnvifErrors() {
    def f as Fake init simFake({
        "/onvif/media2_service GetStreamUri": [
            "500\nContent-Type: application/soap+xml\n\n" + bodyOf(SIM_NO_PROFILE)
        ],
        "/onvif/device_service GetDeviceInformation": [SIM_NOT_AUTHORIZED],
        "/onvif/device_service GetHostname": [SIM_NOT_SUPPORTED]
    });
    def d as Device init connect(fakeDevice($f));
    try {
        streamUri($d, "Profile_9");
        missed("no profile");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
        testing.assertEqual($e.status, 500);
        testing.assertEqual($e.code, "Sender");
        testing.assertEqual($e.subcode, "ter:InvalidArgVal");
        testing.assertEqual($e.subcodes, ["ter:InvalidArgVal", "ter:NoProfile"]);
        testing.assertEqual(
            $e.message,
            "onvif: GetStreamUri: fault ter:InvalidArgVal/ter:NoProfile: " + $e.reason);
    }
    try {
        deviceInformation($d);
        missed("not authorized");
    } catch (e) {
        testing.assertEqual($e.status, 400);
        testing.assertEqual($e.subcode, "ter:NotAuthorized");
        testing.assertEqual($e.reason, "Sender not Authorized");
        testing.assertFalse(strings.contains($e.message, PASSWORD));
    }
    try {
        call($d, "device", "GetHostname", xml.elementNS(NS_DEVICE, "tds:GetHostname"));
        missed("not supported");
    } catch (e) {
        testing.assertEqual($e.subcodes[0], "ter:ActionNotSupported");
        testing.assertEqual($e.code, "Receiver");
    }
    def seen as list of Seen init stopFake($f);
    # a 400 is not retried with HTTP Digest
    testing.assertEqual(len($seen), 5);
}

# Other vendors' failures: an HTML 401 (Hikvision), a 401 fault without
# subcode (gSOAP), a gSOAP fault in another namespace.
func testVendorFailures() {
    def f as Fake init startFake({
        "/onvif/device_service GetSystemDateAndTime": [EZ_UNAUTHORIZED],
        "/onvif/device_service GetDeviceInformation": [DVC_UNAUTHORIZED],
        "/onvif/device_service GetHostname": [EZ_UNKNOWN]
    });
    def d as Device init fakeDevice($f);
    try {
        deviceInformation($d);
        missed("401");
    } catch (e) {
        testing.assertEqual($e.status, 401);
        testing.assertEqual($e.code, "Sender");
        testing.assertEqual($e.subcode, "");
        testing.assertContains($e.message, "onvif: GetDeviceInformation: fault Sender: ");
    }
    try {
        exchange(
            $d,
            $d.address,
            "x",
            xml.elementNS(NS_DEVICE, "tds:GetSystemDateAndTime"),
            [],
            5000,
            false);
        missed("html 401");
    } catch (e) {
        testing.assertEqual($e.status, 401);
        testing.assertEqual($e.code, "");
        testing.assertEqual(
            $e.message,
            "onvif: GetSystemDateAndTime: HTTP 401 Unauthorized without a SOAP reply");
    }
    try {
        call($d, "device", "GetHostname", xml.elementNS(NS_DEVICE, "tds:GetHostname"));
        missed("unknown");
    } catch (e) {
        testing.assertEqual($e.status, 500);
        testing.assertEqual($e.code, "Receiver");
        testing.assertEqual($e.subcodes, ["ter:ActionNotSupported", "ter:InvalidOperation"]);
    }
    def seen as list of Seen init stopFake($f);
    # the 401 offered no Digest challenge, so it was not tried again
    testing.assertEqual(len($seen), 3);
    testing.assertEqual($seen[0].op, "GetDeviceInformation");
    testing.assertEqual($seen[1].op, "GetSystemDateAndTime");
}

# A camera that answers 401 with a Digest challenge gets HTTP Digest on top
# of WS-Security, answering that very challenge; connect remembers it.
func testHttpDigestWhenTheCameraAsks() {
    def challenge as string init "401\nWWW-Authenticate: " + SIM_CHALLENGE +
        "\nContent-Type: text/html\n\n<html>401</html>";
    def f as Fake init startFake({
        "/onvif/device_service GetSystemDateAndTime": [SIM_TIME],
        "/onvif/device_service GetServices": [$challenge, SIM_SERVICES],
        "/onvif/device_service GetDeviceInformation": [$challenge, SIM_INFO]
    });
    def d as Device init connect(fakeDevice($f));
    testing.assertEqual($d.auth, "digest");
    testing.assertEqual(deviceInformation($d).model, "SimCam");
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(len($seen), 5);
    testing.assertEqual($seen[1].authorization, "");
    testing.assertContains($seen[2].authorization, "Digest username=\"admin\", realm=\"OnvifSim\"");
    testing.assertContains($seen[2].body, "UsernameToken");
    testing.assertTrue(field($seen[1].body, "Nonce") != field($seen[2].body, "Nonce"));
    testing.assertEqual($seen[3].authorization, "");
    testing.assertContains($seen[4].authorization, "Digest username=\"admin\"");
    for (def s in $seen) {
        testing.assertFalse(strings.contains($s.authorization, PASSWORD));
    }
}

# Caps, deadlines and closed connections keep their generic kinds.
func testGenericKindsPassOn() {
    def f as Fake init simFake({
        "/onvif/media2_service GetProfiles": [
            ok(strings.repeat(" ", 5000) + bodyOf(SIM_PROFILES2))
        ],
        "/onvif/device_service GetDeviceInformation": [
            "SLEEP\nContent-Type: application/soap+xml\n\n" + bodyOf(SIM_INFO)
        ]
    });
    def d as Device init withMaxBytes(connect(fakeDevice($f)), 4096);
    try {
        profiles($d);
        missed("limit");
    } catch (e) {
        testing.assertEqual($e.kind, "limit");
        testing.assertContains($e.message, "onvif: GetProfiles: POST ");
    }
    try {
        deviceInformation(withTimeout($d, 500));
        missed("timeout");
    } catch (e) {
        testing.assertEqual($e.kind, "timeout");
        testing.assertContains($e.message, "onvif: GetDeviceInformation: ");
    }
    stopFake($f);
    def l as net.Listener init net.listen("127.0.0.1:0");
    def t as task of int init spawn {
        def conn as net.Conn init net.accept($l);
        net.readBytes($conn, 65536);
        net.writeBytes(
            $conn,
            convert.bytesFromString("utf-8", "HTTP/1.1 200 OK\r\nContent-Length: 500\r\n\r\n<x"));
        net.close($conn);
        return 0;
    };
    try {
        deviceInformation(device(
            "http://" + net.address($l) + "/onvif/device_service",
            USER,
            PASSWORD));
        missed("closed");
    } catch (e) {
        testing.assertEqual($e.kind, "closed");
    }
    task.wait($t);
    net.close($l);
}

func testCall() {
    def f as Fake init simFake({"/onvif/device_service GetHostname": [SIM_HOSTNAME]});
    def d as Device init connect(fakeDevice($f));
    def r as xml.Value init call(
        $d,
        "device",
        "GetHostname",
        xml.elementNS(NS_DEVICE, "tds:GetHostname"));
    testing.assertEqual(xml.localName($r), "GetHostnameResponse");
    testing.assertEqual(textAt($r, "*:HostnameInformation/*:FromDHCP"), "false");
    call($d, "device", NS_DEVICE + "/GetHostname", xml.elementNS(NS_DEVICE, "tds:GetHostname"));
    try {
        call($d, "device", "Get Hostname", xml.elementNS(NS_DEVICE, "tds:GetHostname"));
        missed("call");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        call($d, "device", "http://x/\"y", xml.elementNS(NS_DEVICE, "tds:GetHostname"));
        missed("call");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        call($d, "device", "GetHostname", xml.element("GetHostname"));
        missed("call");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        call($d, "recording", "GetRecordings", xml.elementNS(NS_DEVICE, "x:GetRecordings"));
        missed("call");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    def seen as list of Seen init stopFake($f);
    testing.assertEqual(len($seen), 4);
    testing.assertContains(
        $seen[3].contentType,
        "action=\"http://www.onvif.org/ver10/device/wsdl/GetHostname\"");
}

func testReplyReaders() {
    def a as Answer init Answer{
        body: xml.decode('<r><n>1.5e2</n><b>1</b></r>'),
        status: 200,
        digest: false
    };
    testing.assertEqual(floatOf("1.5e2", "n", $a), 150.0);
    testing.assertEqual(floatOf("-0.25", "n", $a), -0.25);
    testing.assertTrue(boolOf("1", "b", $a));
    testing.assertFalse(boolOf("false", "b", $a));
    for (def bad in ["INF", "NaN", "", "1,5", "0x10"]) {
        try {
            floatOf($bad, "n", $a);
            missed($bad);
        } catch (e) {
            testing.assertEqual($e.status, 200);
        }
    }
    try {
        floatOf("1e999", "n", $a);
        missed("floatOf");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        boolOf("yes", "b", $a);
        missed("boolOf");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    try {
        requiredText($a.body, "*:missing", $a);
        missed("requiredText");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
    testing.assertEqual(textAt($a.body, "*:missing"), "");
    try {
        checkRange(1.5, -1.0, 1.0, "x");
        missed("checkRange");
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
    }
}
