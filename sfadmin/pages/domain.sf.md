---
layout: page
title: Domain - .show($requestInfo.DomainName)
---
## Administrator
{: .text-centered}

<div style="display:flex">
	<div style="background-color:#f0f0f0; border: 2px solid lightgray; margin-left:auto; margin-right:auto;">
		<form action="/serveradmin/sfcommand/SetDomainAdminPassword" method="post">
			<input type="hidden" name="DomainName" value=".show($requestInfo.DomainName)">
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

| Parameter | Value | Description |
| :--- | :---: | :--- |
| Root: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", root, "", Update) | The root directory containing the main entry (index file) of the website |
| Enabled: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", enabled, "", Update) | The domain is enabled when set to 'true', disabled otherwise |
| SF Resources: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", sfresources, "", Update) | (Optional) The directory containing resources for Swiftfire, see documentation |
| Access Log: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", accesslogenabled, "", Update) | Generate a log of all clients when 'true' |
| 404 Log: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", 404logenabled, "", Update) | Generate a log of all URL that resulted in a 404 error when 'true' |
| Session log: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", sessionlogenabled, "", Update) | Generate a log of all sessions when 'true' |
| Session timeout: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", sessiontimeout, "", Update) | A session is considered expired when inactive for this long (in seconds) |
| PHP Path: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", phppath, "", Update) | (Optional) Enable PHP by setting the path to the interpreter |
| PHP Options: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", phpoptions, "", Update) | (Optional) Options that will be sent to the PHP interpreter |
| PHP Map Index: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", phpmapindex, "", Update) |  Maps index requests to include index.php and index.sf.php |
| PHP Map All: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", phpmapall, "", Update) | Allows to map *.html to *.php |
| PHP Timeout: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", phptimeout, "", Update) | Timeout for PHP processing (in mSec) |
| Foreward URL: | .sf-postingButtonedInput("/serveradmin/sfcommand/UpdateDomain", forewardurl, "", Update) | (Optional) Forwards all incoming traffic to this url |
{: .domain-details-table}

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
