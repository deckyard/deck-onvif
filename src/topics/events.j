# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.27.0

# onvif - Events through a pull-point subscription: create, pull, renew,
# unsubscribe. No callback server is needed. Spliced into onvif.j via
# include.

def const WSNT_NS as string init "http://docs.oasis-open.org/wsn/b-2";
def const TOPICS_NS as string init "http://www.onvif.org/ver10/topics";
def const CREATE_ACTION as string init "http://www.onvif.org/ver10/events/wsdl/EventPortType/CreatePullPointSubscriptionRequest";
def const PULL_ACTION as string init "http://www.onvif.org/ver10/events/wsdl/PullPointSubscription/PullMessagesRequest";
def const RENEW_ACTION as string init "http://docs.oasis-open.org/wsn/bw-2/SubscriptionManager/RenewRequest";
def const UNSUBSCRIBE_ACTION as string init "http://docs.oasis-open.org/wsn/bw-2/SubscriptionManager/UnsubscribeRequest";

/**
 * A pull-point subscription. Pass it to `pull`, `renew` and `unsubscribe`;
 * it ends by itself at `terminationTime` unless renewed.
 *
 * @field address {string} the subscription manager's URL the requests go
 *   to, placed as the service addresses are (on the device's origin when it
 *   names another host)
 * @field reference {string} the address as the camera gave it, sent back as
 *   WS-Addressing `To`
 * @field parameters {list of string} the reference parameters the device
 *   wants back as header blocks, as XML
 * @field currentTime {string} the device's time when it answered, as sent
 * @field terminationTime {string} when the subscription ends, as sent
 */
export def struct Subscription {
    address as string,
    reference as string,
    parameters as list of string,
    currentTime as string,
    terminationTime as string
};

/**
 * One notification from the device.
 *
 * @field topic {string} the topic, with the ONVIF topic namespace written
 *   `tns1:` (`tns1:VideoSource/MotionAlarm`,
 *   `tns1:RuleEngine/CellMotionDetector/Motion`); another namespace keeps
 *   the prefix the device wrote
 * @field utcTime {string} when it happened, as sent; "" when not given
 * @field operation {string} `Initialized`, `Changed` or `Deleted`; "" when
 *   not given
 * @field source {map of string to string} the `Source` simple items (the
 *   video source, rule, ...)
 * @field key {map of string to string} the `Key` simple items
 * @field data {map of string to string} the `Data` simple items (`State`:
 *   `true`, ...)
 */
export def struct Event {
    topic as string,
    utcTime as string,
    operation as string,
    source as map of string to string,
    key as map of string to string,
    data as map of string to string
};

/**
 * What a pull brought: the events, and the subscription with the times the
 * device sent along.
 *
 * @field events {list of Event} the events, oldest first; empty when none
 *   came
 * @field subscription {Subscription} the subscription, its `currentTime` and
 *   `terminationTime` from the reply (a device may extend a subscription
 *   that is pulled); keep it for the next call
 */
export def struct Pulled {
    events as list of Event,
    subscription as Subscription
};

/**
 * A relative `xs:duration` of whole seconds.
 *
 * @param seconds {int} the seconds
 * @return {string} `PTnS`
 */
func duration(seconds as int) {
    return "PT" + convert.toString($seconds) + "S";
}

/**
 * Subscribe to the device's events (`CreatePullPointSubscription`), every
 * topic, no filter.
 *
 * @param dev {Device} the device, after `connect`
 * @param seconds {int} how long it lasts unless renewed, 10 to 86400
 * @return {Subscription} the subscription
 * @throws {OnvifError} kind `"onvif"` for a time out of range, a device
 *   without events, a reply without an address, or as `call`
 */
