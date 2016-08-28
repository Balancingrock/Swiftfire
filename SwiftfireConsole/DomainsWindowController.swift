// =====================================================================================================================
//
//  File:       DomainsWindowController.swift
//  Project:    SwiftfireConsole
//
//  Version:    0.9.14
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2016 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that the Non Agression Principle is the way for societies to function optimally. I thus reject
//  the implicit use of force to extract payment. Since I cannot negotiate with you about the price of this code, I
//  have choosen to leave it up to you to determine its price. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// v0.9.14 - Initial release
// =====================================================================================================================

import Foundation
import Cocoa


class DomainsWindowController: NSWindowController {
    
    
    // The data source
    
    var context = consoleData.context
    
    
    // Orders the sequence of the items in the window
    
    var sortDescriptor: [NSSortDescriptor] = [NSSortDescriptor(key: "sequence", ascending: true)]
    
    
    // The selected items
    
    dynamic var indexPathsOfSelectedItems: Array<IndexPath> = []
    
    
    // The domains are automatically loaded when the window loads
    
    override func windowDidLoad() {
        refreshButtonAction(sender: nil)
    }
    
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    @IBAction func saveDomainsButtonAction(sender: AnyObject?) {
        if toSwiftfire == nil {
            showErrorInKeyWindow(message: "Not connected to Swiftfire")
        }
        toSwiftfire?.transfer(SaveDomainsCommand())
    }
    
    @IBAction func restoreDomainsButtonAction(sender: AnyObject?) {
        if toSwiftfire == nil {
            showErrorInKeyWindow(message: "Not connected to Swiftfire")
        }
        toSwiftfire?.transfer(RestoreDomainsCommand())
        toSwiftfire?.transfer(ReadDomainsCommand())
    }

    @IBAction func refreshButtonAction(sender: AnyObject?) {
        if toSwiftfire == nil {
            showErrorInKeyWindow(message: "Not connected to Swiftfire")
        }
        toSwiftfire?.transfer(ReadDomainsCommand())
    }
    
    @IBAction func addDomain(sender: AnyObject?) {
        
        var domainName = "domain.com"
        
        let request = NSFetchRequest<SCDomainItem>(entityName: "SCDomainItem")
        request.predicate = NSPredicate(format: "parent == nil")
        let topLevelItems = try! consoleData.context.fetch(request)
        
        while topLevelItems.reduce(false, { $0 || ($1.name?.lowercased() == domainName) }) {
            domainName = domainName + ".new"
        }
        
        guard let command = CreateDomainCommand(domainName: domainName) else {
            log.atLevelError(source: #file.source(#function, #line), message: "Failed to create CreateDomainCommand")
            return
        }
        
        
        // Add the domain
        
        toSwiftfire?.transfer(command)
        
        
        // Re-acquire the domains
        
        toSwiftfire?.transfer(ReadDomainsCommand())
    }
    
    @IBAction func removeDomain(sender: AnyObject?) {
        
        
        // Get all domain names in the proper sequence
        
        let request = NSFetchRequest<SCDomainItem>(entityName: "SCDomainItem")
        request.predicate = NSPredicate(format: "parent == nil")
        let topLevelItems = (try! consoleData.context.fetch(request)).sorted(by: { $0.name! < $1.name! })
        
        
        // Find the selected domain names
        
        var selectedDomainNames: Set<String> = []
        indexPathsOfSelectedItems.forEach({ selectedDomainNames.insert(topLevelItems[$0[0]].name!)})

        
        // Ask the user if he is sure
        
        let info = selectedDomainNames.reduce("You are about to remove the following domain(s):\n", { $0 + $1 + "\n" })
        
        let alert = NSAlert()
        alert.messageText = "Delete Domain(s)"
        alert.informativeText = info
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: self.window!) { (response) -> Void in
            if response == NSAlertFirstButtonReturn {
                
                
                // Send one REMOVE command for each domain that is selected
                
                for name in selectedDomainNames {
                    toSwiftfire?.transfer(RemoveDomainCommand(domainName: name))
                }
                
                
                // Re-acquire the domains
                
                toSwiftfire?.transfer(ReadDomainsCommand())
            }
        }
    }
}
