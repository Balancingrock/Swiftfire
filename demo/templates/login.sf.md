---
layout: page
title: Login
---
<form action="/command/login" method="post">
	<div style="display:flex; flex-direction:column; justify-content:center; margin-bottom:50px;">
		<div style="margin-left:auto; margin-right:auto;">
			<p>.show($requestinfo!.PreviousAttemptMessage)</p>
		</div>
		<div style="margin-left:auto; margin-right:auto;">
			<p style="margin-bottom:0px">Name:</p>
			<input style="width:100%; color:black;" type="text" name="LoginName" value="" autofocus><br>
			<p style="margin-bottom:0px">Password:</p>
			<input style="width:100%; color:black;" type="password" name="LoginPassword" value=""><br><br>
			<input style="width:100%; color:black;" type="submit" value="Login">
			<p><a href="/templates/register.sf.html">Register</a> - <a href="/templates/forgotPassword.sf.html">Forgot password?</a></p>
		</div>
	</div>
</form>