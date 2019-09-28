---
layout: page
title: Register
---
To register, fill out the fields below and click the 'Register' button. Upon verification of the fields values, an email will be sent to the given address containing a verification link. Visit that link to complete the registration process.

<form action="/command/register" method="post">
	<div style="display:flex; justify-content:center; margin-bottom:50px;">
		<div style="margin-left:auto; margin-right:auto;">
			<p>.show($requestinfo!.PreviousAttemptMessage)</p>
			<br>
			<p style="margin-bottom:0px">Name:</p>
			<input type="text" name="RegisterName" value=".show($requestinfo!.RegisterName)" autofocus>
			<br>
			<p style="margin-bottom:0px">Password:</p>
			<input type="password" name="RegisterPassword1" value=".show($requestinfo!.RegisterPassword1)">
			<br>
			<p style="margin-bottom:0px">Password:</p>
			<input type="password" name="RegisterPassword2" value=".show($requestinfo!.RegisterPassword2)">
			<br>
			<p style="margin-bottom:0px">Email:</p>
			<input type="text" name="RegisterEmail" value=".show($requestinfo!.RegisterEmail)">
			<br>
			<br>
			<input style="width:100%" type="submit" value="Register">
		</div>
	</div>
</form>
