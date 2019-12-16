---
layout: page
title: "Domain: .show($request.domain-name)"
---
## Telemetry
{: .text-centered}

<table class="domain-telemetry-table">
    <thead>
        <tr>
        	<th>Name</th><th>Value</th><th>Description</th>
        </tr>
    </thead>
    <tbody>
    	.for(domain-telemetry, $request.domain-name)
            <tr>
                <td class="table-column-name">.show($info.named-value-protocol-name)</td>
                <td class="table-column-value">.show($info.named-value-protocol-value)</td>
                <td class="table-column-description">.show($info.named-value-protocol-about)</td>
            </tr>
        .end(for)
    </tbody>
</table>

## Domain Admin
{: .text-centered}

<div style="display:flex">
	<div style="background-color:#f0f0f0; border: 2px solid lightgray; margin-left:auto; margin-right:auto;">
		<form action="/serveradmin/command/set-domain-admin-password" method="post">
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

## Root directory
{: .text-centered}

<div class="domain-details-table">
	<table class="default-table">
		<thead>
			<tr>
				<th text-align="left" style="width:160px">Parameter</th>
				<th text-align="center" style="width:260px">Value</th>
				<th text-align="left">Description</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td>Root:</td>
				<td>
					<form method="post" action="/serveradmin/command/update-domain-parameter">
						<input type="hidden" name="parameter-name" value="root">
						<input type="hidden" name="domain-name" value=".show($request.domain-name)">
            			<input type="text" name="parameter-value" value=".domainParameter($request.domain-name, root)">
            			<input type="submit" value="Update">
					</form>
				</td>
				<td>The root directory containing the main entry (index file) of the website</td>
			</tr>
		</tbody>
	</table>
</div>
