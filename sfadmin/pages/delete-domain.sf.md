---
layout: page
title: "Confirm removal of domain: .show($request.domain-name)"
menuInclude: no
---
<div class="centered-buttons">
    <form method="post" action="/serveradmin/command/delete-domain">
        <button type="submit" name="domain-name" value=".show($request.domain-name)">Delete</button>
    </form>
	<form method="post" action="/serveradmin/pages/domain-management.sf.html">
        <button type="submit" name="Cancel" value="Cancel">Cancel</button>
    </form>
</div>
