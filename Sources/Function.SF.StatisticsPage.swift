// =====================================================================================================================
//
//  File:       Function.SF.StatisticsPage.swift
//  Project:    Swiftfire
//
//  Version:    0.10.9
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


// Returns a table with all telemetry values.
///
/// - Returns: The table with all telemetry values.

func function_sf_statisticsPage(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    struct Button: CustomStringConvertible {
        var title: String
        var description: String {
            return "<input type=\"submit\" value=\"\(title)\">"
        }
        init(_ title: String) {
            self.title = title
        }
    }
    
    struct Hidden: CustomStringConvertible {
        var name: String
        var value: String
        var description: String {
            return "<input type=\"hidden\" name=\"\(name)\" value=\"\(value)\">"
        }
        init(_ name: String, _ value: String) {
            self.name = name
            self.value = value
        }
    }
    
    struct DomainForm: CustomStringConvertible {
        var content: String
        var title: String
        var description: String {
            return "<form method=\"post\" action=\"/serveradmin/pages/statistics.sf.html\">\(Hidden("RequestedPage", "Domains"))\(content)\(Button(title))</form>"
        }
        init(_ title: String, content: String) {
            self.title = title
            self.content = content
        }
    }
    
    
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
        
        result += "<h2 style=\"text-align:center;\">URL Visits</h2><div class=\"statistics-switch-div\"><form action=\"/serveradmin/pages/statistics.sf.html\" method=\"post\">\(Hidden("RequestedPage", "Clients"))\(Button("Switch to Client View"))</form></div>"
        
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
                    
                    backButtonCode = "\(Hidden("Domain", domainName))"
                    
                    var pathPart = domainName
                    while true {
                        if let nextPathPart = postInfo[pathPart] {
                            if postInfo[nextPathPart] != nil {
                                backButtonCode += Hidden(pathPart, nextPathPart).description
                            }
                            pathPart = nextPathPart
                        } else {
                            break
                        }
                    }

                    backButtonCode = DomainForm("Back", content: backButtonCode).description
                    
                } else {
                    backButtonCode = DomainForm("Back", content: "").description
                }
                
                result += "<table class=\"statistics-domains-table\"><thead><tr><th colspan=\"3\"><div>URL: \(part!.fullUrl)\(backButtonCode)</div></th></tr><tr><th>Accesses</th><th>URL Part</th><th>Do Not Trace</th></tr></thead><tbody>"
                
                
                // Ad the rows
                
                for row in part!.nextParts {
                    
                    
                    // Create the path button postInfo
                    
                    var pathCode = "\(Hidden("RequestedPage", "Domains"))\(Hidden("Domain", domainName))"
                    
                    var pathPart = domainName
                    while true {
                        if let nextPathPart = postInfo[pathPart] {
                            pathCode += Hidden(pathPart, nextPathPart).description
                            pathPart = nextPathPart
                        } else {
                            pathCode += Hidden(pathPart, row.pathPart).description
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
                    (environment.connection as? SFConnection)?.filemanager.fileExists(atPath: url.path, isDirectory: &isDir)
                    
                    // Create 'details' button
                    
                    var details: String = ""
                    if isDir.boolValue { details += DomainForm("Detail", content: pathCode).description }
                    
                    
                    result += "<tr><td>\(row.foreverCount)</td><td><div>\(row.pathPart)\(details)</div></td><td>\(row.doNotTrace ? "true" : "false")</td></tr>"
                }
                
                
                // Add the end of table
                
                result += "</tbody></table>"

            } else {
                
                result += "***Error***"
            }
            
        } else {
            
            // Add the table header
            
            result += "<table class=\"statistics-domains-table\"><thead><tr><th>Accesses</th><th>URL Part</th><th>Do Not Trace</th></tr></thead><tbody>"
            
            
            // Ad the rows
            
            for row in statistics.domains.domains {
                
                result += "<tr><td>\(row.foreverCount)</td><td><div>\(row.pathPart)\(DomainForm("Detail", content: Hidden("Domain", row.pathPart).description))</div></td><td>\(row.doNotTrace ? "true" : "false")</td></tr>"
            }
            
            
            // Add the end of table
            
            result += "</tbody></table>"
        }
        
        
    } else {
        
        // Show the list of clients
        
        result += "<h2 style=\"text-align:center;\">Client visits</h2><div class=\"statistics-switch-div\"><form action=\"/serveradmin/pages/statistics.sf.html\" method=\"post\"><input type=\"hidden\" name=\"RequestedPage\" value=\"Domains\"><input type=\"submit\" value=\"Switch to URL View\"></form></div>"
        
        
        // The client list
        
        // Add the table header
        
        result += "<table class=\"statistics-clients-table\"><thead><tr><th>Address</th><th>Count</th><th>Do Not Trace</th></tr></thead><tbody>"

        // Ad the rows
        
        for row in statistics.clients.clients {
            
            result += "<tr><td>\(row.address)</td><td>\(row.records.count)</td><td>\(row.doNotTrace ? "true" : "false")</td></tr>"
        }
        
        
        // Add the end of table
        
        result += "</tbody></table>"
    }
        
    return result.data(using: String.Encoding.utf8)
}

