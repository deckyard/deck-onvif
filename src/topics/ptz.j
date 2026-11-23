# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.27.0

# onvif - PTZ: moves in the generic (normalized) spaces, stop, status,
# presets. Spliced into onvif.j via include.

/** The ONVIF pan/tilt space URIs, before `PositionGenericSpace` and the like. */
export def const PANTILT_SPACES as string init "http://www.onvif.org/ver10/tptz/PanTiltSpaces/";

/** The ONVIF zoom space URIs, before `PositionGenericSpace` and the like. */
export def const ZOOM_SPACES as string init "http://www.onvif.org/ver10/tptz/ZoomSpaces/";

/**
 * Where a PTZ head points and whether it moves, as `GetStatus` reports it.
 *
 * @field pan {float} the pan position; 0.0 when not reported
 * @field tilt {float} the tilt position; 0.0 when not reported
 * @field zoom {float} the zoom position; 0.0 when not reported
 * @field panTiltMoving {bool} pan or tilt is moving (`MOVING`)
 * @field zoomMoving {bool} zoom is moving
 * @field error {string} the device's error text; "" for none
 * @field utcTime {string} the device's time of the status, as sent
 */
export def struct PtzStatus {
    pan as float,
    tilt as float,
    zoom as float,
    panTiltMoving as bool,
    zoomMoving as bool,
    error as string,
    utcTime as string
};

/**
 * A stored PTZ position.
 *
 * @field token {string} the preset token `gotoPreset` takes
 * @field name {string} its name
 * @field pan {float} its pan position; 0.0 when not reported
 * @field tilt {float} its tilt position; 0.0 when not reported
 * @field zoom {float} its zoom position; 0.0 when not reported
 */
export def struct Preset {
    token as string,
    name as string,
    pan as float,
    tilt as float,
    zoom as float
};

/**
 * A PTZ operation element with its profile token.
 *
 * @param operation {string} the operation's local name
 * @param profile {string} the profile token
 * @return {xml.Value} the element
 */
func ptzOp(operation as string, profile as string) {
    checkToken($profile, "profile token");
    return xml.append(
        xml.elementNS(NS_PTZ, "tptz:" + $operation),
        textElement(NS_PTZ, "tptz:ProfileToken", $profile));
}

/**
 * A `tt:PTZVector`-shaped element: `PanTilt x y` and `Zoom x`, each naming
 * its generic space, so the head reads the numbers in the normalized range
 * the deck checked rather than in its configured default space.
 *
 * @param qname {string} its name (`tptz:Velocity`, ...)
 * @param space {string} `Position`, `Translation` or `Velocity`
 * @param pan {float} pan
 * @param tilt {float} tilt
 * @param zoom {float} zoom
 * @param withZoom {bool} whether to write the zoom
 * @return {xml.Value} the element
 */
func vector(
    qname as string,
    space as string,
    pan as float,
    tilt as float,
    zoom as float,
    withZoom as bool) {
    def v as xml.Value init xml.elementNS(NS_PTZ, $qname);
    def pt as xml.Value init xml.elementNS(NS_SCHEMA, "tt:PanTilt");
    $pt = xml.setAttr(xml.setAttr($pt, "x", floatText($pan)), "y", floatText($tilt));
    $pt = xml.setAttr($pt, "space", PANTILT_SPACES + $space + "GenericSpace");
    $v = xml.append($v, $pt);
    if ($withZoom) {
        def z as xml.Value init xml.setAttr(
            xml.elementNS(NS_SCHEMA, "tt:Zoom"),
            "x",
            floatText($zoom));
        $v = xml.append($v, xml.setAttr($z, "space", ZOOM_SPACES + $space + "GenericSpace"));
    }
    return $v;
}

/**
 * Start moving at a speed until `stopMove` (`ContinuousMove`). Speeds are
 * in the generic velocity space (`VelocityGenericSpace`, named in the
 * request), -1.0 to 1.0: positive pans right, tilts
 * up and zooms in. A zoom of 0.0 is left out, for heads without zoom.
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token (a profile with PTZ)
 * @param pan {float} the pan speed
 * @param tilt {float} the tilt speed
 * @param zoom {float} the zoom speed
 * @throws {OnvifError} kind `"onvif"` for a speed out of range, a bad token,
 *   a device without PTZ, or as `call`
 */
