---
layout: page
title: Domain Management
---
<div class="center-content">.sf-domainsTable()</div>
<form action="/serveradmin/sfcommand/CreateDomain" method="post">
	<div class="center-content">
		<div style="display:flex; flex-direction:column; justify-content:center;">
			<div style="display:flex; flex-direction:column; align-items:flex-end">
				<table class="centered outlined-table table-cell-margins">
					<tr>
						<td><span>Add domain with name:</span></td>
						<td><input type="text" name="DomainName" value=""></td>
					</tr>
					<tr>
						<td><span>Domain Admin ID:</span></td>
						<td><input type="text" name="ID" value=""></td>
					</tr>
					<tr>
						<td><span>Domain Admin Password:</span></td>
						<td><input type="text" name="Password" value=""></td>
					</tr>
				</table>
				<div>
					<div>
						<input type="submit" value="Create Domain">
					</div>
				</div>
			</div>
		</div>
	</div>
</form>

{:.text-centered}
Note: Removing a domain will not remove the associated domain data from the Swiftfire Application Support directory. This has to be done manually by an administrator with sufficient access rights. Re-creating a domain of which the associated domain data is still present will cause a re-appearance of the domain as it was when deleted.