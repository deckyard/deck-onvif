# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.28.0

# onvif - core: the Device handle and its settings, URL policy, WS-Security,
# the clock offset, the SOAP exchange, errors and `call`. Spliced into
# onvif.j via include.

/** The `kind` of every error the deck throws, except caps and transport kinds. */
export def const ERROR_KIND as string init "onvif";

/** The Device service namespace (`tds`). */
export def const NS_DEVICE as string init "http://www.onvif.org/ver10/device/wsdl";

/** The Media service namespace (`trt`). */
export def const NS_MEDIA as string init "http://www.onvif.org/ver10/media/wsdl";

/** The Media2 service namespace (`tr2`). */
export def const NS_MEDIA2 as string init "http://www.onvif.org/ver20/media/wsdl";

/** The PTZ service namespace (`tptz`). */
export def const NS_PTZ as string init "http://www.onvif.org/ver20/ptz/wsdl";

/** The Imaging service namespace (`timg`). */
export def const NS_IMAGING as string init "http://www.onvif.org/ver20/imaging/wsdl";

/** The Events service namespace (`tev`). */
export def const NS_EVENTS as string init "http://www.onvif.org/ver10/events/wsdl";

/** The ONVIF schema namespace (`tt`), of the types inside messages. */
export def const NS_SCHEMA as string init "http://www.onvif.org/ver10/schema";

/** The ONVIF error namespace (`ter`), of the fault subcodes. */
export def const NS_ERROR as string init "http://www.onvif.org/ver10/error";

/**
 * The services the deck knows by name, and their namespaces. `connect`
 * finds their addresses; `call` and `serviceAddress` take the name.
 */
export def const SERVICES as map of string to string init {
    "device": NS_DEVICE,
    "media": NS_MEDIA,
    "media2": NS_MEDIA2,
    "ptz": NS_PTZ,
    "imaging": NS_IMAGING,
    "events": NS_EVENTS,
    "deviceio": "http://www.onvif.org/ver10/deviceIO/wsdl",
    "recording": "http://www.onvif.org/ver10/recording/wsdl",
    "search": "http://www.onvif.org/ver10/search/wsdl",
    "replay": "http://www.onvif.org/ver10/replay/wsdl",
    "analytics": "http://www.onvif.org/ver20/analytics/wsdl"
};

/** The default idle timeout of a request, in milliseconds. */
export def const DEFAULT_TIMEOUT_MS as int init 10000;

/** The default cap on a SOAP reply, in bytes (8 MiB). */
export def const DEFAULT_MAX_BYTES as int init 8388608;

/** The default cap on a snapshot, in bytes (16 MiB). */
export def const DEFAULT_MAX_MEDIA_BYTES as int init 16777216;

def const WSSE_NS as string init "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";
def const WSU_NS as string init "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd";
def const DIGEST_TYPE as string init "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest";
def const NONCE_TYPE as string init "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary";
def const WSA_NS as string init "http://www.w3.org/2005/08/addressing";

# printable characters only, at most this many, in an error message
def const SHOWN as int init 120;

# control characters in text read from a reply (XML 1.0 can carry DEL and C1)
def const CONTROL as string init '[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]';

# a ReferenceToken is xs:string of at most 64 characters (ONVIF schema)
def const MAX_TOKEN as int init 64;

/**
 * A camera or NVR: where its services are, how to sign in, and the clock
 * offset the WS-Security digest needs. Value-semantic: the `with*`
 * functions and `connect` return a changed copy. It holds the password, so
 * never print one.
 *
 * @field address {string} the device service URL
 * @field user {string} the user name; "" for no authentication
 * @field password {string} the password
 * @field offsetMs {int} the camera's clock minus this machine's, in
 *   milliseconds, added to each `Created`
 * @field clockSynced {bool} whether `offsetMs` was read from the camera
 * @field services {map of string to string} service name (`media`, `ptz`,
 *   ...) to its URL, from `connect`
 * @field media {string} the media service the media calls use, `media2` or
 *   `media`; "" before `connect`
 * @field auth {string} how signed SOAP calls sign in: `"wsse"` WS-Security
 *   alone, `"digest"` WS-Security plus HTTP Digest, `""` not known yet (each
 *   call then finds out on its own, see `withAuth`); `connect` settles it
 * @field plainHttp {bool} allow plain `http` to any host, not only private,
 *   link-local and loopback addresses
 * @field tls {http.TlsOptions} certificate checking for `https`
 * @field timeoutMs {int} the idle timeout of each request
 * @field maxBytes {int} the cap on a SOAP reply
 * @field maxMediaBytes {int} the cap on a snapshot
 * @field overrides {list of string} the services set by `withService`, which
 *   `connect` keeps
 */
export def struct Device {
    address as string,
    user as string,
    password as string,
    offsetMs as int,
    clockSynced as bool,
    services as map of string to string,
    media as string,
    auth as string,
    plainHttp as bool,
    tls as http.TlsOptions,
    timeoutMs as int,
    maxBytes as int,
    maxMediaBytes as int,
    overrides as list of string
};

