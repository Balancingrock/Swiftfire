---
layout: page
title: Domain Management
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
	  				.if($info.for-index, equal, $info.for-start-index)
	  					<tr>
    	        			<td>Aliases:</td>
            				<td>
            					<div>
                           			<p>.show($info.alias)</p>
                        			<form method="post" action="/serveradmin/command/delete-alias">
                            			<input type="hidden" name="alias-name" value=".show($info.alias!)">
                            			<button type="submit">Delete</button>
                        			</form>
                        		</div>
                    		</td>
                		</tr>
					.else()
	  					<tr>
                    		<td></td>
                    		<td>
                    			<div>
                            		<p>.show($info.alias)</p>
                            		<form method="post" action="/serveradmin/command/delete-alias">
                                		<button type="submit" name="alias-name" value=".show($info.alias!)">Delete</button>
                            		</form>
                        		</div>
                    		</td>
                		</tr>
                	.end(if)
	  			.end(for-aliases)
	  			<tr>
                    <td></td>
                    <td>
                        <form method="post" action="/serveradmin/command/create-alias">
                            <input type="hidden" name="domain-name" value=".show($info.domain-name)">
                            <input type="text" name="Alias" value="">
                            <button type="submit">Create Alias</button>
                        </form>
                    </td>
                </tr>
            </tbody>
        </table>
        <form method="post" style="display:flex; justify-content:space-between; width:100%; margin-bottom:30px;">
            <button type="submit" name="domain-name" value=".show($info.domain-name)" formaction="/serveradmin/pages/delete-domain.sf.html">Delete Domain</button>
            <button type="submit" name="domain-name" value=".show($info.domain-name)" formaction="/serveradmin/pages/domain.sf.html">Domain Setup</button>
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