export func subscribe(dev as Device, seconds as int) {
    if ($seconds < 10 or $seconds > 86400) {
        fail("a subscription lasts 10 to 86400 seconds, got " + convert.toString($seconds));
    }
    def op as xml.Value init xml.append(
        xml.elementNS(NS_EVENTS, "tev:CreatePullPointSubscription"),
        textElement(NS_EVENTS, "tev:InitialTerminationTime", duration($seconds)));
    def url as string init serviceAddress($dev, "events");
    def a as Answer init exchange(
        $dev,
        $url,
        CREATE_ACTION,
        $op,
        addressing(CREATE_ACTION, $url, []),
        $dev.timeoutMs,
        true);
    def ref as string init requiredText($a.body, "*:SubscriptionReference/*:Address", $a);
    def sub as Subscription init Subscription{
        address: rebase($dev, $ref, "a subscription address"),
        reference: $ref,
        parameters: [],
        currentTime: clean(textAt($a.body, "*:CurrentTime")),
        terminationTime: clean(textAt($a.body, "*:TerminationTime"))
    };
    if (xml.has($a.body, "*:SubscriptionReference/*:ReferenceParameters")) {
        for (def p in xml.children(xml.get(
            $a.body,
            "*:SubscriptionReference/*:ReferenceParameters"))) {
            if (xml.namespace($p) == "") {
                failStatus(
                    "CreatePullPointSubscription: a reference parameter has no namespace",
                    $a.status);
            }
            $sub.parameters[] = xml.encode($p);
        }
    }
    return $sub;
}

/**
 * The WS-Addressing header blocks of a call: `Action`, `To`, `MessageID`
 * and the reference parameters.
 *
 * @param action {string} the action URI
 * @param to2 {string} the address
 * @param parameters {list of string} the reference parameters, as XML
 * @return {list of xml.Value} the header blocks
 */
func addressing(action as string, to2 as string, parameters as list of string) {
    def out as list of xml.Value init [
        textElement(WSA_NS, "wsa:Action", $action),
        textElement(WSA_NS, "wsa:To", $to2),
        textElement(WSA_NS, "wsa:MessageID", "urn:uuid:" + uuid.v4())
    ];
    for (def p in $parameters) {
        def block as xml.Value init xml.decode($p);
        $out[] = xml.setAttrNS($block, WSA_NS, "wsa:IsReferenceParameter", "true");
    }
    return $out;
}

/**
 * The simple items under a path, `Name` to `Value`.
 *
 * @param node {xml.Value} the `tt:Message` element
 * @param path {string} `*:Source`, `*:Key` or `*:Data`
 * @return {map of string to string} the items
 */
func simpleItems(node as xml.Value, path as string) {
    def out as map of string to string init {};
    if (not xml.has($node, $path)) {
        return $out;
    }
    for (def item in xml.findAll(xml.get($node, $path), "*:SimpleItem")) {
        def name as string init attrOf($item, "Name");
        if ($name != "") {
            $out[clean($name)] = clean(attrOf($item, "Value"));
        }
    }
    return $out;
}

/**
 * A topic expression with the ONVIF topic namespace written `tns1:`.
 *
 * @param topic {xml.Value} the `wsnt:Topic` element
 * @return {string} the topic
 */
func topicOf(topic as xml.Value) {
    def text as string init strings.trim(xml.text($topic));
    def at as int init strings.indexOf($text, ":");
    if ($at > 0) {
        def ns as string init "";
        try {
            $ns = xml.lookupPrefix($topic, $text[..$at]);
        } catch (e) {
            $ns = "";
        }
        if ($ns == TOPICS_NS) {
            return clean("tns1:" + $text[$at + 1..]);
        }
    }
    return clean($text);
}

/**
 * Wait for events (`PullMessages`): the device answers as soon as it has
 * any, or with none after `timeoutSeconds`. The first pull of a new
 * subscription brings the current state of each property (`Initialized`).
 *
 * @param dev {Device} the device
 * @param sub {Subscription} the subscription
 * @param timeoutSeconds {int} how long the device may wait, 1 to 60
 * @param limit {int} the most events to take, 1 to 1024
 * @return {Pulled} the events, oldest first, and the subscription with the
 *   device's new `currentTime` and `terminationTime`
 * @throws {OnvifError} kind `"onvif"` for a value out of range, more events
 *   than `limit`, or as `call` (a subscription that ended is a fault, often
 *   `ResourceUnknownFault`)
 */
