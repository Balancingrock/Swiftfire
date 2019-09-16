---
layout: default
---
{:.text-centered}
### Swiftfire status as of: .timestamp()

<div class="status-table" style="overflow-x:auto;" markdown="1">

| Item | Value | Status |
| :--- | :---: | :---: |
| Swiftfire Version: | .sf-telemetryValue("ServerVersion") | | .sf-command(Restart) | .sf-command(Quit) |
| HTTP Portnumber: | .sf-parameterValue("HttpServicePortNumber") | .sf-telemetryValue("HttpServerStatus") |
| HTTPS Portnumber: | .sf-parameterValue("HttpsServicePortNumber") | .sf-telemetryValue("HttpsServerStatus") |

</div>

{:.text-centered}
Server admin site root: .sf-parameterValue(ServerAdminSiteRoot)