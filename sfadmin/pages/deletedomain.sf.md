---
layout: page
title: "Confirm removal of domain: .show($request.domainname)"
menuInclude: no
---
<div class="centered-buttons">
    <form method="post" action="/serveradmin/sfcommand/DeleteDomain">
        <button class="posting-button-button" type="submit" name="DomainName" value=".show($request.domainname)">Delete</button>
    </form>
	<form method="post" action="/serveradmin/pages/domain-management.sf.html">
        <button type="submit" name="Cancel" value="Cancel">Cancel</button>
    </form>
</div>