# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

# onvif - Media and Media2: profiles, stream and snapshot URIs, snapshots.
# Spliced into onvif.j via include.

/**
 * A media profile: one combination of video source, encoder and PTZ
 * configuration a client streams.
 *
 * @field token {string} the profile token the media and PTZ calls take
 * @field name {string} its name
 * @field fixed {bool} whether the device keeps it fixed (not deletable)
 * @field videoSource {string} the video source token the imaging calls
 *   take; "" for none
 * @field encoding {string} the video encoding (`H264`, `H265`, `JPEG`,
 *   ...); "" for none
 * @field width {int} the video width; 0 when not reported
 * @field height {int} the video height; 0 when not reported
 * @field ptz {string} the PTZ configuration token; "" when the profile has
 *   no PTZ
 */
export def struct Profile {
    token as string,
    name as string,
    fixed as bool,
    videoSource as string,
    encoding as string,
    width as int,
    height as int,
    ptz as string
};

/**
 * A profile's RTSP stream address, as the camera gave it and moved onto the
 * device's host.
 *
 * @field address {string} the `rtsp://` (or `rtsps://`) URI exactly as the
 *   camera gave it; behind NAT it names the camera's inner address
 * @field rebased {string} the same URI with its host replaced by the host of
 *   the device address (scheme, user information, port, path and query
 *   kept); equal to `address` when the camera named that host
 */
export def struct Stream {
    address as string,
    rebased as string
};

/**
 * The media service the media calls use.
 *
 * @param dev {Device} the device
 * @return {string} `media2` or `media`
 */
func mediaService(dev as Device) {
    if ($dev.media != "") {
        return $dev.media;
    }
    if (maps.has($dev.services, "media2")) {
        return "media2";
    }
    if (maps.has($dev.services, "media")) {
        return "media";
    }
    fail("the device has no media service; connect first");
    return "";
}

/**
 * A pixel count from a reply.
 *
 * @param text {string} the text, "" for none
 * @param a {Answer} the answer, for its status
 * @return {int} the count; 0 for none
 */
func sizeOf(text as string, a as Answer) {
    if ($text == "") {
        return 0;
    }
    if (not regex.matches('^[0-9]{1,6}$', $text)) {
        failStatus("GetProfiles: a resolution is not a number: " + shown($text), $a.status);
    }
    return convert.toInt($text);
}

/**
 * The media profiles (`GetProfiles` of Media2, or of Media on a device
 * without it).
 *
 * @param dev {Device} the device, after `connect`
 * @return {list of Profile} the profiles
 * @throws {OnvifError} kind `"onvif"` as `call`, a profile without a token,
 *   or a device without a media service
 */
export func profiles(dev as Device) {
    def service as string init mediaService($dev);
    def a as Answer;
    if ($service == "media2") {
        def op as xml.Value init xml.append(
            xml.elementNS(NS_MEDIA2, "tr2:GetProfiles"),
            textElement(NS_MEDIA2, "tr2:Type", "All"));
        $a = request($dev, "media2", "GetProfiles", $op);
    } else {
        $a = request($dev, "media", "GetProfiles", xml.elementNS(NS_MEDIA, "trt:GetProfiles"));
    }
    def out as list of Profile init [];
    for (def p in xml.findAll($a.body, "*:Profiles")) {
        def token as string init attrOf($p, "token");
        if ($token == "" or len($token) > MAX_TOKEN) {
            failStatus("GetProfiles: a profile has no token or one over 64 characters", $a.status);
        }
        def fixed as bool init false;
        if (attrOf($p, "fixed") != "") {
            $fixed = boolOf(attrOf($p, "fixed"), "fixed", $a);
        }
        def video as string init "*:VideoSourceConfiguration";
        def encoder as string init "*:VideoEncoderConfiguration";
        def ptz as string init "*:PTZConfiguration";
        if ($service == "media2") {
            $video = "*:Configurations/*:VideoSource";
            $encoder = "*:Configurations/*:VideoEncoder";
            $ptz = "*:Configurations/*:PTZ";
        }
        def ptzToken as string init "";
        if (xml.has($p, $ptz)) {
            $ptzToken = clean(attrOf(xml.get($p, $ptz), "token"));
        }
        $out[] = Profile{
            token: $token,
            name: textAt($p, "*:Name"),
            fixed: $fixed,
            videoSource: textAt($p, $video + "/*:SourceToken"),
            encoding: clean(textAt($p, $encoder + "/*:Encoding")),
            width: sizeOf(textAt($p, $encoder + "/*:Resolution/*:Width"), $a),
            height: sizeOf(textAt($p, $encoder + "/*:Resolution/*:Height"), $a),
            ptz: $ptzToken
        };
    }
    return $out;
}

