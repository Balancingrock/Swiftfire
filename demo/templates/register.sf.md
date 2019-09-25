---
layout: page
title: Login
---
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
			<p>An email will be sent to the given address containing a confirmation link. Visit that link to complete the regstrationprocess.</p>
			<br>
			<br>
			<input style="width:100%" type="submit" value="Register">
		</div>
	</div>
</form>