# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.27.0

# onvif - Imaging: settings, brightness, focus. Spliced into onvif.j via
# include.

/**
 * The imaging settings of a video source, as `GetImagingSettings` reports
 * them. A number the device left out is not in `values`.
 *
 * @field values {map of string to float} `Brightness`, `ColorSaturation`,
 *   `Contrast`, `Sharpness`, as the device reports them
 * @field focusMode {string} `AUTO` or `MANUAL`; "" when not reported
 * @field irCutFilter {string} `ON`, `OFF` or `AUTO`; "" when not reported
 */
export def struct ImagingSettings {
    values as map of string to float,
    focusMode as string,
    irCutFilter as string
};

/**
 * A device's range for a setting.
 *
 * @field min {float} the lowest value
 * @field max {float} the highest value
 */
export def struct Range {
    min as float,
    max as float
};

/**
 * An Imaging operation element with its video source token.
 *
 * @param operation {string} the operation's local name
 * @param source {string} the video source token
 * @return {xml.Value} the element
 */
func imagingOp(operation as string, source as string) {
    checkToken($source, "video source token");
    return xml.append(
        xml.elementNS(NS_IMAGING, "timg:" + $operation),
        textElement(NS_IMAGING, "timg:VideoSourceToken", $source));
}

/**
 * The imaging settings of a video source (`GetImagingSettings`).
 *
 * @param dev {Device} the device, after `connect`
 * @param source {string} the video source token (`Profile.videoSource`)
 * @return {ImagingSettings} the settings
 * @throws {OnvifError} kind `"onvif"` for a bad token, a malformed number,
 *   a device without imaging, or as `call`
 */
export func imagingSettings(dev as Device, source as string) {
    def a as Answer init request(
        $dev,
        "imaging",
        "GetImagingSettings",
        imagingOp("GetImagingSettings", $source));
    if (not xml.has($a.body, "*:ImagingSettings")) {
        failStatus("GetImagingSettings: the reply has no ImagingSettings", $a.status);
    }
    def s as xml.Value init xml.get($a.body, "*:ImagingSettings");
    def out as ImagingSettings init ImagingSettings{
        values: {},
        focusMode: clean(textAt($s, "*:Focus/*:AutoFocusMode")),
        irCutFilter: clean(textAt($s, "*:IrCutFilter"))
    };
    for (def name in ["Brightness", "ColorSaturation", "Contrast", "Sharpness"]) {
        def text as string init textAt($s, "*:" + $name);
        if ($text != "") {
            $out.values[$name] = floatOf($text, $name, $a);
        }
    }
    return $out;
}

/**
 * A `Min` / `Max` pair from a reply.
 *
 * @param node {xml.Value} the element holding them
 * @param what {string} the setting, for the message
 * @param a {Answer} the answer, for its status
 * @return {Range} the range
 */
func rangeOf(node as xml.Value, what as string, a as Answer) {
    def r as Range init Range{
        min: floatOf(requiredText($node, "*:Min", $a), $what + " Min", $a),
        max: floatOf(requiredText($node, "*:Max", $a), $what + " Max", $a)
    };
    if ($r.min > $r.max) {
        failStatus(plain(xml.localName($a.body)) + ": " + $what + " Min is above Max", $a.status);
    }
    return $r;
}

/**
 * The brightness range a video source accepts (`GetOptions`).
 *
 * @param dev {Device} the device, after `connect`
 * @param source {string} the video source token
 * @return {Range} the range
 * @throws {OnvifError} kind `"onvif"` for a source without a brightness
 *   setting, or as `imagingSettings`
 */
export func brightnessRange(dev as Device, source as string) {
    def a as Answer init request($dev, "imaging", "GetOptions", imagingOp("GetOptions", $source));
    if (not xml.has($a.body, "*:ImagingOptions/*:Brightness")) {
        failStatus("GetOptions: the video source has no brightness setting", $a.status);
    }
    return rangeOf(xml.get($a.body, "*:ImagingOptions/*:Brightness"), "Brightness", $a);
}

/**
 * Set the brightness of a video source (`SetImagingSettings`, kept across
 * restarts). The value is checked against `brightnessRange` first.
 *
 * @param dev {Device} the device, after `connect`
 * @param source {string} the video source token
 * @param value {float} the brightness, in the device's range
 * @throws {OnvifError} kind `"onvif"` for a value out of the range, or as
 *   `imagingSettings`
 */