/**
 * A request the camera refused or that failed. Every error of kind
 * `"onvif"` is one, so its fields are safe to read once the kind matches.
 *
 * @field kind {string} always `"onvif"` (`ERROR_KIND`)
 * @field message {string} `onvif: ` and what failed; for a fault
 *   `onvif: OPERATION: fault SUBCODES: REASON`
 * @field status {int} the HTTP status of the reply; 0 when there was none
 *   (a local check, a transport failure)
 * @field code {string} the SOAP fault code without prefix (`Sender`,
 *   `Receiver`, ...); "" when the reply was no fault
 * @field subcode {string} the first fault subcode, `ter:NAME` in the ONVIF
 *   error namespace (`ter:NotAuthorized`, `ter:InvalidArgVal`), else
 *   `{namespace}NAME` or the name as written; "" for none
 * @field subcodes {list of string} every subcode level, outermost first
 *   (`["ter:InvalidArgVal", "ter:NoProfile"]`)
 * @field reason {string} the fault reason, printable characters only, cut
 *   to 120 characters
 * @example
 *   try {
 *       onvif.gotoPreset($cam, $profile, "7");
 *   } catch (e) {
 *       if ($e.kind == "onvif" and lists.contains($e.subcodes, "ter:NoEntity")) {
 *           io.printf("no such preset\n");
 *       } else {
 *           throw $e;
 *       }
 *   }
 */
export def struct OnvifError {
    kind as string,
    message as string,
    status as int,
    code as string,
    subcode as string,
    subcodes as list of string,
    reason as string
};

/**
 * What an exchange returns: the result element, the HTTP status, and
 * whether HTTP Digest was needed.
 *
 * @field body {xml.Value} the reply's first Body child
 * @field status {int} the HTTP status
 * @field digest {bool} the call went out with HTTP Digest
 */
def struct Answer {
    body as xml.Value,
    status as int,
    digest as bool
};

/**
 * Throw a local error, without a status.
 *
 * @param message {string} what is wrong, without the prefix
 */
func fail(message as string) {
    failStatus($message, 0);
}

/**
 * Throw an error about a reply, with its HTTP status.
 *
 * @param message {string} what is wrong, without the prefix
 * @param status {int} the HTTP status; 0 for none
 */
func failStatus(message as string, status as int) {
    throw OnvifError{
        kind: ERROR_KIND,
        message: "onvif: " + $message,
        status: $status,
        code: "",
        subcode: "",
        subcodes: [],
        reason: ""
    };
}

/**
 * Text fit for an error message: printable ASCII only, cut to `SHOWN`
 * characters.
 *
 * @param text {string} the text
 * @return {string} the text
 */
func plain(text as string) {
    def cut as string init $text;
    if (len($cut) > SHOWN) {
        $cut = $cut[..SHOWN] + "...";
    }
    return regex.replace("[^ -~]", $cut, "?");
}

/**
 * Text read from a reply, to hand back as data: kept whole and in any
 * script, with control characters (C0 but tab, line feed and carriage
 * return; DEL; C1) replaced by `?`. `plain` is for messages.
 *
 * @param text {string} the text
 * @return {string} the text
 */
func clean(text as string) {
    # most text has none: the match is cheaper than the replace
    if (not regex.matches(CONTROL, $text)) {
        return $text;
    }
    return regex.replace(CONTROL, $text, "?");
}

/**
 * Text for an error message, quoted.
 *
 * @param text {string} the text
 * @return {string} the text, quoted and cut
 */
func shown(text as string) {
    return "\"" + plain($text) + "\"";
}

/**
 * A URL for an error message: scheme, host, port and path, never the user
 * information or the query, which may carry credentials.
 *
 * @param url {string} the URL
 * @return {string} what may be shown of it
 */
func shownUrl(url as string) {
    def u as uri.Uri;
    try {
        $u = uri.parse($url);
    } catch (e) {
        return "(a malformed URL)";
    }
    def hostPart as string init $u.host;
    if ($u.port != "") {
        $hostPart = $hostPart + ":" + $u.port;
    }
    return plain($u.scheme + "://" + $hostPart + $u.path);
}

/**
 * A device to talk to, without contacting it: `connect` reads its clock and
 * finds its services.
 *
 * @param address {string} the device service URL, as WS-Discovery's XAddrs
 *   or the vendor gives it (`http://192.168.1.64/onvif/device_service`)
 * @param user {string} the user name; "" for a camera without
 *   authentication
 * @param password {string} the password
 * @return {Device} the device: 10 s idle timeout, 8 MiB reply cap, 16 MiB
 *   snapshot cap, full certificate checking
 * @throws {OnvifError} kind `"onvif"` for a URL that is not `http(s)://host/path`
 *   or carries credentials, a query or a fragment, a user name with a control
 *   character, or a password without a user name
 */
export func device(address as string, user as string, password as string) {
    checkedUrl($address, "a device address");
    if (regex.matches('[\x00-\x1f\x7f]', $user)) {
        fail("a user name holds no control characters");
    }
    if ($user == "" and $password != "") {
        fail("a password needs a user name");
    }
    return Device{
        address: $address,
        user: $user,
        password: $password,
        offsetMs: 0,
        clockSynced: false,
        services: {"device": $address},
        media: "",
        auth: "",
        plainHttp: false,
        tls: http.TlsOptions{skipVerify: false, caCert: encoding.encode("utf-8", "")},
        timeoutMs: DEFAULT_TIMEOUT_MS,
        maxBytes: DEFAULT_MAX_BYTES,
        maxMediaBytes: DEFAULT_MAX_MEDIA_BYTES,
        overrides: []
    };
}

/**
 * Allow plain `http` to any host. Without it, plain `http` reaches only
 * private (RFC 1918, IPv6 ULA), link-local and loopback addresses written as
 * IP literals. The WS-Security digest never sends the password, but the rest
 * of each exchange (stream URLs, settings, events) is readable and can be
 * changed on the way.
 *
 * @param dev {Device} the device
 * @return {Device} the changed copy
 */
export func withPlainHttp(dev as Device) {
    $dev.plainHttp = true;
    return $dev;
}

