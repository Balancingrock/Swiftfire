---
layout: page
title: Register
---
To register, fill out the fields below and click the 'Register' button. Upon verification of the fields values, an email will be sent to the given address containing a verification link. Visit that link to complete the registration process.

<form action="/command/register" method="post">
	<div style="display:flex; flex-direction:column; justify-content:center; margin-bottom:50px;">
		<div style="margin-left:auto; margin-right:auto;">
			<p>.show($request.previous-attempt-message!)</p>
		</div>
		<div style="margin-left:auto; margin-right:auto;">
			<br>
			<p style="margin-bottom:0px">Name:</p>
			<input style="color:black;" type="text" name="register-name" value=".show($request.register-name!)" autofocus>
			<br>
			<p style="margin-bottom:0px">Password:</p>
			<input style="color:black;" type="password" name="register-password-1" value=".show($request.RegisterPassword1!)">
			<br>
			<p style="margin-bottom:0px">Password:</p>
			<input style="color:black;" type="password" name="register-password-2" value=".show($request.RegisterPassword2!)">
			<br>
			<p style="margin-bottom:0px">Email:</p>
			<input style="color:black;" type="text" name="register-email" value=".show($request.register-email!)">
			<br>
			<br>
			<input style="width:100%; color:black;" type="submit" value="Register">
		</div>
	</div>
</form>
