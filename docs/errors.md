<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Other operations and errors

## `call`

`onvif.call(dev, service, action, body)` sends any operation to a named
service (`onvif.SERVICES`) with the same WS-Security header, HTTP Digest
handling, caps and error mapping, and returns the reply's first Body
element. `action` is the operation's name, appended to the service
namespace, or a whole action URI. Build the body with the `xml` module, in
the service's namespace; read the answer by local name (`*:Name`), since
vendors differ in prefixes.

```jennifer
def op as xml.Value init xml.elementNS(onvif.NS_DEVICE, "tds:GetHostname");
def r as xml.Value init onvif.call($cam, "device", "GetHostname", $op);
io.printf("%s\n", xml.text(xml.get(xml.get($r, "*:HostnameInformation"), "*:Name")));

def set as xml.Value init xml.elementNS(onvif.NS_DEVICE, "tds:SetHostname");
$set = xml.append($set, xml.setText(xml.elementNS(onvif.NS_DEVICE, "tds:Name"), "gate"));
onvif.call($cam, "device", "SetHostname", $set);
```

## `OnvifError`

Every error of kind `"onvif"` is an `onvif.OnvifError`:

| Field | Holds |
|---|---|
| `status` | the HTTP status of the reply; 0 for a local check or a transport failure |
| `code` | the SOAP fault code without prefix: `Sender`, `Receiver`, ...; "" when there was no fault |
| `subcode` | the first subcode: `ter:NAME` in the ONVIF error namespace, `{namespace}NAME` in another |
| `subcodes` | every level, outermost first: `["ter:InvalidArgVal", "ter:NoProfile"]` |
| `reason` | the camera's reason text, printable ASCII, cut to 120 characters |

Common subcodes: `ter:NotAuthorized` (wrong credentials or clocks apart; HTTP
400 on onvif_simple_server, 401 elsewhere), `ter:InvalidArgVal` with a
second level (`ter:NoProfile`, `ter:NoToken`, `ter:NoSource`,
`ter:InvalidStreamSetup`, `ter:InvalidPosition`), `ter:ActionNotSupported`.
Vendors differ: gSOAP firmware answers a 401 with a `Sender` fault without
subcode, Hikvision with an HTML page (`code` ""), Dahua sends some faults
with HTTP 200. Compare `subcode` / `subcodes`, never the message.

A helper that receives a caught error takes `onvif.OnvifError`, not `Error`:

```jennifer
func describe(e as onvif.OnvifError) {
    return $e.subcode + " (HTTP " + convert.toString($e.status) + ")";
}
```

## Generic kinds

| Kind | When |
|---|---|
| `"limit"` | a reply over `maxBytes`, a snapshot over `maxMediaBytes` |
| `"timeout"` | the camera did not answer within the idle timeout |
| `"closed"` | the camera closed the connection mid-answer |
| `"cancelled"` | the task running the call was cancelled |

Their messages start with `onvif: ` and the operation.