/**
 * Trust a certificate (PEM) for `https`, such as the camera's own
 * self-signed one.
 *
 * @param dev {Device} the device
 * @param pem {bytes} the certificate
 * @return {Device} the changed copy
 */
export func withCaCert(dev as Device, pem as bytes) {
    $dev.tls = http.TlsOptions{skipVerify: false, caCert: $pem};
    return $dev;
}

/**
 * Accept any certificate for `https`. The connection stays encrypted but is
 * no longer authenticated; prefer `withCaCert`.
 *
 * @param dev {Device} the device
 * @return {Device} the changed copy
 */
export func withInsecure(dev as Device) {
    $dev.tls.skipVerify = true;
    return $dev;
}

/**
 * Set the idle timeout of each request: how long a read or write may wait.
 * A pull waits its own timeout on top.
 *
 * @param dev {Device} the device
 * @param ms {int} milliseconds, 100 to 300000
 * @return {Device} the changed copy
 * @throws {OnvifError} kind `"onvif"` outside that range
 */
export func withTimeout(dev as Device, ms as int) {
    if ($ms < 100 or $ms > 300000) {
        fail("a timeout is 100 to 300000 ms, got " + convert.toString($ms));
    }
    $dev.timeoutMs = $ms;
    return $dev;
}

/**
 * Set the cap on a SOAP reply. A decoded reply takes up to about 15 times
 * its size in memory.
 *
 * @param dev {Device} the device
 * @param n {int} bytes, 4096 to 268435456
 * @return {Device} the changed copy
 * @throws {OnvifError} kind `"onvif"` outside that range
 */
export func withMaxBytes(dev as Device, n as int) {
    if ($n < 4096 or $n > 268435456) {
        fail("a reply cap is 4096 to 268435456 bytes, got " + convert.toString($n));
    }
    $dev.maxBytes = $n;
    return $dev;
}

/**
 * Set the cap on a snapshot.
 *
 * @param dev {Device} the device
 * @param n {int} bytes, 4096 to 268435456
 * @return {Device} the changed copy
 * @throws {OnvifError} kind `"onvif"` outside that range
 */
export func withMaxMediaBytes(dev as Device, n as int) {
    if ($n < 4096 or $n > 268435456) {
        fail("a snapshot cap is 4096 to 268435456 bytes, got " + convert.toString($n));
    }
    $dev.maxMediaBytes = $n;
    return $dev;
}

/**
 * Fix how signed SOAP calls sign in, instead of letting each call find out.
 * `connect` sets it from the answer to its first signed call, so this is for
 * a device used without `connect`, or one whose method is known.
 *
 * - `"wsse"`: WS-Security alone; a `401` fails at once.
 * - `"digest"`: WS-Security plus HTTP Digest on every SOAP call (unsigned
 *   ones too), each answering the camera's challenge.
 * - `""`: not known. A signed call answered `401` with a Digest challenge is
 *   sent once more with HTTP Digest; one without a Digest challenge fails.
 *   Nothing is remembered between calls, so every such call costs up to two
 *   sign-ins.
 *
 * @param dev {Device} the device
 * @param method {string} `"wsse"`, `"digest"` or `""`
 * @return {Device} the changed copy
 * @throws {OnvifError} kind `"onvif"` for another method, or `"wsse"` /
 *   `"digest"` without a user name
 */
export func withAuth(dev as Device, method as string) {
    if ($method != "" and $method != "wsse" and $method != "digest") {
        fail("an auth method is wsse, digest or \"\", got " + shown($method));
    }
    if ($method != "" and $dev.user == "") {
        fail("the auth method " + $method + " needs a user name");
    }
    $dev.auth = $method;
    return $dev;
}

/**
 * Set a service's address by hand, for a device whose own answer is wrong.
 * The address must pass the same checks as the device's, and is used as
 * given. Set before or after `connect`: `connect` keeps it over what the
 * device reports. The `device` service's address is where the clock is read
 * too.
 *
 * @param dev {Device} the device
 * @param name {string} a name from `SERVICES`
 * @param address {string} the service URL
 * @return {Device} the changed copy
 * @throws {OnvifError} kind `"onvif"` for an unknown name or a bad URL
 */
export func withService(dev as Device, name as string, address as string) {
    knownService($name);
    checkedUrl($address, "a service address");
    $dev.services[$name] = $address;
    if (not lists.contains($dev.overrides, $name)) {
        $dev.overrides[] = $name;
    }
    if ($name == "media2" or ($name == "media" and $dev.media == "")) {
        $dev.media = $name;
    }
    return $dev;
}

/**
 * Choose the media service the media calls use, where a device has both.
 *
 * @param dev {Device} the device
 * @param name {string} `media2` or `media`
 * @return {Device} the changed copy
 * @throws {OnvifError} kind `"onvif"` for another name or a service the
 *   device does not have
 */
export func withMedia(dev as Device, name as string) {
    if ($name != "media" and $name != "media2") {
        fail("the media service is media or media2, got " + shown($name));
    }
    if (not maps.has($dev.services, $name)) {
        fail("the device has no " + $name + " service");
    }
    $dev.media = $name;
    return $dev;
}

/**
 * The address of one of the device's services.
 *
 * @param dev {Device} the device
 * @param name {string} a name from `SERVICES`
 * @return {string} its URL
 * @throws {OnvifError} kind `"onvif"` for an unknown name or a service the
 *   device does not have (or `connect` has not found yet)
 */
export func serviceAddress(dev as Device, name as string) {
    knownService($name);
    if (not maps.has($dev.services, $name)) {
        fail("the device has no " + $name + " service");
    }
    return $dev.services[$name];
}

