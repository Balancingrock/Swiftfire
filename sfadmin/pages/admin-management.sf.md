---
layout: page
title: Server Admin Management
menuInclude: yes
menuTopTitle: Admin
menuTopIndex: 2
menuSubTitle: Management
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
        .for(accounts)
        	.if($account.uuid, equal, $info.uuid)
        	    <tr>
                    <td><p class="half-margins-no-padding">.show($info.name)</p></td>
                    <td></td>
                    <td>
                        <form method="post" action="/serveradmin/sfcommand/SetNewPassword">
                            <input type="hidden" name="uuid" value=".show($info.uuid)">
                            <input type="text" name="Password" value="">
                            <input type="submit" value="Set New Password">
                        </form>
                    </td>
                </tr>
        	.else()
                <tr>
                    <td><p class="half-margins-no-padding">.show($info.name)</p></td>
                    <td>
                        <form method="post" action="/serveradmin/sfcommand/ConfirmDeleteAccount">
                            <button type="submit" name="name" value=".show($info.name)">Delete</button>
                        </form>
                    </td>
                    <td>
                        <form method="post" action="/serveradmin/sfcommand/SetNewPassword">
                            <input type="hidden" name="uuid" value=".show($info.uuid)">
                            <input type="text" name="Password" value="">
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
<form action="/serveradmin/sfcommand/CreateAdmin" method="post">
	<div style="display:flex; flex-direction:column; justify-content:center;">
		<table class="centered outlined-table table-cell-margins">
			<tr>
				<td>
					<span style="margin-top: 4px; margin-right: 4px">Admin ID: </span>
				</td>
				<td>
					<input type="text" name="ID" value="" style="text-align:center;">
				</td>
			</tr>
			<tr>
				<td>
					<span style="margin-top: 4px; margin-right: 4px">Password: </span>
				</td>
				<td>
					<input type="text" name="Password" value="" style="text-align:center;">
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