export func setBrightness(dev as Device, source as string, value as float) {
    def r as Range init brightnessRange($dev, $source);
    checkRange($value, $r.min, $r.max, "the brightness");
    def settings as xml.Value init xml.append(
        xml.elementNS(NS_IMAGING, "timg:ImagingSettings"),
        textElement(NS_SCHEMA, "tt:Brightness", floatText($value)));
    setImaging($dev, $source, $settings);
}

/**
 * Send `SetImagingSettings` with ForcePersistence.
 *
 * @param dev {Device} the device
 * @param source {string} the video source token
 * @param settings {xml.Value} the `timg:ImagingSettings` element
 */
func setImaging(dev as Device, source as string, settings as xml.Value) {
    def op as xml.Value init imagingOp("SetImagingSettings", $source);
    $op = xml.append($op, $settings);
    $op = xml.append($op, textElement(NS_IMAGING, "timg:ForcePersistence", "true"));
    request($dev, "imaging", "SetImagingSettings", $op);
}

/**
 * Switch autofocus on or off (`SetImagingSettings`, `Focus/AutoFocusMode`).
 *
 * @param dev {Device} the device, after `connect`
 * @param source {string} the video source token
 * @param mode {string} `AUTO` or `MANUAL`
 * @throws {OnvifError} kind `"onvif"` for another mode, or as
 *   `imagingSettings`
 */
export func setFocusMode(dev as Device, source as string, mode as string) {
    if ($mode != "AUTO" and $mode != "MANUAL") {
        fail("a focus mode is AUTO or MANUAL, got " + shown($mode));
    }
    def focus as xml.Value init xml.append(
        xml.elementNS(NS_SCHEMA, "tt:Focus"),
        textElement(NS_SCHEMA, "tt:AutoFocusMode", $mode));
    setImaging(
        $dev,
        $source,
        xml.append(xml.elementNS(NS_IMAGING, "timg:ImagingSettings"), $focus));
}

/**
 * The speed range of continuous focus moves (`GetMoveOptions`).
 *
 * @param dev {Device} the device, after `connect`
 * @param source {string} the video source token
 * @return {Range} the range
 * @throws {OnvifError} kind `"onvif"` for a source without continuous focus
 *   moves, or as `imagingSettings`
 */
export func focusSpeedRange(dev as Device, source as string) {
    def a as Answer init request(
        $dev,
        "imaging",
        "GetMoveOptions",
        imagingOp("GetMoveOptions", $source));
    if (not xml.has($a.body, "*:MoveOptions/*:Continuous/*:Speed")) {
        failStatus("GetMoveOptions: the video source has no continuous focus move", $a.status);
    }
    return rangeOf(xml.get($a.body, "*:MoveOptions/*:Continuous/*:Speed"), "Speed", $a);
}

/**
 * Start a continuous focus move (`Move`, `Focus/Continuous`) until
 * `focusStop`: a positive speed focuses farther, a negative one nearer. The
 * speed is checked against `focusSpeedRange` first; autofocus usually has
 * to be off (`setFocusMode(..., "MANUAL")`).
 *
 * @param dev {Device} the device, after `connect`
 * @param source {string} the video source token
 * @param speed {float} the speed, in the device's range
 * @throws {OnvifError} kind `"onvif"` for a speed out of the range, or as
 *   `imagingSettings`
 */
export func focusMove(dev as Device, source as string, speed as float) {
    def r as Range init focusSpeedRange($dev, $source);
    checkRange($speed, $r.min, $r.max, "a focus speed");
    def continuous as xml.Value init xml.append(
        xml.elementNS(NS_SCHEMA, "tt:Continuous"),
        textElement(NS_SCHEMA, "tt:Speed", floatText($speed)));
    def op as xml.Value init xml.append(
        imagingOp("Move", $source),
        xml.append(xml.elementNS(NS_IMAGING, "timg:Focus"), $continuous));
    request($dev, "imaging", "Move", $op);
}

/**
 * Stop a focus move (`Stop`).
 *
 * @param dev {Device} the device, after `connect`
 * @param source {string} the video source token
 * @throws {OnvifError} kind `"onvif"` for a bad token, or as `call`
 */
export func focusStop(dev as Device, source as string) {
    request($dev, "imaging", "Stop", imagingOp("Stop", $source));
}
