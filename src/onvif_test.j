# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * White-box tests: jennifer test src/onvif_test.j
 *
 * No test needs a camera. A fake on 127.0.0.1 (`startFake` in the core
 * overlay) answers each SOAP request by its path and operation with a reply
 * recorded from onvif_simple_server (fixtures/simulator_test.j) or published
 * from real cameras (fixtures/vendors_test.j), and records what it got.
 * WS-Discovery runs against a loopback UDP fake. The topic overlays are
 * fragments spliced in here, not standalone suites.
 */
use httpd;
use task;
use testing;

include "topics/fixtures/simulator_test.j";
include "topics/fixtures/vendors_test.j";
include "topics/core_test.j";
include "topics/device_test.j";
include "topics/discovery_test.j";
include "topics/media_test.j";
include "topics/ptz_test.j";
include "topics/imaging_test.j";
include "topics/events_test.j";
