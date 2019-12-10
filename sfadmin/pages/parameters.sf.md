---
layout: page
title: Parameters
menuInclude: yes
menuTopTitle: Parameters
menuTopIndex: 4
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