/**
 * Refuse a service name the deck does not know.
 *
 * @param name {string} the name
 */
func knownService(name as string) {
    if (not maps.has(SERVICES, $name)) {
        fail("unknown service " + shown($name) + "; one of " +
            strings.join(maps.keys(SERVICES), ", "));
    }
}

/**
 * Check a URL's form: `http(s)://host[:port]/path[?query]`, printable ASCII,
 * no user information or fragment.
 *
 * @param url {string} the URL
 * @param what {string} what it is, for the message
 * @return {uri.Uri} its parts
 */
func checkedUrl(url as string, what as string) {
    if (not regex.matches('^https?://[^/?#@\s]+(/[!-~]*)?$', $url) or strings.contains($url, "#")) {
        fail($what + " is an http(s)://host/path URL without credentials or fragment, got " +
            shownUrl($url));
    }
    def u as uri.Uri;
    try {
        $u = uri.parse($url);
    } catch (e) {
        fail($what + " is malformed: " + shownUrl($url));
    }
    if ($u.host == "" or $u.user != "" or
        ($u.port != "" and not regex.matches('^[0-9]{1,5}$', $u.port))) {
        fail($what + " is malformed: " + shownUrl($url));
    }
    return $u;
}

/**
 * Whether a host is an IP literal this deck reaches over plain `http`
 * without `withPlainHttp`: private, link-local or loopback.
 *
 * @param host {string} the host as in a URL (`[::1]` for IPv6)
 * @return {bool} whether it is on the local network
 */
func isLocalHost(host as string) {
    def h as string init $host;
    if (strings.startsWith($h, "[") and strings.endsWith($h, "]")) {
        $h = $h[1..len($h) - 1];
    }
    def a as ipnet.Address;
    try {
        $a = ipnet.parseAddress($h);
    } catch (e) {
        return false;
    }
    return ipnet.isPrivate($a) or ipnet.isLinkLocal($a) or ipnet.isLoopback($a);
}

/**
 * Check a URL the deck is about to send to: its form, and plain `http`
 * only to the local network unless `withPlainHttp`.
 *
 * @param dev {Device} the device
 * @param url {string} the URL
 * @param what {string} what it is, for the message
 */
func checkReachable(dev as Device, url as string, what as string) {
    def u as uri.Uri init checkedUrl($url, $what);
    if ($u.scheme == "http" and not $dev.plainHttp and not isLocalHost($u.host)) {
        fail($what + " " + shownUrl($url) +
            " is plain http to a host that is not a private, link-local or loopback address; " +
            "use https or withPlainHttp");
    }
}

/**
 * Place a URL the camera gave. When it names the host the caller reached the
 * device by, it is the camera's real endpoint and is kept, port included.
 * When it names another host (an inner address behind NAT or a proxy), it
 * moves onto the device's scheme, host and port. Either way the path and
 * query stay as given, and credentials go only to the host the caller
 * named. A camera reached over `https` that names its own host over plain
 * `http` is moved too, so TLS is never dropped.
 *
 * @param dev {Device} the device
 * @param url {string} the URL from the camera
 * @param what {string} what it is, for the message
 * @return {string} the URL to send to
 */
func rebase(dev as Device, url as string, what as string) {
    def given as uri.Uri init checkedUrl(strings.trim($url), $what);
    def home as uri.Uri init uri.parse($dev.address);
    def origin as uri.Uri init $home;
    if (strings.lower($given.host) == strings.lower($home.host) and
        not ($home.scheme == "https" and $given.scheme == "http")) {
        $origin = $given;
    }
    def out as string init $origin.scheme + "://" + $origin.host;
    if ($origin.port != "") {
        $out = $out + ":" + $origin.port;
    }
    def path as string init $given.path;
    if ($path == "") {
        $path = "/";
    }
    $out = $out + $path;
    if ($given.query != "") {
        $out = $out + "?" + $given.query;
    }
    return $out;
}

/**
 * A URL cut into scheme with `://`, user information, host, port and the
 * rest (path, query, fragment), each as written.
 *
 * @field scheme {string} e.g. `rtsp://`
 * @field userInfo {string} `user:password`, without `@`; "" for none
 * @field host {string} the host, an IPv6 literal with its brackets
 * @field port {string} the port, without `:`; "" for none
 * @field rest {string} everything after the authority
 */
def struct UrlParts {
    scheme as string,
    userInfo as string,
    host as string,
    port as string,
    rest as string
};

/**
 * Cut an absolute URL at its authority, keeping every part as written.
 *
 * @param url {string} the URL
 * @param what {string} what it is, for the message
 * @return {UrlParts} its parts
 */
func urlParts(url as string, what as string) {
    def m as regex.Match init regex.find('^([A-Za-z][A-Za-z0-9+.-]*://)([^/?#]*)(.*)$', $url);
    if ($m.start == -1) {
        fail($what + " is not an absolute URL: " + shownUrl($url));
    }
    def out as UrlParts init UrlParts{
        scheme: $m.groups[0],
        userInfo: "",
        host: $m.groups[1],
        port: "",
        rest: $m.groups[2]
    };
    def at as int init strings.lastIndexOf($out.host, "@");
    if ($at >= 0) {
        $out.userInfo = $out.host[..$at];
        $out.host = $out.host[$at + 1..];
    }
    def colon as int init strings.lastIndexOf($out.host, ":");
    if ($colon >= 0 and $colon > strings.lastIndexOf($out.host, "]")) {
        $out.port = $out.host[$colon + 1..];
        $out.host = $out.host[..$colon];
    }
    return $out;
}

/**
 * A URL put back together from its parts.
 *
 * @param p {UrlParts} the parts
 * @return {string} the URL
 */