export func continuousMove(
    dev as Device,
    profile as string,
    pan as float,
    tilt as float,
    zoom as float) {
    checkRange($pan, -1.0, 1.0, "a pan speed");
    checkRange($tilt, -1.0, 1.0, "a tilt speed");
    checkRange($zoom, -1.0, 1.0, "a zoom speed");
    def op as xml.Value init xml.append(
        ptzOp("ContinuousMove", $profile),
        vector("tptz:Velocity", "Velocity", $pan, $tilt, $zoom, $zoom != 0.0));
    request($dev, "ptz", "ContinuousMove", $op);
}

/**
 * Move to a position (`AbsoluteMove`) in the generic position spaces
 * (`PositionGenericSpace`, named in the request): pan and tilt -1.0 to 1.0,
 * zoom 0.0 (wide) to 1.0 (tele). No `Speed` is sent: the head moves at its
 * default speed.
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @param pan {float} the pan position
 * @param tilt {float} the tilt position
 * @param zoom {float} the zoom position
 * @throws {OnvifError} kind `"onvif"` for a position out of range, a bad
 *   token, or as `call` (`ter:SpaceNotSupported` from a head without the
 *   generic space, `ter:InvalidPosition` from one that reads it otherwise)
 */
export func absoluteMove(
    dev as Device,
    profile as string,
    pan as float,
    tilt as float,
    zoom as float) {
    checkRange($pan, -1.0, 1.0, "a pan position");
    checkRange($tilt, -1.0, 1.0, "a tilt position");
    checkRange($zoom, 0.0, 1.0, "a zoom position");
    def op as xml.Value init xml.append(
        ptzOp("AbsoluteMove", $profile),
        vector("tptz:Position", "Position", $pan, $tilt, $zoom, true));
    request($dev, "ptz", "AbsoluteMove", $op);
}

/**
 * Move by an amount from where the head is (`RelativeMove`), in the
 * generic translation spaces (`TranslationGenericSpace`, named in the
 * request): each -1.0 to 1.0. A zoom of 0.0 is left out. No `Speed` is sent.
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @param pan {float} the pan step
 * @param tilt {float} the tilt step
 * @param zoom {float} the zoom step
 * @throws {OnvifError} kind `"onvif"` for a step out of range, a bad token,
 *   or as `call`
 */
export func relativeMove(
    dev as Device,
    profile as string,
    pan as float,
    tilt as float,
    zoom as float) {
    checkRange($pan, -1.0, 1.0, "a pan step");
    checkRange($tilt, -1.0, 1.0, "a tilt step");
    checkRange($zoom, -1.0, 1.0, "a zoom step");
    def op as xml.Value init xml.append(
        ptzOp("RelativeMove", $profile),
        vector("tptz:Translation", "Translation", $pan, $tilt, $zoom, $zoom != 0.0));
    request($dev, "ptz", "RelativeMove", $op);
}

/**
 * Stop every PTZ movement of a profile (`Stop`, pan, tilt and zoom).
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @throws {OnvifError} kind `"onvif"` for a bad token or as `call`
 */
export func stopMove(dev as Device, profile as string) {
    def op as xml.Value init ptzOp("Stop", $profile);
    $op = xml.append($op, textElement(NS_PTZ, "tptz:PanTilt", "true"));
    $op = xml.append($op, textElement(NS_PTZ, "tptz:Zoom", "true"));
    request($dev, "ptz", "Stop", $op);
}

/**
 * A coordinate attribute from a reply, or 0.0 when it is missing.
 *
 * @param node {xml.Value} the element holding the vector
 * @param path {string} the path to `PanTilt` or `Zoom`
 * @param name {string} `x` or `y`
 * @param a {Answer} the answer, for its status
 * @return {float} the coordinate
 */
func coordinate(node as xml.Value, path as string, name as string, a as Answer) {
    if (not xml.has($node, $path)) {
        return 0.0;
    }
    def text as string init attrOf(xml.get($node, $path), $name);
    if ($text == "") {
        return 0.0;
    }
    return floatOf($text, regex.replace('\*:', $path, "") + " " + $name, $a);
}

