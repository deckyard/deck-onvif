# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0
# pragma-jennifer-capability: net

/**
 * IP cameras and NVRs over ONVIF, the SOAP web services every vendor that
 * implements the profiles (S streaming, T advanced streaming, G recording)
 * offers: find devices on the LAN with WS-Discovery, read the device's
 * identity, clock and services, list the media profiles with their RTSP
 * stream and snapshot addresses and fetch a snapshot, move a PTZ head and
 * recall presets, set brightness and focus, and pull events from a
 * pull-point subscription. `call` reaches any other operation.
 *
 * Requests are SOAP 1.2 over the bundled `soap` module. Each one carries a
 * WS-Security `UsernameToken` with a `PasswordDigest`, built per request
 * with a fresh nonce and a `Created` time corrected by the camera's clock
 * offset, which `connect` reads first; the password itself is never sent.
 * A camera that also wants HTTP Digest gets it. Plain `http`, ONVIF's norm
 * on a LAN, is allowed to private, link-local and loopback addresses;
 * anything else needs `withPlainHttp`.
 *
 * A request the camera refused, or that failed, throws `OnvifError` (kind
 * `"onvif"`) with the HTTP `status` and the SOAP fault's `code` and
 * `subcode` (`ter:NotAuthorized`, `ter:InvalidArgVal`, ...). A reply over a
 * cap is kind `"limit"`, a camera that does not answer in time
 * `"timeout"`, one that closes the connection `"closed"`.
 *
 * | topic | covers |
 * | --- | --- |
 * | `core` | `Device`, settings, auth, the clock, the exchange, errors, `call` |
 * | `device` | `connect`, device information, services, scopes, time, reboot |
 * | `discovery` | WS-Discovery `Probe` and `ProbeMatches` |
 * | `media` | profiles, stream and snapshot URIs, snapshots (Media and Media2) |
 * | `ptz` | continuous, absolute and relative moves, stop, status, presets |
 * | `imaging` | imaging settings, brightness, focus |
 * | `events` | pull-point subscriptions: create, pull, renew, unsubscribe |
 *
 * Out of scope: RTSP and video (the deck returns stream URLs for a player),
 * push notifications (they need a listening endpoint), Profile M analytics.
 *
 * @module onvif
 * @see https://www.onvif.org/profiles/specifications/
 * @example
 *   def cam as onvif.Device init onvif.connect(
 *       onvif.device("http://192.168.1.64/onvif/device_service", "admin", $password));
 *   for (def p in onvif.profiles($cam)) {
 *       io.printf("%s %s\n", $p.name, onvif.streamUri($cam, $p.token).address);
 *   }
 */
use binary;
use convert;
use crypto;
use encoding;
use hash;
use lists;
use maps;
use net;
use regex;
use strings;
use time;
use uuid;
use xml;

import "http.j" as http;
import "ipnet.j" as ipnet;
import "soap.j" as soap;
import "uri.j" as uri;

include "topics/core.j";
include "topics/device.j";
include "topics/discovery.j";
include "topics/media.j";
include "topics/ptz.j";
include "topics/imaging.j";
include "topics/events.j";
