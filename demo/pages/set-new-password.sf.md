---
layout: page
title: Set New Password
---
If you requested to set a new password for your account, you can do so here. If not, simply ignore this page.

<form action="/command/set-new-password" method="post">
	<input type="hidden" name="name" value=".show($request!.name)">
	<div style="display:flex; flex-direction:column; justify-content:center; margin-bottom:50px;">
		<div style="margin-left:auto; margin-right:auto;">
			<p>.show($request.previous-attempt-message!)</p>
		</div>
		<div style="margin-left:auto; margin-right:auto;">
			<br>
			<p style="margin-bottom:0px">Password:</p>
			<input style="color:black;" type="password" name="set-new-password-1" value=".show($request.set-new-password-1!)">
			<br>
			<p style="margin-bottom:0px">Password:</p>
			<input style="color:black;" type="password" name="set-new-password-2" value=".show($request.set-new-password-2!)">
			<br>
			<br>
			<input style="width:100%; color:black;" type="submit" value="Set New Password">
		</div>
	</div>
</form>
