---
layout: page
title: Server Admin Management
menuInclude: yes
menuTopTitle: Admin
menuTopIndex: 2
menuSubTitle: Management
#
# Input:
#   $account.uuid: The UUID string of the server administrator account that is logged in
#	server-accounts
#		$info.uuid: The UUID string of a server-account
#		$info.name: The name of a server server-account
#
# Output:
#	URL(POST): /serveradmin/command/set-new-password
#		uuid: The uuid string of server account for which a new password must be set
#		password: The new password to be used
#
#	URL(POST): /serveradmin/command/confirm-delete-account
#		name: The name of the account to be deleted
#       uuid: The uuid string of the account to be deleted
#
# 	URL(POST): /serveradmin/command/create-admin
#		name: The name of the server account to be created
#		password: The password for the server account to be created
#		
---
<div class="center-content">
	<table class="default-table">
		<thead>
            <tr>
                <th>Account ID</th>
                <th></th>
                <th></th>
            </tr>
        </thead>
        <tbody>
        .for(server-accounts)
        	.if($account.uuid, equal, $info.uuid)
        	    <tr>
                    <td><p class="half-margins-no-padding">.show($info.name)</p></td>
                    <td></td>
                    <td>
                        <form method="post" action="/serveradmin/command/set-new-password">
                            <input type="hidden" name="uuid" value=".show($info.uuid)">
                            <input type="text" name="password" value="">
                            <input type="submit" value="Set New Password">
                        </form>
                    </td>
                </tr>
        	.else()
                <tr>
                    <td><p class="half-margins-no-padding">.show($info.name)</p></td>
                    <td>
                        <form method="post" action="/serveradmin/command/confirm-delete-account">
                        	<input type="hidden" name="name" value=".show($info.name)">
                            <button type="submit" name="uuid" value=".show($info.uuid)">Delete</button>
                        </form>
                    </td>
                    <td>
                        <form method="post" action="/serveradmin/command/set-new-password">
                            <input type="hidden" name="uuid" value=".show($info.uuid)">
                            <input type="text" name="password" value="">
                            <input type="submit" value="Set New Password">
                        </form>
                    </td>
                </tr>
        	.end(if)
        .end(for)
		</tbody>
	</table>
</div>

<h1 style="text-align: center;">Create New Admin Account</h1>
<form action="/serveradmin/command/create-admin" method="post">
	<div style="display:flex; flex-direction:column; justify-content:center;">
		<table class="centered outlined-table table-cell-margins">
			<tr>
				<td>
					<span style="margin-top: 4px; margin-right: 4px">Admin ID: </span>
				</td>
				<td>
					<input type="text" name="name" value="" style="text-align:center;">
				</td>
			</tr>
			<tr>
				<td>
					<span style="margin-top: 4px; margin-right: 4px">Password: </span>
				</td>
				<td>
					<input type="text" name="password" value="" style="text-align:center;">
				</td>
			</tr>
		</table>
		<div class="center-content">
			<div style="margin-top: 4px;">
				<input type="submit" value="Create New Admin">
			</div>
		</div>
	</div>
</form>
