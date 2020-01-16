---
layout: page
title: Quit Swiftfire
menuInclude: no
#
# Input:
#	-
#
# Output:
#	URL: /serveradmin/command/confirmed-quit
#
#	URL: /serveradmin/command/cancel-quit
#
---
{:.text-centered}
## Are you sure you want to quit Swiftfire?

{:.text-centered}
It can only be manually restarted at the server itself.

<div class="centered-buttons">
    <form method="post" action="/serveradmin/command/confirmed-quit">
        <input type="submit" value="Confirm Quit">
    </form>
    <form method="post" action="/serveradmin/command/cancel-quit">
        <input type="submit" value="Cancel">
    </form>
</div>

