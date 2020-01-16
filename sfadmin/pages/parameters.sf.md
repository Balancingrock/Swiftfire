---
layout: page
title: Parameters
menuInclude: yes
menuTopTitle: Parameters
menuTopIndex: 4
#
# Input:
#	server-parameters
#		$info.named-value-protocol-name
#		$info.named-value-protocol-value
#		$info.named-value-protocol-about
#
# Output:
#	URL(POST): /serveradmin/command/set-server-parameter
#		server-parameter-name: The name of the server parameter
#		server-parameter-value: The value for the server parameter
#
---
<table class="parameter-table">
    <thead>
        <tr>
            <th>Name</th>
            <th>Value</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
	.for(server-parameters)
        <tr>
            <td>.show($info.named-value-protocol-name)</td>
            <td>
                <form method="post" action="/serveradmin/command/set-server-parameter">
                	<input type="hidden" name="server-parameter-name" value=".show($info.named-value-protocol-name)">
                    <input type="text" name="server-parameter-value" value=".show($info.named-value-protocol-value)">
                    <input type="submit" value="Update">
                </form>
            </td>
	        <td>.show($info.named-value-protocol-about)</td>
    	</tr>
	.end()
	</tbody>
</table>
