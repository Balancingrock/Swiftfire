---
layout: page
title: Confirm Server Admin Deletion
menuInclude: no
#
# Input:
#    $request.name: Name of the account to delete
#    $request.uuid: UUID string of the account to delete
#
# Output:
#    URL(POST): /serveradmin/command/delete-account
#    	uuid: The uuid string of the account to delete
#
#    URL: /serveradmin/pages/admin-management.sf.html
---
<div class="center-content">
	<div class="flex-column-hcenter">
		<div class="center-content" style="margin: 50px 0px 0px 0px;">
			Confirm removal of admin account:
		</div>
		<div class="center-content" style="margin: 30px 0px 40px 0px; background-color: yellow; border: 1px grey solid; font-size: 2em;">
			.show($request.name)
		</div>
		<div class="flex-row-vcenter" style="justify-content: space-between;">
			<form method="post" action="/serveradmin/command/delete-account">
				<input type="hidden" name="uuid" value=".show($request.uuid)">
				<input type="submit" value="Confirm">
			</form>
			<form method="post" action="/serveradmin/pages/admin-management.sf.html">
				<input type="submit" value="Cancel">
			</form>
		</div>
	</div>
</div>
