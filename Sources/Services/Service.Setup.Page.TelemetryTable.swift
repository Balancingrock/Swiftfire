// =====================================================================================================================
//
//  File:       Service.Setup.AdminPage.TelemetryTable.swift
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


/// Create the telemetry table for the domain setup page,
///
/// - Parameters:
///     - domain: The domain for which to create it
///
/// - Returns: The requested HTML code.

func telemetryTable(_ domain: Domain) -> String {
    
    var html: String = """
        <div class="center-content">
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Name</th><th>Value</th><th>Description</th>
                        </tr>
                    </thead>
                    <tbody>
    """
    
    domain.telemetry.all.forEach() {
        html += """
            <tr>
                <td>\($0.name)</td><td>\($0.stringValue)</td><td>\($0.about)</td>
            </tr>
        """
    }

    html += """
                    </tbody>
                </table>
            </div>
        </div>
    """
    
    return html
}
