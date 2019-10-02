---
layout: page
title: New Password?
---
If you forgot your password, you can use this page to set a new password.

Step 1: Fill in the name of the account

Step 2: Click 'Set New Password'

Step 3: Wait for the email to arrive and visit the link in the email

Step 4: Set a new password

The link in the mail is valid for 24 hours. The account remains usable with the old password up until a new password is set.

<form action="/command/forgot-password" method="post">
	<div style="display:flex; flex-direction:column; justify-content:center; margin-bottom:50px;">
		<div style="margin-left:auto; margin-right:auto;">
			<p style="margin-bottom:0px">Name:</p>
			<input style="width:100%; color:black;" type="text" name="forgot-password-name" value="" autofocus><br><br>
			<input style="width:100%; color:black;" type="submit" value="Set New Password">
		</div>
	</div>
</form>
