---
layout: page
title: Telemetry
menuInclude: yes
menuTopTitle: Telemetry
menuTopIndex: 5
---
<div class="telemetry-table">
    <table class="telemetry-table">
        <thead>
            <tr><th>Name</th><th>Value</th><th>Description</th></tr>
        </thead>
        <tbody>
		.for(server-telemetry)    
            <tr>
                <td class="table-column-name">.show($info.named-value-protocol-name)</td>
                <td class="table-column-value">.show($info.named-value-protocol-value)</td>
                <td class="table-column-description">.show($info.named-value-protocol-about)</td>
            </tr>
        .end()
        </tbody>
    </table>
</div>