/**
 * The URI in a `GetStreamUri` / `GetSnapshotUri` answer: Media's
 * `MediaUri/Uri` or Media2's `Uri`.
 *
 * @param a {Answer} the answer
 * @param schemes {string} the allowed schemes, a regex alternation
 * @return {string} the URI
 */
func mediaUri(a as Answer, schemes as string) {
    def u as string init "";
    if (xml.has($a.body, "*:MediaUri/*:Uri")) {
        $u = textAt($a.body, "*:MediaUri/*:Uri");
    } else {
        $u = requiredText($a.body, "*:Uri", $a);
    }
    if (not regex.matches('^(' + $schemes + ')://[^/?#\s]+(/[!-~]*)?$', $u)) {
        failStatus(
            plain(xml.localName($a.body)) + ": not a " + $schemes + " URI: " + shownUrl($u),
            $a.status);
    }
    return $u;
}

/**
 * The RTSP address of a profile's stream (`GetStreamUri`, RTP unicast over
 * RTSP). The deck adds no credentials: the player signs in to RTSP itself.
 * Use `address` on the camera's own network; `rebased` reaches a camera
 * behind NAT whose RTSP port is forwarded on the same number.
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @return {Stream} the URI as the camera gave it, and on the device's host
 * @throws {OnvifError} kind `"onvif"` as `call` (`ter:InvalidArgVal` /
 *   `ter:NoProfile` for an unknown profile), a bad token, or an answer that
 *   is not an RTSP URI
 */
export func streamUri(dev as Device, profile as string) {
    checkToken($profile, "profile token");
    def a as Answer;
    if (mediaService($dev) == "media2") {
        def op as xml.Value init xml.elementNS(NS_MEDIA2, "tr2:GetStreamUri");
        $op = xml.append($op, textElement(NS_MEDIA2, "tr2:Protocol", "RtspUnicast"));
        $op = xml.append($op, textElement(NS_MEDIA2, "tr2:ProfileToken", $profile));
        $a = request($dev, "media2", "GetStreamUri", $op);
    } else {
        def transport as xml.Value init xml.append(
            xml.elementNS(NS_SCHEMA, "tt:Transport"),
            textElement(NS_SCHEMA, "tt:Protocol", "RTSP"));
        def setup as xml.Value init xml.elementNS(NS_MEDIA, "trt:StreamSetup");
        $setup = xml.append($setup, textElement(NS_SCHEMA, "tt:Stream", "RTP-Unicast"));
        $setup = xml.append($setup, $transport);
        def op as xml.Value init xml.elementNS(NS_MEDIA, "trt:GetStreamUri");
        $op = xml.append($op, $setup);
        $op = xml.append($op, textElement(NS_MEDIA, "trt:ProfileToken", $profile));
        $a = request($dev, "media", "GetStreamUri", $op);
    }
    def u as string init mediaUri($a, "rtsps?");
    return Stream{address: $u, rebased: onDeviceHost($dev, $u, "a stream address")};
}

/**
 * The address of a profile's JPEG snapshot (`GetSnapshotUri`).
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @return {string} the `http(s)://` URI as the camera gave it, without user
 *   information (`user:password@`) some cameras put in it
 * @throws {OnvifError} kind `"onvif"` as `streamUri`
 */
export func snapshotUri(dev as Device, profile as string) {
    checkToken($profile, "profile token");
    def a as Answer;
    if (mediaService($dev) == "media2") {
        $a = request(
            $dev,
            "media2",
            "GetSnapshotUri",
            xml.append(
                xml.elementNS(NS_MEDIA2, "tr2:GetSnapshotUri"),
                textElement(NS_MEDIA2, "tr2:ProfileToken", $profile)));
    } else {
        $a = request(
            $dev,
            "media",
            "GetSnapshotUri",
            xml.append(
                xml.elementNS(NS_MEDIA, "trt:GetSnapshotUri"),
                textElement(NS_MEDIA, "trt:ProfileToken", $profile)));
    }
    return withoutUserInfo(mediaUri($a, "https?"), "a snapshot address");
}