func joinUrl(p as UrlParts) {
    def out as string init $p.scheme;
    if ($p.userInfo != "") {
        $out = $out + $p.userInfo + "@";
    }
    $out = $out + $p.host;
    if ($p.port != "") {
        $out = $out + ":" + $p.port;
    }
    return $out + $p.rest;
}

/**
 * A URL without its user information (`user:password@`), which is never
 * used, sent or shown.
 *
 * @param url {string} the URL
 * @param what {string} what it is, for the message
 * @return {string} the URL without it
 */
func withoutUserInfo(url as string, what as string) {
    def p as UrlParts init urlParts(strings.trim($url), $what);
    $p.userInfo = "";
    return joinUrl($p);
}

/**
 * A URL on the device's host, every other part kept as written (scheme,
 * user information, port, path, query).
 *
 * @param dev {Device} the device
 * @param url {string} the URL
 * @param what {string} what it is, for the message
 * @return {string} the URL on the device's host
 */
func onDeviceHost(dev as Device, url as string, what as string) {
    def p as UrlParts init urlParts($url, $what);
    $p.host = uri.parse($dev.address).host;
    return joinUrl($p);
}

/**
 * The WS-Security `PasswordDigest` of a password:
 * `base64(sha1(nonce + created + password))`.
 *
 * @param nonce {bytes} the nonce, as sent base64-encoded in `Nonce`
 * @param created {string} the `Created` time as sent
 * @param password {string} the password
 * @return {string} the digest, base64
 * @example
 *   # the ONVIF Application Programmer's Guide's example
 *   onvif.passwordDigest(encoding.fromText("base64", "LKqI6G/AikKCQrN0zqZFlg=="),
 *       "2010-09-16T07:50:45Z", "userpassword");   # "tuOSpGlFlIXsozq4HFNeeGeFLEI="
 */
export func passwordDigest(nonce as bytes, created as string, password as string) {
    def data as bytes init binary.concat($nonce, encoding.encode("utf-8", $created + $password));
    return encoding.toText("base64", hash.compute("sha1", $data));
}

/**
 * The time to write in `Created`: this machine's clock plus the camera's
 * offset, in UTC to the second.
 *
 * @param dev {Device} the device
 * @return {string} `YYYY-MM-DDTHH:MM:SSZ`
 */
func createdNow(dev as Device) {
    def ms as int init time.unixMilliseconds(time.now()) + $dev.offsetMs;
    return time.format(time.fromUnixMilliseconds($ms), "%Y-%m-%dT%H:%M:%SZ");
}

/**
 * A WS-Security header block with a `UsernameToken` and its
 * `PasswordDigest`.
 *
 * @param user {string} the user name
 * @param password {string} the password
 * @param nonce {bytes} a fresh nonce
 * @param created {string} the `Created` time
 * @return {xml.Value} the `wsse:Security` element
 */
func securityHeader(user as string, password as string, nonce as bytes, created as string) {
    def pw as xml.Value init xml.setText(
        xml.setAttr(xml.elementNS(WSSE_NS, "wsse:Password"), "Type", DIGEST_TYPE),
        passwordDigest($nonce, $created, $password));
    def n as xml.Value init xml.setText(
        xml.setAttr(xml.elementNS(WSSE_NS, "wsse:Nonce"), "EncodingType", NONCE_TYPE),
        encoding.toText("base64", $nonce));
    def token as xml.Value init xml.elementNS(WSSE_NS, "wsse:UsernameToken");
    $token = xml.append($token, textElement(WSSE_NS, "wsse:Username", $user));
    $token = xml.append($token, $pw);
    $token = xml.append($token, $n);
    $token = xml.append($token, textElement(WSU_NS, "wsu:Created", $created));
    # No mustUnderstand on purpose: a camera that signs in by HTTP Digest
    # alone must be free to ignore this block. With mustUnderstand="1" a
    # device without WS-Security answers a MustUnderstand fault instead of
    # the Digest challenge the fallback in `exchange` waits for.
    return xml.append(xml.elementNS(WSSE_NS, "wsse:Security"), $token);
}

/**
 * An element holding text.
 *
 * @param ns {string} its namespace
 * @param qname {string} its prefixed name
 * @param text {string} the text
 * @return {xml.Value} the element
 */
func textElement(ns as string, qname as string, text as string) {
    return xml.setText(xml.elementNS($ns, $qname), $text);
}

/**
 * One HTTP exchange of a SOAP 1.2 request, read as `soap.send` reads it,
 * with the `401` challenge kept (`soap.send` drops the headers).
 *
 * @field status {int} the HTTP status; 0 when there was no answer
 * @field envelope {soap.Envelope} the reply's envelope; an empty Body when
 *   there was none
 * @field isFault {bool} whether the reply is a fault
 * @field fault {soap.Fault} the fault, when it is one
 * @field failed {string} what went wrong without a usable reply; "" for none
 * @field challenge {string} the `WWW-Authenticate` value of a `401`; "" for none
 */
def struct Posted {
    status as int,
    envelope as soap.Envelope,
    isFault as bool,
    fault as soap.Fault,
    failed as string,
    challenge as string
};

/**
 * POST a SOAP 1.2 envelope and read the reply. HTTP failures, malformed and
 * unexpected replies come back in `failed`; caps, deadlines and closed
 * connections throw their generic kinds, a transport failure
 * (`net.NetError`) and a cancelled task go on as they are.
 *
 * @param dev {Device} the device, for its TLS and reply cap
 * @param url {string} the service URL
 * @param action {string} the SOAP action URI
 * @param request {string} the envelope
 * @param timeoutMs {int} the idle timeout
 * @param mode {string} `"digest"` to answer HTTP Digest challenges,
 *   `"authorization"` to send `authorization` as it is, else ""
 * @param authorization {string} the `Authorization` value for that mode
 * @param what {string} the operation, for the message
 * @return {Posted} the reply
 */
