// =====================================================================================================================
//
//  File:       Service.Setup.AdminPage.DomainParameterTable.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019 Marinus van der Lugt, All rights reserved.
//
//  License:    Use or redistribute this code any way you like with the following two provision:
//
//  1) You ACCEPT this source code AS IS without any guarantees that it will work as intended. Any liability from its
//  use is YOURS.
//
//  2) You WILL NOT seek damages from the author or balancingrock.nl.
//
//  I also ask you to please leave this header with the source code.
//
//  Like you, I need to make a living:
//
//   - You can send payment (you choose the amount) via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (again: rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.3.0 - Split off from Service.Setup
//
// =====================================================================================================================

import Foundation

import Core

internal func parameterTable(_ domain: Domain) -> String {
    
    func setupCommand(_ cmd: String) -> String {
        return "/\(domain.setupKeyword!)/command/\(cmd)"
    }
    
    let html = """
    <div class="table-container center-content">
        <table>
        <thead>
            <tr>
                <th>Parameter</th><th>Value</th><th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Enabled</td>
                <td>
                    <form method="post" action="\(setupCommand("update-parameter"))">
                        <input type="hidden" name="parameter-name" value="enabled">
                        <input type="text" name="parameter-value" value="\(domain.enabled)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>The domain is enabled when set to 'true', disabled otherwise</td>
            </tr>
            <tr>
                <td>Access Log</td>
                <td>
                    <form method="post" action="\(setupCommand("update-parameter"))">
                        <input type="hidden" name="parameter-name" value="accessLogEnabled">
                        <input type="text" name="parameter-value" value="\(domain.accessLogEnabled)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>The access log is enabled when set to 'true', disabled otherwise</td>
            </tr>
            <tr>
                <td>404 Log</td>
                <td>
                    <form method="post" action="\(setupCommand("update-parameter"))">
                        <input type="hidden" name="parameter-name" value="four04LogEnabled">
                        <input type="text" name="parameter-value" value="\(domain.four04LogEnabled)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>The 404 log is enabled when set to 'true', disabled otherwise</td>
            </tr>
            <tr>
                <td>Session Log</td>
                <td>
                    <form method="post" action="\(setupCommand("update-parameter"))">
                        <input type="hidden" name="parameter-name" value="sessionLogEnabled">
                        <input type="text" name="parameter-value" value="\(domain.sessionLogEnabled)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>The session log is enabled when set to 'true', disabled otherwise</td>
            </tr>
            <tr>
                <td>Session Timeout</td>
                <td>
                    <form method="post" action="\(setupCommand("update-parameter"))">
                        <input type="hidden" name="parameter-name" value="sessionTimeout">
                        <input type="text" name="parameter-value" value="\(domain.sessionTimeout)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>A session is considered expired when inactive for this long (in seconds)</td>
            </tr>
            <tr>
                <td>PHP Map Index</td>
                <td>
                    <form method="post" action="\(setupCommand("update-parameter"))">
                        <input type="hidden" name="parameter-name" value="phpMapIndex">
                        <input type="text" name="parameter-value" value="\(domain.phpMapIndex)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>Maps index requests to include index.php and index.sf.php</td>
            </tr>
            <tr>
                <td>PHP Map All</td>
                <td>
                    <form method="post" action="\(setupCommand("update-parameter"))">
                        <input type="hidden" name="parameter-name" value="phpMapAll">
                        <input type="text" name="parameter-value" value="\(domain.phpMapAll)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>Allows to map *.html to *.php</td>
            </tr>
            <tr>
                <td>PHP Timeout</td>
                <td>
                    <form method="post" action="\(setupCommand("update-parameter"))">
                        <input type="hidden" name="parameter-name" value="phpTimeout">
                        <input type="text" name="parameter-value" value="\(domain.phpTimeout)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>Timeout for PHP processing (in mSec)</td>
            </tr>
            <tr>
                <td>Foreward URL</td>
                <td>
                    <form method="post" action="\(setupCommand("update-parameter"))">
                        <input type="hidden" name="parameter-name" value="forwardUrl">
                        <input type="text" name="parameter-value" value="\(domain.forwardUrl)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>(Optional) Forwards all incoming traffic to this url</td>
            </tr>
        </tbody>
        </table>
    </div>
    """
    
    return html
}
