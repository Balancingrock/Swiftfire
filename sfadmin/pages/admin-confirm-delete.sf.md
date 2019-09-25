---
layout: page
title: Confirm Server Admin Deletion
menuInclude: no
---
<div class="center-content">
	<div class="flex-column-hcenter">
		<div class="center-content" style="margin: 50px 0px 0px 0px;">
			Confirm removal of admin account:
		</div>
		<div class="center-content" style="margin: 30px 0px 40px 0px; background-color: yellow;">
			.show($requestInfo.ID)
		</div>
		<div class="flex-row-vcenter" style="justify-content: space-between;">
			.postingButton("/serveradmin/sfcommand/DeleteAccount", "Confirmed", ID, $requestInfo.ID)
			.postingButton("/serveradmin/pages/admin-management.sf.html", Cancel, "", "")
		</div>
	</div>
</div>