func post(
    dev as Device,
    url as string,
    action as string,
    request as string,
    timeoutMs as int,
    mode as string,
    authorization as string,
    what as string) {
    def headers as map of string to string init {"Content-Type": soap.contentType("1.2", $action)};
    def o as http.Options;
    $o.tls = $dev.tls;
    $o.timeoutMs = $timeoutMs;
    $o.maxBytes = $dev.maxBytes;
    def out as Posted init Posted{
        status: 0,
        envelope: soap.Envelope{version: "1.2", headers: [], body: []},
        isFault: false,
        fault: soap.Fault{code: "", subcode: "", reason: "", actor: "", detail: ""},
        failed: "",
        challenge: ""
    };
    def r as http.Response;
    try {
        if ($mode == "digest") {
            $r = http.sendDigest("POST", $url, $headers, $request, $o, $dev.user, $dev.password);
        } else {
            if ($mode == "authorization") {
                $headers["Authorization"] = $authorization;
            }
            $r = http.send("POST", $url, $headers, $request, $o);
        }
    } catch (e) {
        if ($e.kind == "cancelled") {
            throw $e;
        }
        if ($e.kind == "net") {
            throw netPassedOn($e, $url);
        }
        # neither the query nor the user information: they may carry a key
        def why as string init "POST " + shownUrl($url) + ": " +
            plain(strings.replace($e.message, $url, shownUrl($url)));
        if ($e.kind == "limit" or $e.kind == "timeout" or $e.kind == "closed") {
            throw Error{kind: $e.kind, message: "onvif: " + $what + ": " + $why};
        }
        $out.failed = $why;
        return $out;
    }
    $out.status = $r.status;
    if ($r.status == 401 and maps.has($r.headers, "www-authenticate")) {
        $out.challenge = $r.headers["www-authenticate"];
    }
    def ok as bool init $r.status >= 200 and $r.status < 300;
    def statusLine as string init "HTTP " + convert.toString($r.status) + " " + plain($r.statusText);
    if (strings.trim($r.body) == "") {
        if (not $ok) {
            $out.failed = $statusLine;
        }
        return $out;
    }
    try {
        $out.envelope = soap.parse($r.body);
    } catch (e) {
        if (not $ok) {
            $out.failed = $statusLine + " without a SOAP reply";
            return $out;
        }
        # a decoding cap is "limit": it goes on as it is
        if ($e.kind != soap.ERROR_KIND) {
            throw Error{kind: $e.kind, message: "onvif: " + $what + ": " + $e.message};
        }
        $out.failed = unprefixed($e.message);
        return $out;
    }
    if (soap.isFault($out.envelope)) {
        try {
            $out.fault = soap.parseFault($out.envelope);
        } catch (e) {
            $out.failed = unprefixed($e.message);
            return $out;
        }
        $out.isFault = true;
        return $out;
    }
    if ($out.envelope.version != "1.2") {
        $out.failed = "a SOAP 1.2 call got a SOAP " + $out.envelope.version + " reply";
    } elseif (not $ok) {
        $out.failed = $statusLine + " without a fault";
    }
    return $out;
}

/**
 * A transport failure to pass on: the `net.NetError` as it is, its fields
 * intact, unless its message names the URL, whose query may carry a key;
 * then the same error with the URL shown as {@link shownUrl} shows it.
 *
 * @param e {net.NetError} the error, kind "net"
 * @param url {string} the URL the request went to
 * @return {net.NetError} the error to throw
 */
func netPassedOn(e as net.NetError, url as string) {
    if (not strings.contains($e.message, $url)) {
        return $e;
    }
    def out as net.NetError init $e;
    $out.message = strings.replace($e.message, $url, shownUrl($url));
    return $out;
}

/**
 * A soap message without its `soap: ` prefix.
 *
 * @param message {string} the message
 * @return {string} the rest
 */
func unprefixed(message as string) {
    if (strings.startsWith($message, "soap: ")) {
        return $message[6..];
    }
    return $message;
}

/**
 * Whether a `WWW-Authenticate` value offers HTTP Digest.
 *
 * @param challenge {string} the value; several challenges may share it
 * @return {bool} whether one is Digest
 */
func isDigestChallenge(challenge as string) {
    return regex.matches('(^|[\s,])digest\s', strings.lower($challenge));
}

/**
 * A fault subcode written as `ter:NAME` in the ONVIF error namespace,
 * `{namespace}NAME` in another, or as written when its prefix is unbound.
 *
 * @param node {xml.Value} the `Value` element holding the QName
 * @return {string} the subcode
 */
func qnameText(node as xml.Value) {
    def text as string init strings.trim(xml.text($node));
    def at as int init strings.indexOf($text, ":");
    def prefix as string init "";
    def local as string init $text;
    if ($at >= 0) {
        $prefix = $text[..$at];
        $local = $text[$at + 1..];
    }
    def ns as string init "";
    try {
        $ns = xml.lookupPrefix($node, $prefix);
    } catch (e) {
        return plain($text);
    }
    if ($ns == NS_ERROR) {
        return "ter:" + plain($local);
    }
    if ($ns == "") {
        return plain($local);
    }
    return plain('{' + $ns + '}' + $local);
}

