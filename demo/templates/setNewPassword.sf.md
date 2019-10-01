---
layout: page
title: Set New Password
---
If you requested to set a new password for your account, you can do so here. If not, simply ignore this page.

<form action="/command/newPassword" method="post">
	<div style="display:flex; justify-content:center; margin-bottom:50px;">
		<div style="margin-left:auto; margin-right:auto;">
			<p>.show($requestinfo!.PreviousAttemptMessage)</p>
			<br>
			<p style="margin-bottom:0px">Password:</p>
			<input style="color:black;" type="password" name="NewPassword1" value=".show($requestinfo!.NewPassword1)">
			<br>
			<p style="margin-bottom:0px">Password:</p>
			<input style="color:black;" type="password" name="NewPassword2" value=".show($requestinfo!.NewPassword2)">
			<br>
			<br>
			<input style="width:100%; color:black;" type="submit" value="Set New Password">
		</div>
	</div>
</form>
