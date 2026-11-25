# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.28.0

# onvif - the Device service: connect, the clock, identity, services,
# scopes, reboot. Spliced into onvif.j via include.

/**
 * The camera's clock, as `GetSystemDateAndTime` reports it.
 *
 * @field utc {string} the camera's UTC time, `YYYY-MM-DDTHH:MM:SSZ`; "" when
 *   it sent none (then the offset is unknown)
 * @field dateTimeType {string} `NTP` or `Manual`, as sent
 * @field daylightSavings {bool} whether daylight saving time is on
 * @field timeZone {string} the POSIX time zone (`CET-1CEST,M3.5.0,M10.5.0/3`);
 *   "" for none
 */
export def struct Clock {
    utc as string,
    dateTimeType as string,
    daylightSavings as bool,
    timeZone as string
};

/**
 * Who made the device, as `GetDeviceInformation` reports it.
 *
 * @field manufacturer {string} the manufacturer
 * @field model {string} the model
 * @field firmwareVersion {string} the firmware version
 * @field serialNumber {string} the serial number
 * @field hardwareId {string} the hardware id
 */
export def struct DeviceInfo {
    manufacturer as string,
    model as string,
    firmwareVersion as string,
    serialNumber as string,
    hardwareId as string
};

/**
 * A service the device offers, from `GetServices` (or `GetCapabilities` on a
 * device without it).
 *
 * @field name {string} the deck's name for it (`media`, `ptz`, ...); "" for
 *   a namespace not in `SERVICES`
 * @field namespace {string} the service namespace
 * @field address {string} its URL, on the device's own scheme, host and port
 * @field version {string} `MAJOR.MINOR`; "" when not reported
 */
export def struct Service {
    name as string,
    namespace as string,
    address as string,
    version as string
};

/**
 * The services a device listed, and whether HTTP Digest was needed.
 *
 * @field services {list of Service} the services
 * @field digest {bool} whether HTTP Digest was needed
 */
def struct ServicesRead {
    services as list of Service,
    digest as bool
};

/**
 * A clock read and what it took.
 *
 * @field clock {Clock} the clock
 * @field offsetMs {int} the camera's clock minus this machine's
 * @field known {bool} whether the camera sent its UTC time
 * @field auth {string} the auth method that worked, when the clock was
 *   read signed or with HTTP Digest (`"wsse"`, `"digest"`); "" otherwise
 */
def struct ClockRead {
    clock as Clock,
    offsetMs as int,
    known as bool,
    auth as string
};

/**
 * Contact a device: read its clock for the WS-Security digest, then find
 * its services (`GetServices`, else `GetCapabilities`). Every other call
 * needs the services; `device` alone has only the device service.
 *
 * @param dev {Device} the device, from `device`
 * @return {Device} the device with its clock offset, services and media
 *   service (`media2` where offered) set, and `auth` settled from the first
 *   signed call (`"digest"` when the camera asked for HTTP Digest, else
 *   `"wsse"`) unless `withAuth` set it; services set by `withService` keep
 *   their addresses
 * @throws {OnvifError} kind `"onvif"` for a fault (`ter:NotAuthorized` for a
 *   wrong user or password), an HTTP failure or a malformed reply
 * @throws {Error} kind `"limit"`, `"timeout"` or `"closed"` from the
 *   transport
 * @throws {net.NetError} kind `"net"` when the camera cannot be reached
 */
export func connect(dev as Device) {
    $dev = syncClock($dev);
    def found as ServicesRead;
    def answered as bool init false;
    try {
        $found = readServices($dev, false);
        $answered = true;
    } catch (e) {
        # an old device without GetServices answers with a fault other than
        # an authentication failure; anything else goes on
        if ($e.kind != ERROR_KIND or $e.code == "" or $e.subcode == "ter:NotAuthorized" or
            $e.status == 401) {
            throw $e;
        }
    }
    if (not $answered) {
        $found = readCapabilities($dev);
    }
    if ($dev.auth == "" and $dev.user != "") {
        $dev.auth = "wsse";
        if ($found.digest) {
            $dev.auth = "digest";
        }
    }
    # explicit settings win over what the device reports
    def kept as map of string to string init $dev.services;
    $dev.services = {"device": $dev.address};
    for (def s in $found.services) {
        if ($s.name != "" and $s.name != "device") {
            $dev.services[$s.name] = $s.address;
        }
    }
    for (def name in $dev.overrides) {
        $dev.services[$name] = $kept[$name];
    }
    $dev.media = "";
    if (maps.has($dev.services, "media2")) {
        $dev.media = "media2";
    } elseif (maps.has($dev.services, "media")) {
        $dev.media = "media";
    }
    return $dev;
}

