---
layout: page
title: "Domain: .show($request.domain-name)"
---
## Administrator
{: .text-centered}

<div style="display:flex">
	<div style="background-color:#f0f0f0; border: 2px solid lightgray; margin-left:auto; margin-right:auto;">
		<form action="/serveradmin/sfcommand/SetDomainAdminPassword" method="post">
			<input type="hidden" name="domain-name" value=".show($request.domain-name)">
			<table>
				<tr>
					<td>Domain admin:</td>
					<td><input type="text" name="ID" value=""></td>
					<td></td>
				</tr>
				<tr>
					<td>(New) Password:</td>
					<td><input type="text" name="Password" value=""></td>
					<td><input type="submit" value="Create Admin or Change Password"></td>
				</tr>
			</table>
		</form>
	</div>
</div>

## Parameters
{: .text-centered}

<div class="domain-details-table">
	<table style="border: collapse">
		<thead>
			<tr>
				<th text-align="left">Parameter</th>
				<th text-align="center">Value</th>
				<th text-align="left">Description</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td>Root:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="root">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, root)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>The root directory containing the main entry (index file) of the website</td>
			</tr>
			<tr>
				<td>Enabled:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="enabled">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, enabled)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>The domain is enabled when set to 'true', disabled otherwise</td>
			</tr>
			<tr>
				<td>SF Resources:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="sf-resources">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, sf-resources)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>(Optional) The directory containing resources for Swiftfire, see documentation</td>
			</tr>
			<tr>
				<td>Access Log:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="access-log-enabled">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, access-log-enabled)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>Generate a log of all clients when 'true'</td>
			</tr>
			<tr>
				<td>404 Log:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="404-log-enabled">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, 404-log-enabled)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>Generate a log of all URL that resulted in a 404 error when 'true'</td>
			</tr>
			<tr>
				<td>Session Log:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="session-log-enabled">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, session-log-enabled)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>Generate a log of all sessions when 'true'</td>
			</tr>
			<tr>
				<td>Session timeout:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="session-timeout">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, session-timeout)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>A session is considered expired when inactive for this long (in seconds)</td>
			</tr>
			<tr>
				<td>PHP Path:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="php-path">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, php-path)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>(Optional) Enable PHP by setting the path to the interpreter</td>
			</tr>
			<tr>
				<td>PHP Options:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="php-options">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, php-options)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>(Optional) Options that will be sent to the PHP interpreter</td>
			</tr>
			<tr>
				<td>PHP Map Index:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="php-map-index">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, php-map-index)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>Maps index requests to include index.php and index.sf.php</td>
			</tr>
			<tr>
				<td>PHP Map All:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="php-map-all">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, php-map-all)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>Allows to map *.html to *.php</td>
			</tr>
			<tr>
				<td>PHP Timeout:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="php-timeout">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, php-timeout)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>Timeout for PHP processing (in mSec)</td>
			</tr>
			<tr>
				<td>Foreward URL:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="foreward-url">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, foreward-url)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>(Optional) Forwards all incoming traffic to this url</td>
			</tr>
			<tr>
				<td>Comments Auto Approval Threshold:</td>
				<td>
					<form method="post" action="/serveradmin/sfcommand/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="comment-auto-approval-threshold">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, comment-auto-approval-threshold)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>User comments will be approved automatically after this many approved comments</td>
			</tr>
		</tbody>
	</table>
</div>

<div class="line"></div>

## Telemetry
{: .text-centered}

.sf-domainTelemetryTable()

<div class="line"></div>

## Blacklist
{: .text-centered}

.sf-domainBlacklistTable()

<div class="line"></div>

## Services
{: .text-centered}

The services marked 'used' are currently in use, select or deselect as necessary. The services are executed in top to bottom order. To change the order, renumber as necessary.
{: .text-centered}

.sf-domainServicesTable()