/**
 * The subcodes of a SOAP 1.2 fault, outermost first. A SOAP 1.1 fault has
 * none, but its `faultcode` may itself be an ONVIF code (`ter:...`).
 *
 * @param env {soap.Envelope} the fault envelope
 * @return {list of string} the subcodes
 */
func subcodesOf(env as soap.Envelope) {
    def out as list of string init [];
    if (len($env.body) == 0) {
        return $out;
    }
    def f as xml.Value init $env.body[0];
    if ($env.version == "1.1") {
        if (xml.has($f, "faultcode")) {
            def code as string init qnameText(xml.get($f, "faultcode"));
            if (strings.startsWith($code, "ter:")) {
                $out[] = $code;
            }
        }
        return $out;
    }
    if (not xml.has($f, "*:Code")) {
        return $out;
    }
    def at as xml.Value init xml.get($f, "*:Code");
    # a fault nests a handful of levels at most; stop at 8
    while (xml.has($at, "*:Subcode") and len($out) < 8) {
        $at = xml.get($at, "*:Subcode");
        if (not xml.has($at, "*:Value")) {
            return $out;
        }
        $out[] = qnameText(xml.get($at, "*:Value"));
    }
    return $out;
}

/**
 * Throw the `OnvifError` of a fault reply.
 *
 * @param r {Posted} the fault reply
 * @param what {string} the operation, for the message
 */
func failFault(r as Posted, what as string) {
    def subs as list of string init subcodesOf($r.envelope);
    def first as string init "";
    if (len($subs) > 0) {
        $first = $subs[0];
    }
    def named as string init plain($r.fault.code);
    if (len($subs) > 0) {
        $named = strings.join($subs, "/");
    }
    def reason as string init plain(strings.trim($r.fault.reason));
    throw OnvifError{
        kind: ERROR_KIND,
        message: "onvif: " + $what + ": fault " + $named + ": " + $reason,
        status: $r.status,
        code: plain($r.fault.code),
        subcode: $first,
        subcodes: $subs,
        reason: $reason
    };
}

/**
 * Send one request and return the result element. How a signed request
 * signs in follows `dev.auth` (see `withAuth`): when it is not known, a
 * `401` with a Digest challenge is answered once with HTTP Digest, and a
 * `401` without one fails at once. Faults, HTTP failures and malformed
 * replies throw `OnvifError`; caps, deadlines and closed connections keep
 * their generic kinds.
 *
 * @param dev {Device} the device
 * @param url {string} the service URL
 * @param action {string} the SOAP action URI
 * @param body {xml.Value} the operation element
 * @param headers {list of xml.Value} more header blocks
 * @param timeoutMs {int} the idle timeout
 * @param auth {bool} whether to sign the request
 * @return {Answer} the result element, the status, and whether HTTP Digest was used
 */
func exchange(
    dev as Device,
    url as string,
    action as string,
    body as xml.Value,
    headers as list of xml.Value,
    timeoutMs as int,
    auth as bool) {
    def what as string init plain(xml.localName($body));
    checkReachable($dev, $url, "the " + $what + " address");
    def signed as bool init $auth and $dev.user != "";
    def mode as string init "";
    if ($dev.auth == "digest" and $dev.user != "") {
        $mode = "digest";
    }
    def authorization as string init "";
    def answered as bool init false;
    while (true) {
        # a fresh nonce and Created for every request, the retry too
        def blocks as list of xml.Value init [];
        if ($signed) {
            $blocks[] = securityHeader(
                $dev.user,
                $dev.password,
                crypto.randBytes(16),
                createdNow($dev));
        }
        for (def h in $headers) {
            $blocks[] = $h;
        }
        def request as string init soap.envelope("1.2", $blocks, [$body]);
        if ($answered) {
            try {
                $authorization = http.digestAuthorization(
                    $authorization,
                    "POST",
                    $url,
                    $dev.user,
                    $dev.password,
                    $request);
            } catch (e) {
                failStatus(
                    $what + ": cannot answer the Digest challenge: " + plain($e.message),
                    401);
            }
            $mode = "authorization";
        }
        def p as Posted init post(
            $dev,
            $url,
            $action,
            $request,
            $timeoutMs,
            $mode,
            $authorization,
            $what);
        # a camera that wants HTTP Digest answers 401 with a Digest challenge,
        # with or without a fault; answer it once, only while the method is
        # not known, and never when the 401 offers no Digest
        if ($p.status == 401 and $signed and $dev.auth == "" and not $answered and
            isDigestChallenge($p.challenge)) {
            $answered = true;
            $authorization = $p.challenge;
            continue;
        }
        if ($p.failed != "") {
            failStatus($what + ": " + $p.failed, $p.status);
        }
        if ($p.isFault) {
            failFault($p, $what);
        }
        if (len($p.envelope.body) == 0) {
            failStatus($what + ": the reply Body is empty", $p.status);
        }
        return Answer{body: $p.envelope.body[0], status: $p.status, digest: $mode != ""};
    }
    return Answer{body: $body, status: 0, digest: false};
}

/**
 * Send a request to a named service and return the result element.
 *
 * @param dev {Device} the device
 * @param service {string} a name from `SERVICES`
 * @param operation {string} the operation's local name, for the action
 * @param body {xml.Value} the operation element
 * @return {Answer} the answer
 */
func request(dev as Device, service as string, operation as string, body as xml.Value) {
    def url as string init serviceAddress($dev, $service);
    return exchange(
        $dev,
        $url,
        SERVICES[$service] + "/" + $operation,
        $body,
        [],
        $dev.timeoutMs,
        true);
}

