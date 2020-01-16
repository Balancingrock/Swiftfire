---
layout: page
title: Domain Management
#
# Input:
#	server-domains
#		$info.domain-name
#		domain-aliases
#			$info.alias
#
# Output:
#	URL(POST): /serveradmin/command/delete-alias
#		alias-name: The alias name to be removed
#
#	URL(POST): /serveradmin/command/create-alias
#		domain-name: The name of the domain for which to create a new alias
#		alias-name: The name for the new alias
#
#	URL(POST): /serveradmin/pages/delete-domain.sf.html
#		domain-name: The name of the domain to be removed
#
#	URL(POST): /serveradmin/pages/domain.sf.html
#		domain-name: The name of the domain to set up
#	
#	URL(POST): /serveradmin/command/create-domain
#		domain-name: The name of the new domain
#		domain-admin-id: The name of the domain admin
#		domain-admin-password: The password for the domain admin
#		domain-root: The root address of the new domain
#
---
<div class="center-content">
	<div class="domains-list">
	.for(server-domains)
		<table class="domains-table">
            <thead>
            	<tr>
            		<th>Domain:</th>
            		<th>.show($info.domain-name)</th>
            	</tr>
            </thead>
            <tbody>
	  			.for(domain-aliases, $info.domain-name)
  					<tr>
	  				.if($info.for-index, equal, $info.for-start-index)
    	        		<td>Aliases:</td>
    	        	.else()
                    	<td></td>
                    .end(if)
            			<td>
            				<div>
                       			<p>.show($info.alias)</p>
                    			<form method="post" action="/serveradmin/command/delete-alias">
                        			<input type="hidden" name="alias" value=".show($info.alias!)">
                        			<button type="submit">Delete</button>
                    			</form>
                     		</div>
                		</td>
            		</tr>
	  			.end(for-aliases)
	  			<tr>
                    <td></td>
                    <td>
                        <form method="post" action="/serveradmin/command/create-alias">
                            <input type="hidden" name="domain" value=".show($info.domain-name)">
                            <input type="text" name="alias" value="">
                            <button type="submit">Create Alias</button>
                        </form>
                    </td>
                </tr>
            </tbody>
        </table>
        <form method="post" style="display:flex; justify-content:space-between; width:100%; margin-bottom:30px;">
            <button type="submit" name="domain" value=".show($info.domain-name)" formaction="/serveradmin/pages/delete-domain.sf.html">Delete Domain</button>
            <button type="submit" name="domain" value=".show($info.domain-name)" formaction="/serveradmin/pages/domain.sf.html">Domain Setup</button>
        </form>
	.end(for-domains)
	</div>
</div>

<form action="/serveradmin/command/create-domain" method="post">
	<div class="center-content">
		<div style="display:flex; flex-direction:column; justify-content:center;">
			<div style="display:flex; flex-direction:column; align-items:flex-end">
				<table class="centered outlined-table table-cell-margins">
					<tr>
						<td><span>Add domain with name:</span></td>
						<td><input type="text" name="domain-name" value=""></td>
					</tr>
					<tr>
						<td><span>Domain Admin ID:</span></td>
						<td><input type="text" name="domain-admin-id" value=""></td>
					</tr>
					<tr>
						<td><span>Domain Admin Password:</span></td>
						<td><input type="text" name="domain-admin-password" value=""></td>
					</tr>
					<tr>
						<td><span>Website Root Directory:</span></td>
						<td><input type="text" name="domain-root" value=""></td>
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
