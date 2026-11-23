# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.27.0

# onvif - WS-Discovery: a Probe to the multicast group, ProbeMatches back by
# unicast. Spliced into onvif.j via include.

/** The WS-Discovery multicast group and port. */
export def const DISCOVERY_ADDRESS as string init "239.255.255.250:3702";

/** The most devices one discovery returns. */
export def const MAX_DEVICES as int init 256;

def const WSD_NS as string init "http://schemas.xmlsoap.org/ws/2005/04/discovery";
def const WSA04_NS as string init "http://schemas.xmlsoap.org/ws/2004/08/addressing";
def const NETWORK_NS as string init "http://www.onvif.org/ver10/network/wsdl";
def const PROBE_ACTION as string init "http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe";
def const MATCHES_ACTION as string init "http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches";

# the largest datagram read; a longer one is cut and skipped
def const MAX_DATAGRAM as int init 65535;

/**
 * A device that answered a Probe.
 *
 * @field endpoint {string} its stable endpoint reference (`urn:uuid:...`)
 * @field address {string} the first `http(s)` XAddr, the device service URL
 *   to pass to `device`; "" when it sent none
 * @field xaddrs {list of string} every XAddr it sent
 * @field types {list of string} its types as written
 *   (`tdn:NetworkVideoTransmitter`)
 * @field scopes {list of string} its scope URIs
 * @field name {string} the `onvif://www.onvif.org/name/` scope, decoded;
 *   "" for none
 * @field hardware {string} the `onvif://www.onvif.org/hardware/` scope,
 *   decoded; "" for none
 * @field from {string} the `host:port` the answer came from
 */
export def struct Discovered {
    endpoint as string,
    address as string,
    xaddrs as list of string,
    types as list of string,
    scopes as list of string,
    name as string,
    hardware as string,
    from as string
};

/**
 * How to probe.
 *
 * @field timeoutMs {int} how long to collect answers, 100 to 30000
 * @field target {string} where the Probe goes, `host:port`: the multicast
 *   group, or one device by unicast
 * @field iface {string} the network interface to send on (Linux,
 *   `SO_BINDTODEVICE`); "" for the routing table's choice
 * @field types {list of string} the device types to ask for, each a
 *   separate Probe: `NetworkVideoTransmitter` (cameras, `dn:` prefix) and
 *   `Device` (any ONVIF device, `tds:` prefix)
 */
export def struct DiscoveryOptions {
    timeoutMs as int,
    target as string,
    iface as string,
    types as list of string
};

/**
 * The default discovery: 3 s, the multicast group, any interface, both
 * types.
 *
 * @return {DiscoveryOptions} the options
 */
export func discoveryOptions() {
    return DiscoveryOptions{
        timeoutMs: 3000,
        target: DISCOVERY_ADDRESS,
        iface: "",
        types: ["NetworkVideoTransmitter", "Device"]
    };
}

/**
 * Find ONVIF devices on the local network: send a Probe to the
 * WS-Discovery group and collect the answers for `timeoutMs`.
 *
 * @param timeoutMs {int} how long to wait for answers, 100 to 30000
 * @return {list of Discovered} the devices, in the order they answered, one
 *   per endpoint
 * @throws {OnvifError} kind `"onvif"` for a timeout out of range
 * @throws {net.NetError} kind `"net"` for a socket that cannot be bound or
 *   send
 */
export func discover(timeoutMs as int) {
    def o as DiscoveryOptions init discoveryOptions();
    $o.timeoutMs = $timeoutMs;
    return discoverWith($o);
}

/**
 * The SOAP 1.2 Probe message.
 *
 * @param messageId {string} its `MessageID`, `urn:uuid:...`
 * @param kind {string} `NetworkVideoTransmitter` or `Device`
 * @return {string} the message
 */
func probeMessage(messageId as string, kind as string) {
    def typeName as string init "dn:NetworkVideoTransmitter";
    if ($kind == "Device") {
        $typeName = "tds:Device";
    }
    def header as list of xml.Value init [
        textElement(WSA04_NS, "a:MessageID", $messageId),
        textElement(WSA04_NS, "a:To", "urn:schemas-xmlsoap-org:ws:2005:04:discovery"),
        textElement(WSA04_NS, "a:Action", PROBE_ACTION)
    ];
    def types as xml.Value init textElement(WSD_NS, "d:Types", $typeName);
    $types = xml.setAttr($types, "xmlns:dn", NETWORK_NS);
    $types = xml.setAttr($types, "xmlns:tds", NS_DEVICE);
    def probe as xml.Value init xml.append(xml.elementNS(WSD_NS, "d:Probe"), $types);
    return soap.envelope("1.2", $header, [$probe]);
}

/**
 * The words of a space-separated list.
 *
 * @param text {string} the list
 * @return {list of string} its words
 */
func words(text as string) {
    def out as list of string init [];
    for (def w in regex.split('\s+', strings.trim($text))) {
        if ($w != "") {
            $out[] = $w;
        }
    }
    return $out;
}

/**
 * The decoded value of a scope under a prefix, or "".
 *
 * @param scopes {list of string} the scope URIs
 * @param prefix {string} the prefix, with its trailing `/`
 * @return {string} the rest of the first matching scope, percent-decoded
 */
func scopeValue(scopes as list of string, prefix as string) {
    for (def s in $scopes) {
        if (strings.startsWith(strings.lower($s), $prefix) and len($s) > len($prefix)) {
            def raw as string init $s[len($prefix)..];
            try {
                return clean(uri.decode($raw));
            } catch (e) {
                return clean($raw);
            }
        }
    }
    return "";
}

