---
layout: page
title: Server Admin Login
menuInclude: yes
menuTopTitle: Admin
menuSubTitle: Login
#
# Input:
#	-
#
# Output:
#	URL(POST): /serveradmin
#		server-admin-login-name: The name of the server admin that wants to log in
#		server-admin-login-password: The password of the server admin that wants to log in
#
---
<form action="/serveradmin" method="post">
<div style="display:flex; justify-content:center; margin-bottom:50px;">
	<div style="margin-left:auto; margin-right:auto;">
		<p style="margin-bottom:0px">Name:</p>
		<input type="text" name="server-admin-login-name" value="" autofocus><br>
		<p style="margin-bottom:0px">Password:</p>
		<input type="password" name="server-admin-login-password" value=""><br><br>
		<input style="width:100%" type="submit" value="Login">
	</div>
</div>
</form>