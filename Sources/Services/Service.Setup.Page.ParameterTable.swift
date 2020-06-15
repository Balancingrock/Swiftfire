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
//  Copyright:  (c) 2019-2020 Marinus van der Lugt, All rights reserved.
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


/// Create the parameter table for the domain setup page,
///
/// - Parameters:
///     - domain: The domain for which to create it
///
/// - Returns: The requested HTML code.

func parameterTable(_ domain: Domain) -> String {
    
    func setupCommand(_ cmd: String) -> String {
        return "/\(domain.setupKeyword!)/command/\(cmd)"
    }
    
    func parameterRow(text: String, name: String, value: String, comment: String) -> String {
        return """
        <tr>
            <td>\(text)</td>
            <td>
                <form method="post" action="\(setupCommand("update-parameter"))">
                    <input type="hidden" name="parameter-name" value="\(name)">
                    <input type="text" name="parameter-value" value="\(value)">
                    <input type="submit" value="Update">
                </form>
            </td>
            <td>\(comment)</td>
        </tr>
        """
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
            \(parameterRow(
                text: "Enabled",
                name: "enabled",
                value: String(domain.enabled),
                comment: "The domain is enabled when set to 'true', disabled otherwise"))
            \(parameterRow(
                text: "Access Log",
                name: "access-log-enabled",
                value: String(domain.accessLogEnabled),
                comment: "The access log is enabled when set to 'true', disabled otherwise"))
            \(parameterRow(
                text: "404 Log",
                name: "404-log-enabled",
                value: String(domain.four04LogEnabled),
                comment: "The 404 log is enabled when set to 'true', disabled otherwise"))
            \(parameterRow(
                text: "Session Log",
                name: "session-log-enabled",
                value: String(domain.sessionLogEnabled),
                comment: "The session log is enabled when set to 'true', disabled otherwise"))
            \(parameterRow(
                text: "Session Timeout",
                name: "session-timeout",
                value: String(domain.sessionTimeout),
                comment: "A session is considered expired when inactive for this long (in seconds)"))
            \(parameterRow(
                text: "Scan all HTML files",
                name: "scan-all-html",
                value: String(domain.scanAllHtml),
                comment: "When true, all 'htm', 'html' and 'php' file will be scanned for Swiftfire functions"))
            \(parameterRow(
                text: "PHP Executable Path",
                name: "php-executable-path",
                value: String(domain.phpPath?.path ?? "Disabled"),
                comment: "To enable PHP, set a path to the php executable to be used"))
            \(parameterRow(
                text: "PHP Map Index",
                name: "php-map-index",
                value: String(domain.phpPath == nil ? "nvt" : String(domain.phpMapIndex)),
                comment: "Maps index.*.html to index.*.php if no index.*.html found (enable PHP first)"))
            \(parameterRow(
                text: "PHP Map All",
                name: "php-map-all",
                value: String(domain.phpPath == nil ? "nvt" : String(domain.phpMapAll)),
                comment: "Maps *.html to *.php if no *.html file found (enable PHP first)"))
            \(parameterRow(
                text: "PHP Timeout",
                name: "php-timeout",
                value: String(domain.phpPath == nil ? "nvt" : String(domain.phpTimeout)),
                comment: "Timeout for PHP processing (in mSec - enable PHP first)"))
            \(parameterRow(
                text: "Comment Auto Approval Threshold",
                name: "comment-auto-approval-threshold",
                value: String(domain.commentAutoApprovalThreshold),
                comment: "Auto approve comments when this many comments have been manually approved"))
            \(parameterRow(
                text: "Forward URL",
                name: "forward-url",
                value: String(domain.forwardUrl),
                comment: "Forwards all incoming traffic to this url (clear to disable)"))
        </tbody>
        </table>
    </div>
    """
    
    return html
}