/**
 * Parse a ProbeMatches message answering one of our Probes. Anything else
 * (another message, a malformed one, an answer to someone else) gives an
 * empty list.
 *
 * @param text {string} the datagram
 * @param ids {list of string} the MessageIDs of our Probes
 * @param from {string} where it came from
 * @return {list of Discovered} the devices in it
 */
func parseMatches(text as string, ids as list of string, from as string) {
    def out as list of Discovered init [];
    def env as soap.Envelope;
    try {
        $env = soap.parse($text);
    } catch (e) {
        return $out;
    }
    def relates as string init "";
    def action as string init "";
    for (def h in $env.headers) {
        if (xml.localName($h) == "RelatesTo") {
            $relates = strings.trim(xml.text($h));
        } elseif (xml.localName($h) == "Action") {
            $action = strings.trim(xml.text($h));
        }
    }
    if (not lists.contains($ids, $relates) or $action != MATCHES_ACTION or len($env.body) != 1 or
        xml.localName($env.body[0]) != "ProbeMatches") {
        return $out;
    }
    for (def m in xml.findAll($env.body[0], "*:ProbeMatch")) {
        def d as Discovered init Discovered{
            endpoint: clean(textAt($m, "*:EndpointReference/*:Address")),
            address: "",
            xaddrs: [],
            types: [],
            scopes: [],
            name: "",
            hardware: "",
            from: $from
        };
        for (def w in words(textAt($m, "*:Types"))) {
            $d.types[] = clean($w);
        }
        for (def w in words(textAt($m, "*:Scopes"))) {
            $d.scopes[] = clean($w);
        }
        for (def w in words(textAt($m, "*:XAddrs"))) {
            $d.xaddrs[] = clean($w);
            if ($d.address == "" and regex.matches('^https?://[^/?#@\s]+(/[!-~]*)?$', $w)) {
                $d.address = $w;
            }
        }
        $d.name = scopeValue($d.scopes, "onvif://www.onvif.org/name/");
        $d.hardware = scopeValue($d.scopes, "onvif://www.onvif.org/hardware/");
        if ($d.endpoint != "") {
            $out[] = $d;
        }
    }
    return $out;
}

/**
 * Find ONVIF devices with these options: one Probe per type to
 * `options.target`, then every ProbeMatches answering them until
 * `options.timeoutMs` has passed. Devices answer by unicast to the sending
 * socket, so no multicast group is joined. Answers that are not ProbeMatches
 * for these Probes, malformed or cut at 64 KiB are skipped; a device that
 * answers twice is listed once.
 *
 * @param options {DiscoveryOptions} the options, from `discoveryOptions`
 * @return {list of Discovered} the devices, at most `MAX_DEVICES`
 * @throws {OnvifError} kind `"onvif"` for a timeout out of range, an unknown
 *   type or a target that is not `host:port`
 * @throws {net.NetError} kind `"net"` for a socket that cannot be bound or
 *   send
 */
export func discoverWith(options as DiscoveryOptions) {
    if ($options.timeoutMs < 100 or $options.timeoutMs > 30000) {
        fail("a discovery timeout is 100 to 30000 ms, got " + convert.toString($options.timeoutMs));
    }
    if (not regex.matches('^([A-Za-z0-9.-]+|\[[0-9A-Fa-f:.]+\]):[0-9]{1,5}$', $options.target)) {
        fail("a discovery target is host:port, got " + shown($options.target));
    }
    if (len($options.types) == 0) {
        fail("a discovery asks for at least one type");
    }
    for (def t in $options.types) {
        if ($t != "NetworkVideoTransmitter" and $t != "Device") {
            fail("a discovery type is NetworkVideoTransmitter or Device, got " + shown($t));
        }
    }
    if (regex.matches('[^A-Za-z0-9._:-]', $options.iface)) {
        fail("an interface name is letters, digits and . _ : -, got " + shown($options.iface));
    }
    def sock as net.UDPSocket;
    try {
        $sock = net.listenUDP(":0");
    } catch (e) {
        if ($e.kind == "net") {
            throw $e;
        }
        fail("discovery: cannot open a UDP socket: " + plain($e.message));
    }
    defer net.close($sock);
    def ids as list of string init [];
    try {
        if ($options.iface != "") {
            net.bindToDevice($sock, $options.iface);
        }
        for (def t in $options.types) {
            def id as string init "urn:uuid:" + uuid.v4();
            $ids[] = $id;
            net.sendTo($sock, $options.target, encoding.encode("utf-8", probeMessage($id, $t)));
        }
    } catch (e) {
        if ($e.kind == "cancelled" or $e.kind == "net") {
            throw $e;
        }
        fail("discovery: cannot send to " + plain($options.target) + ": " + plain($e.message));
    }
    def found as list of Discovered init [];
    def seen as list of string init [];
    def deadline as int init time.unixMillis(time.now()) + $options.timeoutMs;
    while (len($found) < MAX_DEVICES) {
        def left as int init $deadline - time.unixMillis(time.now());
        if ($left <= 0) {
            break;
        }
        net.setReadDeadline($sock, $left);
        def dg as net.Datagram;
        try {
            $dg = net.recvFrom($sock, MAX_DATAGRAM);
        } catch (e) {
            if ($e.kind == "timeout") {
                break;
            }
            if ($e.kind == "cancelled" or $e.kind == "net") {
                throw $e;
            }
            fail("discovery: " + plain($e.message));
        }
        if ($dg.truncated) {
            continue;
        }
        def text as string init "";
        try {
            $text = encoding.decode("utf-8", $dg.data);
        } catch (e) {
            continue;
        }
        for (def d in parseMatches($text, $ids, $dg.peer)) {
            if (not lists.contains($seen, $d.endpoint) and len($found) < MAX_DEVICES) {
                $seen[] = $d.endpoint;
                $found[] = $d;
            }
        }
    }
    return $found;
}