/**
 * Read the clock without signing, as ONVIF requires the camera to answer,
 * from the device service's address (`withService("device", ...)` moves
 * it). A camera that refuses is asked once more, signed with this machine's
 * clock.
 *
 * @param dev {Device} the device
 * @return {ClockRead} the clock and the offset
 */
func readClock(dev as Device) {
    def op as xml.Value init xml.elementNS(NS_DEVICE, "tds:GetSystemDateAndTime");
    def action as string init NS_DEVICE + "/GetSystemDateAndTime";
    def url as string init serviceAddress($dev, "device");
    def before as int init time.unixMilliseconds(time.now());
    def a as Answer;
    def refused as bool init false;
    try {
        $a = exchange($dev, $url, $action, $op, [], $dev.timeoutMs, false);
    } catch (e) {
        if ($e.kind != ERROR_KIND or ($e.status != 401 and $e.subcode != "ter:NotAuthorized")) {
            throw $e;
        }
        $refused = true;
    }
    if ($refused) {
        $before = time.unixMilliseconds(time.now());
        $a = exchange($dev, $url, $action, $op, [], $dev.timeoutMs, true);
    }
    def after as int init time.unixMilliseconds(time.now());
    def method as string init "";
    if ($a.digest) {
        $method = "digest";
    } elseif ($refused and $dev.user != "") {
        $method = "wsse";
    }
    def sdt as xml.Value init $a.body;
    if (not xml.has($sdt, "*:SystemDateAndTime")) {
        failStatus("GetSystemDateAndTime: the reply has no SystemDateAndTime", $a.status);
    }
    $sdt = xml.get($sdt, "*:SystemDateAndTime");
    def c as Clock init Clock{
        utc: "",
        dateTimeType: clean(textAt($sdt, "*:DateTimeType")),
        daylightSavings: false,
        timeZone: clean(textAt($sdt, "*:TimeZone/*:TZ"))
    };
    if (textAt($sdt, "*:DaylightSavings") != "") {
        $c.daylightSavings = boolOf(textAt($sdt, "*:DaylightSavings"), "DaylightSavings", $a);
    }
    if (not xml.has($sdt, "*:UTCDateTime")) {
        return ClockRead{clock: $c, offsetMs: 0, known: false, auth: $method};
    }
    def t as time.Time init dateTimeOf(xml.get($sdt, "*:UTCDateTime"), $a);
    $c.utc = time.format($t, "%Y-%m-%dT%H:%M:%SZ");
    def offset as int init time.unixMilliseconds($t) - ($before + ($after - $before) // 2);
    return ClockRead{clock: $c, offsetMs: $offset, known: true, auth: $method};
}

/**
 * A `tt:DateTime` (`Date` with `Year`, `Month`, `Day` and `Time` with
 * `Hour`, `Minute`, `Second`) as a UTC time.
 *
 * @param node {xml.Value} the `UTCDateTime` element
 * @param a {Answer} the answer, for its status
 * @return {time.Time} the time
 */
func dateTimeOf(node as xml.Value, a as Answer) {
    def parts as list of int init [];
    def limits as list of list of int init [
        [1970, 9999],
        [1, 12],
        [1, 31],
        [0, 23],
        [0, 59],
        [0, 60]
    ];
    def paths as list of string init [
        "*:Date/*:Year",
        "*:Date/*:Month",
        "*:Date/*:Day",
        "*:Time/*:Hour",
        "*:Time/*:Minute",
        "*:Time/*:Second"
    ];
    for (def i in 0..6) {
        def text as string init requiredText($node, $paths[$i], $a);
        if (not regex.matches('^[0-9]{1,4}$', $text)) {
            failStatus(
                "GetSystemDateAndTime: " + regex.replace('\*:', $paths[$i], "") +
                    " is not a number: " + shown($text),
                $a.status);
        }
        def n as int init convert.toInt($text);
        if ($n < $limits[$i][0] or $n > $limits[$i][1]) {
            failStatus(
                "GetSystemDateAndTime: " + regex.replace('\*:', $paths[$i], "") +
                    " is out of range: " + $text,
                $a.status);
        }
        $parts[] = $n;
    }
    # a leap second reads as the last second of its minute
    if ($parts[5] == 60) {
        $parts[5] = 59;
    }
    def iso as string init convert.toString($parts[0]) + "-" + pad2($parts[1]) + "-" +
        pad2($parts[2]) +
        "T" + pad2($parts[3]) + ":" + pad2($parts[4]) + ":" + pad2($parts[5]) + "Z";
    def t as time.Time;
    try {
        $t = time.fromIso($iso);
    } catch (e) {
        failStatus("GetSystemDateAndTime: not a date: " + $iso, $a.status);
    }
    return $t;
}

/**
 * A number of two digits at least.
 *
 * @param n {int} the number, 0 or more
 * @return {string} the digits
 */
func pad2(n as int) {
    if ($n < 10) {
        return "0" + convert.toString($n);
    }
    return convert.toString($n);
}

/**
 * Read the camera's clock (`GetSystemDateAndTime`, not signed).
 *
 * @param dev {Device} the device
 * @return {Clock} the clock
 * @throws {OnvifError} kind `"onvif"` as `call`, or for a malformed date
 */
export func systemDateAndTime(dev as Device) {
    return readClock($dev).clock;
}

/**
 * Read the camera's clock again and keep its offset for the WS-Security
 * digest. `connect` does it once; a long-running program does it now and
 * then, since cameras refuse a `Created` too far from their own time
 * (`ter:NotAuthorized`). A camera that sends no UTC time leaves the offset
 * at 0 and `clockSynced` false.
 *
 * @param dev {Device} the device
 * @return {Device} the device with `offsetMs` and `clockSynced` set, and
 *   `auth` when it was not known and the clock had to be read signed
 * @throws {OnvifError} kind `"onvif"` as `systemDateAndTime`
 */
export func syncClock(dev as Device) {
    def r as ClockRead init readClock($dev);
    $dev.offsetMs = $r.offsetMs;
    $dev.clockSynced = $r.known;
    if ($dev.auth == "" and $r.auth != "") {
        $dev.auth = $r.auth;
    }
    return $dev;
}

/**
 * Who made the device (`GetDeviceInformation`).
 *
 * @param dev {Device} the device
 * @return {DeviceInfo} manufacturer, model, firmware, serial number,
 *   hardware id; a field the device left out is ""
 * @throws {OnvifError} kind `"onvif"` as `call`
 */
export func deviceInformation(dev as Device) {
    def a as Answer init request(
        $dev,
        "device",
        "GetDeviceInformation",
        xml.elementNS(NS_DEVICE, "tds:GetDeviceInformation"));
    return DeviceInfo{
        manufacturer: textAt($a.body, "*:Manufacturer"),
        model: textAt($a.body, "*:Model"),
        firmwareVersion: textAt($a.body, "*:FirmwareVersion"),
        serialNumber: textAt($a.body, "*:SerialNumber"),
        hardwareId: textAt($a.body, "*:HardwareId")
    };
}

/**
 * The service name of a namespace, or "".
 *
 * @param ns {string} the namespace
 * @return {string} its name in `SERVICES`
 */
func serviceName(ns as string) {
    for (def name in SERVICES) {
        if (SERVICES[$name] == $ns) {
            return $name;
        }
    }
    return "";
}

/**
 * `GetServices`, parsed.
 *
 * @param dev {Device} the device
 * @param withCapabilities {bool} ask for the capabilities too (not read)
 * @return {ServicesRead} the services
 */
func readServices(dev as Device, withCapabilities as bool) {
    def op as xml.Value init xml.append(
        xml.elementNS(NS_DEVICE, "tds:GetServices"),
        textElement(NS_DEVICE, "tds:IncludeCapability", convert.toString($withCapabilities)));
    def a as Answer init request($dev, "device", "GetServices", $op);
    def out as list of Service init [];
    for (def s in xml.findAll($a.body, "*:Service")) {
        def ns as string init requiredText($s, "*:Namespace", $a);
        def address as string init rebase(
            $dev,
            requiredText($s, "*:XAddr", $a),
            "a service address");
        def version as string init "";
        if (xml.has($s, "*:Version/*:Major")) {
            $version = textAt($s, "*:Version/*:Major") + "." + textAt($s, "*:Version/*:Minor");
            if (not regex.matches('^[0-9]{1,6}\.[0-9]{1,6}$', $version)) {
                failStatus(
                    "GetServices: a version is not MAJOR.MINOR: " + shown($version),
                    $a.status);
            }
        }
        $out[] = Service{
            name: serviceName($ns),
            namespace: clean($ns),
            address: $address,
            version: $version
        };
    }
    if (len($out) == 0) {
        failStatus("GetServices: the reply lists no service", $a.status);
    }
    return ServicesRead{services: $out, digest: $a.digest};
}

/**
 * `GetCapabilities`, read for the service addresses, for a device without
 * `GetServices`.
 *
 * @param dev {Device} the device
 * @return {ServicesRead} the services it names
 */
func readCapabilities(dev as Device) {
    def op as xml.Value init xml.append(
        xml.elementNS(NS_DEVICE, "tds:GetCapabilities"),
        textElement(NS_DEVICE, "tds:Category", "All"));
    def a as Answer init request($dev, "device", "GetCapabilities", $op);
    if (not xml.has($a.body, "*:Capabilities")) {
        failStatus("GetCapabilities: the reply has no Capabilities", $a.status);
    }
    def caps as xml.Value init xml.get($a.body, "*:Capabilities");
    def paths as map of string to string init {
        "device": "*:Device/*:XAddr",
        "media": "*:Media/*:XAddr",
        "ptz": "*:PTZ/*:XAddr",
        "imaging": "*:Imaging/*:XAddr",
        "events": "*:Events/*:XAddr",
        "analytics": "*:Analytics/*:XAddr",
        "deviceio": "*:Extension/*:DeviceIO/*:XAddr",
        "recording": "*:Extension/*:Recording/*:XAddr",
        "search": "*:Extension/*:Search/*:XAddr",
        "replay": "*:Extension/*:Replay/*:XAddr"
    };
    def out as list of Service init [];
    for (def name in $paths) {
        def x as string init textAt($caps, $paths[$name]);
        if ($x != "") {
            $out[] = Service{
                name: $name,
                namespace: SERVICES[$name],
                address: rebase($dev, $x, "a service address"),
                version: ""
            };
        }
    }
    return ServicesRead{services: $out, digest: $a.digest};
}

/**
 * The services the device lists (`GetServices`), each with its namespace,
 * address and version, including ones the deck has no name for.
 *
 * @param dev {Device} the device
 * @return {list of Service} the services
 * @throws {OnvifError} kind `"onvif"` as `call`, or for a reply without a
 *   service
 */
export func services(dev as Device) {
    return readServices($dev, false).services;
}

/**
 * The device's scopes (`GetScopes`): URIs such as
 * `onvif://www.onvif.org/name/Gate` and `onvif://www.onvif.org/hardware/X1`.
 *
 * @param dev {Device} the device
 * @return {list of string} the scope URIs
 * @throws {OnvifError} kind `"onvif"` as `call`
 */
export func scopes(dev as Device) {
    def a as Answer init request(
        $dev,
        "device",
        "GetScopes",
        xml.elementNS(NS_DEVICE, "tds:GetScopes"));
    def out as list of string init [];
    for (def s in xml.findAll($a.body, "*:Scopes")) {
        $out[] = textAt($s, "*:ScopeItem");
    }
    return $out;
}

/**
 * Restart the device (`SystemReboot`). It stops answering for a while.
 *
 * @param dev {Device} the device
 * @return {string} the device's message (`Rebooting in 30 seconds`); ""
 *   for none
 * @throws {OnvifError} kind `"onvif"` as `call`
 */
export func reboot(dev as Device) {
    def a as Answer init request(
        $dev,
        "device",
        "SystemReboot",
        xml.elementNS(NS_DEVICE, "tds:SystemReboot"));
    return clean(textAt($a.body, "*:Message"));
}