/**
 * Fetch a profile's snapshot: `GetSnapshotUri`, then a GET of that address.
 * The address is placed as the service addresses are: kept when it names the
 * device's host, else moved onto the device's scheme, host and port (path
 * and query kept), so credentials go nowhere else. User information in it
 * is dropped unused; the device's own credentials answer a `401`, once:
 * HTTP Digest always, HTTP Basic only over `https`.
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @return {bytes} the image (JPEG as a rule)
 * @throws {OnvifError} kind `"onvif"` as `snapshotUri`, for a non-2xx
 *   status, Basic auth asked over plain `http`, or an answer that is not an
 *   image
 * @throws {Error} kind `"limit"` for an image over `maxMediaBytes`,
 *   `"timeout"` and `"closed"` from the transport
 * @throws {net.NetError} kind `"net"` when the camera cannot be reached
 */
export func snapshot(dev as Device, profile as string) {
    return download($dev, snapshotUri($dev, $profile));
}

/**
 * GET an image.
 *
 * @param dev {Device} the device
 * @param url {string} the camera's snapshot URL
 * @return {bytes} the image
 */
func download(dev as Device, url as string) {
    def target as string init rebase(
        $dev,
        withoutUserInfo($url, "a snapshot address"),
        "a snapshot address");
    checkReachable($dev, $target, "the snapshot address");
    def headers as map of string to string init {"Accept": "image/*"};
    def r as http.BytesResponse init fetchBytes($dev, $target, $headers);
    if ($r.status == 401 and $dev.user != "") {
        def challenge as string init "";
        if (maps.has($r.headers, "www-authenticate")) {
            $challenge = $r.headers["www-authenticate"];
        }
        def lower as string init strings.lower($challenge);
        if (isDigestChallenge($challenge)) {
            try {
                $headers["Authorization"] = http.digestAuthorization(
                    $challenge,
                    "GET",
                    $target,
                    $dev.user,
                    $dev.password,
                    "");
            } catch (e) {
                failStatus(
                    "snapshot: cannot answer the Digest challenge: " + plain($e.message),
                    401);
            }
        } elseif (regex.matches('(^|[\s,])basic(\s|$)', $lower)) {
            if (strings.startsWith($target, "http:")) {
                failStatus(
                    "snapshot: the camera asks for HTTP Basic over plain http, which would send the password readable; refused",
                    401);
            }
            $headers["Authorization"] = http.basic($dev.user, $dev.password);
        } else {
            failStatus("snapshot: HTTP 401 without a Digest or Basic challenge", 401);
        }
        $r = fetchBytes($dev, $target, $headers);
    }
    if ($r.status < 200 or $r.status > 299) {
        failStatus(
            "snapshot: HTTP " + convert.toString($r.status) + " " + plain($r.statusText) +
                " from " +
                shownUrl($target),
            $r.status);
    }
    def ct as string init "";
    if (maps.has($r.headers, "content-type")) {
        $ct = strings.lower(strings.trim($r.headers["content-type"]));
    }
    if (not strings.startsWith($ct, "image/") and not isImage($r.body)) {
        failStatus("snapshot: the answer is not an image (" + shown($ct) + ")", $r.status);
    }
    return $r.body;
}

/**
 * Whether bytes start like a JPEG or PNG file.
 *
 * @param b {bytes} the bytes
 * @return {bool} whether they look like an image
 */
func isImage(b as bytes) {
    if (len($b) >= 3 and $b[0] == 255 and $b[1] == 216 and $b[2] == 255) {
        return true;
    }
    return len($b) >= 4 and $b[0] == 137 and $b[1] == 80 and $b[2] == 78 and $b[3] == 71;
}

/**
 * One GET with the device's timeout, media cap and TLS.
 *
 * @param dev {Device} the device
 * @param url {string} the URL
 * @param headers {map of string to string} the headers
 * @return {http.BytesResponse} the response
 */
func fetchBytes(dev as Device, url as string, headers as map of string to string) {
    def r as http.BytesResponse;
    try {
        $r = http.requestWithBytes(
            "GET",
            $url,
            $headers,
            "",
            $dev.timeoutMs,
            $dev.maxMediaBytes,
            $dev.tls);
    } catch (e) {
        if ($e.kind == "cancelled") {
            throw $e;
        }
        if ($e.kind == "net") {
            throw netPassedOn($e, $url);
        }
        def why as string init plain(strings.replace($e.message, $url, shownUrl($url)));
        if ($e.kind == "limit" or $e.kind == "timeout" or $e.kind == "closed") {
            throw Error{
                kind: $e.kind,
                message: "onvif: snapshot: GET " + shownUrl($url) + ": " + $why
            };
        }
        fail("snapshot: GET " + shownUrl($url) + ": " + $why);
    }
    return $r;
}
