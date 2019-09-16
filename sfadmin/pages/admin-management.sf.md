---
layout: page
title: Server Admin Management
menuInclude: yes
menuTopTitle: Admin
menuTopIndex: 2
menuSubTitle: Management
---
<div class="center-content">.sf-adminTable()</div>
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
