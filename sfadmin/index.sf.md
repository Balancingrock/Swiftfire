---
layout: default
#
# Input:
# 	$server-telemetry.ServerVersion
# 	$server-parameter.HttpServicePortNumber
# 	$server-parameter.HttpServerStatus
# 	$server-parameter.HttpsServicePortNumber
# 	$server-parameter.HttpsServerStatus
# 	$server-parameter.ServerAdminSiteRoot
#
# Output:
#	URL: /serveradmin/command/restart
#
#	URL: /serveradmin/command/quit
#
---
{:.text-centered}
### Swiftfire status as of: .timestamp()

<div class="status-table" style="overflow-x:auto;" markdown="1">

<table>
	<thead>
		<tr>
			<th>Item</th><th>Value</th><th>Status</th><th>Action</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>Swiftfire Version</td>
			<td>.show($server-telemetry.ServerVersion)</td>
			<td></td>
			<td>
				<div style="display:flex">
					<form method="post" action="/serveradmin/command/restart">
						<button type="submit">Restart</button>
					</form>
					<form method="post" action="/serveradmin/command/quit" style="margin-left:2em">
						<button type="submit">Quit</button>
					</form>
				</div>
			</td>
		</tr>
		<tr>
			<td>HTTP Port</td>
			<td>.show($server-parameter.HttpServicePortNumber)</td>
			<td>.show($server-telemetry.HttpServerStatus)</td>
			<td></td>
		</tr>
		<tr>
			<td>HTTPS Port</td>
			<td>.show($server-parameter.HttpsServicePortNumber)</td>
			<td>.show($server-telemetry.HttpsServerStatus)</td>
			<td></td>
		</tr>
	</tbody>
</table>

</div>

{:.text-centered}
Server admin site root: <span style="background-color:#eee">.show($server-parameter.ServerAdminSiteRoot)</span>
