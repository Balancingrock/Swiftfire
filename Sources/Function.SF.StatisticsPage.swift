// =====================================================================================================================
//
//  File:       Function.SF.StatisticsPage.swift
//  Project:    Swiftfire
//
//  Version:    0.10.10
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 0.10.10 - Changed Connection to SFConnection
// 0.10.9 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Returns a page with data and controls to view the server statistics.
//
//
// Signature:
// ----------
//
// .sf-statisticsPage()
//
//
// Parameters:
// -----------
//
// None.
//
//
// Other Input:
// ------------
//
// session = environment.serviceInfo[.sessionKey] // Must be a non-expired session.
// session[.accountKey] must contain an admin account
//
// Class of the div containing the 'Switch to...' button: statistics-switch-div
// Class of the table for the domains: statistics-domains-table
// Class of the table for the clients: statistics-clients-table
//
//
// Returns:
// --------
//
// The statistics page or:
// - "Session error"
// - "Account error"
// - "Illegal access"
//
//
// Other Output:
// -------------
//
// None.
//
//
// =====================================================================================================================

import Foundation
import Html


// Returns a table with all telemetry values.
///
/// - Returns: The table with all telemetry values.

func function_sf_statisticsPage(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    // Check access rights
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        return "Session error".data(using: String.Encoding.utf8)
    }
    
    guard let account = session.info[.accountKey] as? Account else {
        return "Account error".data(using: String.Encoding.utf8)
    }
    
    guard serverAdminDomain.accounts.contains(account.uuid) else {
        return "Illegal access".data(using: String.Encoding.utf8)
    }
    
    
    // Get the posted info
    
    let postInfo = environment.serviceInfo[.postInfoKey] as? PostInfo ?? PostInfo()
    
    var result: String = ""

    
    // Domains or Clients?
    
    if postInfo["RequestedPage"] == "Domains" {
        
        // Show the list of domains
        // ------------------------
        
        // Button to select domains or clients list
        // ----------------------------------------
        
        let hidden = Input.hidden(name: "RequestedPage", value: "Clients")
        let button = Input.submit(title: "Switch to Client View")
        let form = Form(method: .post, action: "/serveradmin/pages/statistics.sf.html", hidden, button)
        let header = H2(klass: "statistics-h2", "URL Visits")
        let switchContainer = Div(klass: "statistics-switch-div", form)
        
        result += header.html
        result += switchContainer.html
        
        // The domains list
        // ----------------
        
        if let domainName = postInfo["Domain"] {
            
            var part = statistics.domains.getDomain(for: domainName)
            if part != nil {
                
                var partName = domainName
                
                while part != nil {
                    let nextPartName = postInfo[partName]
                    if nextPartName == nil { break }
                    let nextPart = part!.getPathPart(for: nextPartName!)
                    if nextPart == nil { break }
                    part = nextPart
                    partName = nextPartName!
                }
                
                // Add the table header
                
                var backButtonCode: String = ""
                if part?.previous != nil {
                    
                    backButtonCode = Input.hidden(name: "Domain", value: domainName).html
                    
                    var pathPart = domainName
                    while true {
                        if let nextPathPart = postInfo[pathPart] {
                            if postInfo[nextPathPart] != nil {
                                backButtonCode += Input.hidden(name: pathPart, value: nextPathPart).html
                            }
                            pathPart = nextPathPart
                        } else {
                            break
                        }
                    }
                    
                    backButtonCode = Form(method: .post, action: "/serveradmin/pages/statistics.sf.html", Input.hidden(name: "RequestedPage", value: "Domains"), backButtonCode, Input.submit(title: "Back")).html
                    
                } else {
                    backButtonCode = Form(method: .post, action: "/serveradmin/pages/statistics.sf.html", Input.hidden(name: "RequestedPage", value: "Domains"), Input.submit(title: "Back")).html
                }
                
                var headerTopCell = Th(Div("Dir: ", part!.fullUrl, backButtonCode))
                headerTopCell.colspan = 3
                let tableHeader = Thead(Tr(headerTopCell), Tr(Th("Accesses"), Th("File / Dir"), Th("Do Not Trace")))
                var table = Table(klass: "statistics-domains-table", header: tableHeader)

                
                // Ad the rows
                
                for row in part!.nextParts {
                    
                    
                    // Create the path button postInfo
                    
                    var pathCode = Input.hidden(name: "RequestedPage", value: "Domains").html
                    pathCode += Input.hidden(name: "Domain", value: domainName).html
                    
                    var pathPart = domainName
                    while true {
                        if let nextPathPart = postInfo[pathPart] {
                            pathCode += Input.hidden(name: pathPart, value: nextPathPart).html
                            pathPart = nextPathPart
                        } else {
                            pathCode += Input.hidden(name: pathPart, value: row.pathPart).html
                            break
                        }
                    }
                    
                    
                    // Find out if this row represents a dictionary
                    
                    var components = URL(string: row.fullUrl)?.pathComponents
                    let urlDomainName = components?.remove(at: 0)
                    let domain = domains.domain(forName: urlDomainName)!
                    var url = URL(fileURLWithPath: domain.root)
                    components?.forEach({ url = url.appendingPathComponent($0) })
                    var isDir: ObjCBool = false
                    environment.connection.filemanager.fileExists(atPath: url.path, isDirectory: &isDir)
                    
                    // Create 'details' button
                    
                    var details: String = ""
                    if isDir.boolValue {
                        
                        let button = Input.submit(title: "Detail")
                        let hidden = Input.hidden(name: "RequestedPage", value: "Domains")
                        let form = Form(method: .post, action: "/serveradmin/pages/statistics.sf.html", hidden, pathCode, button)
                        
                        details += form.html
                    }
                    
                    let form = Form(method: .post, action: "/serveradmin/sfcommand/UpdateDoNotTraceUrl", pathCode, Div(Input.checkbox(name: "checkbox", value: "", checked: row.doNotTrace), Input.submit(title: "Update")))
                    let cell1 = Td(row.foreverCount.description)
                    let cell2 = Td(Div(row.pathPart, details))
                    let cell3 = Td(form)
                    let tableRow = Tr(cell1, cell2, cell3)
                    table.append(tableRow)
                }
                
                
                // Add the end of table
                
                result += table.html

            } else {
                
                result += "***Error***"
            }
            
        } else {
            
            // Add the table header
            
            var table = Table(klass: "statistics-domains-table", columnTitles: "Accesses", "File / Dir", "Do Not Trace")
            
            // Ad the rows
            
            for row in statistics.domains.domains {

                let dntButton = Input.submit(title: "Update")
                let dntCheckbox = Input.checkbox(name: "checkbox", value: "", checked: row.doNotTrace)
                let dntDiv = Div(dntCheckbox, " ", dntButton)
                let dntPath = Input.hidden(name: "Domain", value: row.pathPart)
                let dntForm = Form(method: .post, action: "/serveradmin/sfcommand/UpdateDoNotTraceUrl", dntPath, dntDiv)
                
                let detailButton = Input.submit(title: "Detail")
                let detailPath = Input.hidden(name: "Domain", value: row.pathPart)
                let detailPage = Input.hidden(name: "RequestedPage", value: "Domains")
                let detailForm = Form(method: .post, action: "/serveradmin/pages/statistics.sf.html", detailPage, detailPath, detailButton)
                let detailDiv = Div(row.pathPart, detailForm)
                
                let row = Tr(Td(row.foreverCount.description), Td(detailDiv), Td(dntForm))
                
                table.append(row)
            }
            
            
            // Add the end of table
            
            result += table.html
        }
        
        
    } else {
        
        // Show the list of clients
        
        let hidden = Input.hidden(name: "RequestedPage", value: "Domains")
        let button = Input.submit(title: "Switch to URL View")
        let form = Form(method: .post, action: "/serveradmin/pages/statistics.sf.html", hidden, button)
        let header = H2(klass: "statistics-h2", "Client Visits")
        let switchContainer = Div(klass: "statistics-switch-div", form)
        
        result += header.html
        result += switchContainer.html

        var table = Table(klass: "statistics-clients-table", columnTitles: "Address", "Count", "Do Not Trace")
        
        // Ad the rows
        
        for row in statistics.clients.clients {
            
            let form = Form(method: .post, action: "/serveradmin/sfcommand/UpdateDoNotTraceClient", Input.hidden(name: "Client", value: row.address), Input.checkbox(name: "checkbox", value: "", checked: row.doNotTrace), " ", Input.submit(title: "Update"))
            
            table.append(Tr(Td(row.address), Td(row.records.count.description), Td(form)))
        }
        
        
        // Add the end of table
        
        result += table.html
    }
        
    return result.data(using: String.Encoding.utf8)
}