/**
 * Where the head points and whether it moves (`GetStatus`).
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @return {PtzStatus} the status
 * @throws {OnvifError} kind `"onvif"` for a bad token, a malformed position,
 *   or as `call`
 */
export func ptzStatus(dev as Device, profile as string) {
    def a as Answer init request($dev, "ptz", "GetStatus", ptzOp("GetStatus", $profile));
    if (not xml.has($a.body, "*:PTZStatus")) {
        failStatus("GetStatus: the reply has no PTZStatus", $a.status);
    }
    def s as xml.Value init xml.get($a.body, "*:PTZStatus");
    return PtzStatus{
        pan: coordinate($s, "*:Position/*:PanTilt", "x", $a),
        tilt: coordinate($s, "*:Position/*:PanTilt", "y", $a),
        zoom: coordinate($s, "*:Position/*:Zoom", "x", $a),
        panTiltMoving: textAt($s, "*:MoveStatus/*:PanTilt") == "MOVING",
        zoomMoving: textAt($s, "*:MoveStatus/*:Zoom") == "MOVING",
        error: clean(textAt($s, "*:Error")),
        utcTime: clean(textAt($s, "*:UtcTime"))
    };
}

/**
 * The stored positions of a profile (`GetPresets`).
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @return {list of Preset} the presets
 * @throws {OnvifError} kind `"onvif"` for a bad token, a preset without a
 *   token, or as `call`
 */
export func presets(dev as Device, profile as string) {
    def a as Answer init request($dev, "ptz", "GetPresets", ptzOp("GetPresets", $profile));
    def out as list of Preset init [];
    for (def p in xml.findAll($a.body, "*:Preset")) {
        def token as string init attrOf($p, "token");
        if ($token == "" or len($token) > MAX_TOKEN) {
            failStatus("GetPresets: a preset has no token or one over 64 characters", $a.status);
        }
        $out[] = Preset{
            token: $token,
            name: textAt($p, "*:Name"),
            pan: coordinate($p, "*:PTZPosition/*:PanTilt", "x", $a),
            tilt: coordinate($p, "*:PTZPosition/*:PanTilt", "y", $a),
            zoom: coordinate($p, "*:PTZPosition/*:Zoom", "x", $a)
        };
    }
    return $out;
}

/**
 * Move to a stored position (`GotoPreset`).
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @param preset {string} the preset token
 * @throws {OnvifError} kind `"onvif"` for a bad token, or as `call`
 *   (`ter:InvalidArgVal` / `ter:NoToken` for an unknown preset)
 */
export func gotoPreset(dev as Device, profile as string, preset as string) {
    checkToken($preset, "preset token");
    def op as xml.Value init xml.append(
        ptzOp("GotoPreset", $profile),
        textElement(NS_PTZ, "tptz:PresetToken", $preset));
    request($dev, "ptz", "GotoPreset", $op);
}

/**
 * Store the current position as a new preset (`SetPreset`).
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @param name {string} the preset's name, 1 to 64 characters
 * @return {string} the new preset's token
 * @throws {OnvifError} kind `"onvif"` for a bad token or name, or as `call`
 *   (`ter:PresetExist` for a name in use, `ter:TooManyPresets`)
 */
export func setPreset(dev as Device, profile as string, name as string) {
    checkToken($name, "preset name");
    def op as xml.Value init xml.append(
        ptzOp("SetPreset", $profile),
        textElement(NS_PTZ, "tptz:PresetName", $name));
    def a as Answer init request($dev, "ptz", "SetPreset", $op);
    def token as string init requiredText($a.body, "*:PresetToken", $a);
    if ($token == "" or len($token) > MAX_TOKEN) {
        failStatus("SetPreset: the preset token is empty or over 64 characters", $a.status);
    }
    return $token;
}

/**
 * Delete a preset (`RemovePreset`).
 *
 * @param dev {Device} the device, after `connect`
 * @param profile {string} the profile token
 * @param preset {string} the preset token
 * @throws {OnvifError} kind `"onvif"` for a bad token, or as `call`
 */
export func removePreset(dev as Device, profile as string, preset as string) {
    checkToken($preset, "preset token");
    def op as xml.Value init xml.append(
        ptzOp("RemovePreset", $profile),
        textElement(NS_PTZ, "tptz:PresetToken", $preset));
    request($dev, "ptz", "RemovePreset", $op);
}