/**
 * Call any operation of a service and return its result element: the
 * operations this deck has no function for. The request is signed like
 * every other.
 *
 * @param dev {Device} the device
 * @param service {string} a name from `SERVICES` (`device`, `media`,
 *   `ptz`, ...)
 * @param action {string} the SOAP action URI, or the operation's name,
 *   which is appended to the service namespace
 *   (`GetHostname` -> `http://www.onvif.org/ver10/device/wsdl/GetHostname`)
 * @param body {xml.Value} the operation element, in the service's namespace
 * @return {xml.Value} the reply's first Body child (`GetHostnameResponse`)
 * @throws {OnvifError} kind `"onvif"` for a fault, an HTTP failure, a
 *   malformed reply, an unknown or missing service, or a bad action
 * @throws {Error} kind `"limit"` for a reply over the cap, `"timeout"` and
 *   `"closed"` from the transport
 * @throws {net.NetError} kind `"net"` when the camera cannot be reached
 * @example
 *   def op as xml.Value init xml.elementNS(onvif.NS_DEVICE, "tds:GetHostname");
 *   def r as xml.Value init onvif.call($cam, "device", "GetHostname", $op);
 *   io.printf("%s\n", xml.text(xml.get(xml.get($r, "*:HostnameInformation"), "*:Name")));
 */
export func call(dev as Device, service as string, action as string, body as xml.Value) {
    def url as string init serviceAddress($dev, $service);
    def uriAction as string init $action;
    if (regex.matches('^[A-Za-z][A-Za-z0-9]{0,127}$', $action)) {
        $uriAction = SERVICES[$service] + "/" + $action;
    } elseif (not regex.matches('^(https?|urn):[!-~]+$', $action) or
        strings.contains($action, "\"") or
        strings.contains($action, "\\")) {
        fail("an action is an operation name or an action URI, got " + shown($action));
    }
    if (xml.typeOf($body) != "element" or xml.namespace($body) == "") {
        fail("the body of a call is an element in the service's namespace");
    }
    return exchange($dev, $url, $uriAction, $body, [], $dev.timeoutMs, true).body;
}

/**
 * Check a token (a profile, preset, video source or configuration token):
 * 1 to 64 characters, none of them a control character.
 *
 * @param token {string} the token
 * @param what {string} what it is, for the message
 */
func checkToken(token as string, what as string) {
    if ($token == "" or len($token) > MAX_TOKEN or regex.matches('[\x00-\x1f\x7f]', $token)) {
        fail("a " + $what + " is 1 to 64 characters without control characters, got " +
            shown($token));
    }
}

/**
 * The trimmed text at a path of local names, or "" when it is missing.
 *
 * @param node {xml.Value} where to start
 * @param path {string} the path, of local-name steps (`*:Name`)
 * @return {string} the text
 */
func textAt(node as xml.Value, path as string) {
    if (not xml.has($node, $path)) {
        return "";
    }
    return strings.trim(xml.text(xml.get($node, $path)));
}

/**
 * The trimmed text at a path, which the reply must have.
 *
 * @param node {xml.Value} where to start
 * @param path {string} the path
 * @param a {Answer} the answer, for its status
 * @return {string} the text
 */
func requiredText(node as xml.Value, path as string, a as Answer) {
    if (not xml.has($node, $path)) {
        failStatus(
            plain(xml.localName($a.body)) + ": the reply has no " + regex.replace('\*:', $path, ""),
            $a.status);
    }
    return strings.trim(xml.text(xml.get($node, $path)));
}

/**
 * An attribute's value, or "" when it is missing.
 *
 * @param node {xml.Value} the element
 * @param name {string} the unprefixed attribute name
 * @return {string} the value
 */
func attrOf(node as xml.Value, name as string) {
    if (not xml.hasAttrNS($node, "", $name)) {
        return "";
    }
    return strings.trim(xml.attrNS($node, "", $name));
}

/**
 * A number from a reply (`xs:float`, `xs:int`), or an error.
 *
 * @param text {string} the text
 * @param what {string} the field, for the message
 * @param a {Answer} the answer, for its status
 * @return {float} the number
 */
func floatOf(text as string, what as string, a as Answer) {
    if (not regex.matches('^[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)([eE][+-]?[0-9]+)?$', $text)) {
        failStatus(
            plain(xml.localName($a.body)) + ": " + $what + " is not a number: " + shown($text),
            $a.status);
    }
    def f as float;
    try {
        $f = convert.toFloat($text);
    } catch (e) {
        failStatus(
            plain(xml.localName($a.body)) + ": " + $what + " is out of range: " + shown($text),
            $a.status);
    }
    return $f;
}

/**
 * An `xs:boolean` from a reply.
 *
 * @param text {string} the text
 * @param what {string} the field, for the message
 * @param a {Answer} the answer, for its status
 * @return {bool} the value
 */
func boolOf(text as string, what as string, a as Answer) {
    if ($text == "true" or $text == "1") {
        return true;
    }
    if ($text == "false" or $text == "0") {
        return false;
    }
    failStatus(
        plain(xml.localName($a.body)) + ": " + $what + " is not a boolean: " + shown($text),
        $a.status);
    return false;
}

/**
 * A float as `xs:float` text.
 *
 * @param f {float} the number
 * @return {string} the text
 */
func floatText(f as float) {
    return convert.toString($f);
}

/**
 * Check a number is in a range.
 *
 * @param f {float} the number
 * @param lo {float} the lowest allowed
 * @param hi {float} the highest allowed
 * @param what {string} what it is, for the message
 */
func checkRange(f as float, lo as float, hi as float, what as string) {
    if ($f < $lo or $f > $hi) {
        fail($what + " is " + floatText($lo) + " to " + floatText($hi) + ", got " + floatText($f));
    }
}
