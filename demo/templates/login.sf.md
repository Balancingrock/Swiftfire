---
layout: page
title: Login
---
<form action="/command/login" method="post">
	<div style="display:flex; justify-content:center; margin-bottom:50px;">
		<div style="margin-left:auto; margin-right:auto;">
			<p>.show($requestinfo!.PreviousAttemptMessage)</p>
			<p style="margin-bottom:0px">Name:</p>
			<input type="text" name="LoginName" value="" autofocus><br>
			<p style="margin-bottom:0px">Password:</p>
			<input type="password" name="LoginPassword" value=""><br><br>
			<input style="width:100%" type="submit" value="Login">
			<p><a href="/template/register.sf.html">Register</a> - <a href="/template/register.sf.html">Forgot password?</a></p>
		</div>
	</div>
</form>