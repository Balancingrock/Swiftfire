---
layout: page
title: Restarting Swiftfire
menuInclude: no
#
# Input:
#	-
#
# Output:
#	-
#
---
{:.text-centered}
Please wait 10 seconds to allow the process to complete.

<script type = "text/javascript">

var timeInSecs;
var ticker;

function startTimer(secs){
   timeInSecs = parseInt(secs)-1;
   ticker = setInterval("tick()",1000);   // every second
}

function tick() {
   var secs = timeInSecs;
   if (secs>0) {
      timeInSecs--;
   } else {
      clearInterval(ticker); // stop counting at zero
      window.location.href = "/serveradmin";
   }
   document.getElementById("countdown").innerHTML = secs;
}

startTimer(10);  // 10 seconds 

</script>

<div style="text-align:center;">
<span id="countdown" style="font-weight:bold; font-size:24px;">10</span>
</div>