#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
#
# onvif overrides the shared example runner.
#
# The examples talk to a camera on the local network (discover.j sends a
# WS-Discovery multicast Probe), and CI has none, so running them would only
# test the network of the build machine. CI checks that each one still
# parses against the current language and module surface; `jennifer lint`
# covers them too, in the test workflow, and reaches undefined calls. The
# suite tests every call against a loopback fake with recorded replies.
set -euo pipefail
cd "$(dirname "$0")/.."
exec env EXAMPLES_SKIP_RUN=1 tools/check-examples-shared.sh
