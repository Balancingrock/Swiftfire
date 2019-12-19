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

Note: The domain root directory and the domain support directory in "Application Support/Swiftfire/domains/.show($request.domain-name)" will not be deleted, this must be done separately. Creating the domain again before deleting these directories will cause the instant reappearance of the domain as it was before.
{:.text-centered}