---
layout: page
title: Server Blacklist
menuInclude: yes
menuTopTitle: Blacklist
menuTopIndex: 6
#
# Input:
#	server-blacklist
#		$info.blacklist-address: The address of a blacklist entry
#		$info.blacklist-action: The action associated with a blacklist entry
#
# Output:
#	URL(POST): /serveradmin/command/update-blacklist
#		address: The address of the blacklist entry to update
#		action: The new action for the associated blacklist address
#
#	URL(POST): /serveradmin/command/remove-from-blacklist
#		address: The address of an entry to be removed from the server blacklist
#
#	URL(POST): /serveradmin/command/add-to-blacklist
#		address: The address for a new blacklist entry
#		action: The action for the new blacklist entry
#
---
{: .text-centered}
Addresses blacklisted here are blacklisted for all domains.

<div class="blacklist-table">
	<table class="server-blacklist-table">
        <thead>
            <tr>
                <th>Address</th>
                <th>Action</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
        .for(server-blacklist)
            <tr>
                <td>.show($info.blacklist-address)</td>
                <td>
                    <form method="post" action="/serveradmin/command/update-blacklist">
                    	<input type="hidden" name="address" value=".show($info.blacklist-address)">
                    	.if($info.blacklist-action, equal, closeConnection)
	                    	<input type="radio" name="action" value="close" checked>
	                    .else()
	                    	<input type="radio" name="action" value="close">
	                    .end()
                    	<span> Close Connection, </span>
                    	.if($info.blacklist-action, equal, send503ServiceUnavailable)
	                    	<input type="radio" name="action" value="503" checked>
	                    .else()
                    		<input type="radio" name="action" value="503">
                    	.end()
                    	<span> 503 Service Unavailable, </span>
                    	.if($info.blacklist-action, equal, send401Unauthorized)
	                    	<input type="radio" name="action" value="401" checked>
	                    .else()
    	                	<input type="radio" name="action" value="401">
    	                .end()
                    	<span> 401 Unauthorized </span>
                    	<input type="submit" value="Update">
                    </form>
                </td>
                <td>
                    <form method="post" action="/serveradmin/command/remove-from-blacklist">
                        <input type="hidden" name="address" value=".show($info.blacklist-address)">
                        <input type="submit" value="Delete">
                    </form>
                </td>
            </tr>
        .end(for)
        </tbody>
    </table>
    <br>
    <form class="server-blacklist-create" method="post" action="/serveradmin/command/add-to-blacklist">
        <div>
            <span>Address: </span>
            <input type="text" name="address" value="">
        </div>
        <div>
            <input type="radio" name="action" value="close" checked>
            <span> Close, </span>
            <input type="radio" name="action" value="503">
            <span> 503 Service Unavailable, </span>
            <input type="radio" name="action" value="401">
            <span> 401 Unauthorized</span>
        </div>
        <div>
            <input type="submit" value="Add to Blacklist">
        </div>
    </form>
</div>
