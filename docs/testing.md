<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# How the deck is tested

`jennifer test src/onvif_test.j` needs no camera. A fake on 127.0.0.1
answers each SOAP request by its path and operation with a recorded reply
and keeps what it received, so the tests check both sides: what the deck
sends (the signed header, the digest, the body) and how it reads what
cameras answer.

The replies come from two kinds of source:

- **onvif_simple_server** (roleoroleo, commit `7a2e335c`, GPL-3.0), a C
  ONVIF™ server used in camera firmware, built and run in a throwaway
  container on 2026-11-14 and driven by an independent Python client: every
  operation of the deck, the faults (wrong password, unknown profile and
  preset, unknown operation, a pull after unsubscribing), a lighttpd HTTP
  Digest challenge on the snapshot and a WS-Discovery ProbeMatches. The
  server checks the PasswordDigest, so the deck's digest was verified
  against an independent implementation live.
- **Published captures of real cameras**: EZVIZ™ DS-2DE2C400IG-W-W
  (Hikvision™ firmware), Dahua™ DHI-ITC413-PW4D-Z1 and DVC DCN-BF5365 (gSOAP)
  from the fixtures of github.com/2BAD/onvif (MIT), and the traces of the
  ONVIF Application Programmer's Guide 1.0 (an Axis™): other envelope
  prefixes (`env:`, `s:`, `SOAP-ENV:`), Media2 under the prefix `trt2`,
  faults with HTTP 200 and 500, an HTML 401, a subscription address with a
  raw `%`, reference parameters.

The PasswordDigest is checked against the example in the ONVIF Application
Programmer's Guide (6.1.1.3) and a value computed with Python's `hashlib`.
WS-Discovery runs against a loopback UDP fake that answers with the
simulator's recorded ProbeMatches, among junk and a reply to another Probe.
