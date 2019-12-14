// =====================================================================================================================
//
//  File:       Service.Setup.AdminPage.ServiceTable.swift
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


internal func servicesTable(_ domain: Domain) -> String {

    func setupCommand(_ cmd: String) -> String {
        return "/\(domain.setupKeyword!)/command/\(cmd)"
    }

    // Prepare the table data
    
    struct TableRow {
        let rowIndex: Int
        let name: String
        let usedByDomain: Bool
    }
    
    var tableRows: Array<TableRow> = []
    
    var index: Int = 0
    for service in domain.services {
        tableRows.append(TableRow(rowIndex: index, name: service.name, usedByDomain: true))
        index += 1
    }
    
    OUTER: for service in services.registered {
        for row in tableRows {
            if row.name == service.value.name { continue OUTER }
        }
        tableRows.append(TableRow(rowIndex: tableRows.count, name: service.value.name, usedByDomain: false))
    }
    
    
    // Create the table
    
    var html: String = """
        <div class="center-content">
            <div class="table-container">
                <form method="post" action="\(setupCommand("update-services"))">
                    <table>
                        <thead>
                            <tr>
                                <th>Index</th>
                                <th>Seq.</th>
                                <th>Service Name</th>
                                <th>Used</th>
                            </tr>
                        </thead>
                        <tbody>
    
    """
    
    for row in tableRows {
        
        let entry: String = """
            <tr>
                <td>\(row.rowIndex)</td>
                <td><input type="text" name="seqName\(row.rowIndex)" value="\(row.rowIndex)"></td>
                <td><input type="text" name="nameName\(row.rowIndex)" value="\(row.name)" disabled></td>
                <td><input type="hidden" name="nameName\(row.rowIndex)" value="\(row.name)"></td>
                <td><input type="checkbox" name="usedName\(row.rowIndex)" value="usedName\(row.rowIndex)" \(row.usedByDomain ? "checked" : "")></td>
            </tr>
        
        """
        html += entry
    }
    
    html += """
                        </tbody>
                    </table>
                    <div class="center-content">
                        <div class="center-self submit-offset">
                            <input type="submit" value="Update Services">
                        </div>
                    </div>
                </form>
            </div>
        </div>
    """
    
    return html
}