export func pull(dev as Device, sub as Subscription, timeoutSeconds as int, limit as int) {
    if ($timeoutSeconds < 1 or $timeoutSeconds > 60) {
        fail("a pull waits 1 to 60 seconds, got " + convert.toString($timeoutSeconds));
    }
    if ($limit < 1 or $limit > 1024) {
        fail("a pull takes 1 to 1024 events, got " + convert.toString($limit));
    }
    def op as xml.Value init xml.elementNS(NS_EVENTS, "tev:PullMessages");
    $op = xml.append($op, textElement(NS_EVENTS, "tev:Timeout", duration($timeoutSeconds)));
    $op = xml.append($op, textElement(NS_EVENTS, "tev:MessageLimit", convert.toString($limit)));
    # the device holds the answer up to the timeout: wait that long on top
    def a as Answer init exchange(
        $dev,
        $sub.address,
        PULL_ACTION,
        $op,
        addressing(PULL_ACTION, $sub.reference, $sub.parameters),
        $dev.timeoutMs + $timeoutSeconds * 1000,
        true);
    def found as list of xml.Value init xml.findAll($a.body, "*:NotificationMessage");
    if (len($found) > $limit) {
        failStatus(
            "PullMessages: " + convert.toString(len($found)) + " events, over the limit of " +
                convert.toString($limit),
            $a.status);
    }
    def out as list of Event init [];
    for (def n in $found) {
        def e as Event init Event{
            topic: "",
            utcTime: "",
            operation: "",
            source: {},
            key: {},
            data: {}
        };
        if (xml.has($n, "*:Topic")) {
            $e.topic = topicOf(xml.get($n, "*:Topic"));
        }
        if (xml.has($n, "*:Message/*:Message")) {
            def m as xml.Value init xml.get($n, "*:Message/*:Message");
            $e.utcTime = clean(attrOf($m, "UtcTime"));
            $e.operation = clean(attrOf($m, "PropertyOperation"));
            $e.source = simpleItems($m, "*:Source");
            $e.key = simpleItems($m, "*:Key");
            $e.data = simpleItems($m, "*:Data");
        }
        $out[] = $e;
    }
    # PullMessagesResponse carries both times; a device that leaves one out
    # leaves the old value
    if (textAt($a.body, "*:TerminationTime") != "") {
        $sub.terminationTime = clean(textAt($a.body, "*:TerminationTime"));
    }
    if (textAt($a.body, "*:CurrentTime") != "") {
        $sub.currentTime = clean(textAt($a.body, "*:CurrentTime"));
    }
    return Pulled{events: $out, subscription: $sub};
}

/**
 * Extend a subscription (`Renew`).
 *
 * @param dev {Device} the device
 * @param sub {Subscription} the subscription
 * @param seconds {int} how long from now it lasts, 10 to 86400
 * @return {Subscription} the subscription with the new times
 * @throws {OnvifError} kind `"onvif"` for a time out of range, or as `call`
 */
export func renew(dev as Device, sub as Subscription, seconds as int) {
    if ($seconds < 10 or $seconds > 86400) {
        fail("a subscription lasts 10 to 86400 seconds, got " + convert.toString($seconds));
    }
    def op as xml.Value init xml.append(
        xml.elementNS(WSNT_NS, "wsnt:Renew"),
        textElement(WSNT_NS, "wsnt:TerminationTime", duration($seconds)));
    def a as Answer init exchange(
        $dev,
        $sub.address,
        RENEW_ACTION,
        $op,
        addressing(RENEW_ACTION, $sub.reference, $sub.parameters),
        $dev.timeoutMs,
        true);
    $sub.terminationTime = clean(requiredText($a.body, "*:TerminationTime", $a));
    $sub.currentTime = clean(textAt($a.body, "*:CurrentTime"));
    return $sub;
}

/**
 * End a subscription (`Unsubscribe`).
 *
 * @param dev {Device} the device
 * @param sub {Subscription} the subscription
 * @throws {OnvifError} kind `"onvif"` as `call`
 */
export func unsubscribe(dev as Device, sub as Subscription) {
    exchange(
        $dev,
        $sub.address,
        UNSUBSCRIBE_ACTION,
        xml.elementNS(WSNT_NS, "wsnt:Unsubscribe"),
        addressing(UNSUBSCRIBE_ACTION, $sub.reference, $sub.parameters),
        $dev.timeoutMs,
        true);
}
