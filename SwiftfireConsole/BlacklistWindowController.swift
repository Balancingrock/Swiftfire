// =====================================================================================================================
//
//  File:       BlacklistWindowController.swift
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

final class BlacklistWindowController: NSWindowController, NSTableViewDataSource {
    
    
    // The data source
    
    var context = consoleData.context
    
    
    // Orders the sequence of the items in the window
    
    var sortDescriptor: [NSSortDescriptor] = [NSSortDescriptor(key: "address", ascending: true)]

    
    // MARK: - NSWindowController overrides
    
    override func windowDidLoad() {
        
        // Fetch the domains for the popup button
        
        if let toSwiftfire = toSwiftfire {
            toSwiftfire.transfer(ReadDomainsCommand())
        }
        else {
            showErrorInKeyWindow(message: "Not connected to Swiftfire")
        }
    }
    
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var selectPopUpButton: NSPopUpButton!
    @IBOutlet weak var blacklistTableView: NSTableView!
    @IBOutlet weak var dialogueSheet: BlacklistWindowSheet?
    

    // MARK: - IBActions
    
    @IBAction func selectPopUpButtonAction(sender: AnyObject?) {
        let target = selectPopUpButton.titleOfSelectedItem!
        toSwiftfire?.transfer(ReadBlacklistCommand(source: target))
    }
    
    @IBAction func addButtonAction(sender: AnyObject?) {
        
        if let sheet = dialogueSheet {
            sheet.setup(address: nil, action: nil)
            sheet.title = "Add to Blacklist"
            window?.beginSheet(sheet, completionHandler: nil)
        }
        else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find the blacklist sheet")
        }
    }
    
    @IBAction func optionsButtonAction(sender: AnyObject?) {
        
        let request = NSFetchRequest<SCBlacklistItem>(entityName: "SCBlacklistItem")
        request.sortDescriptors?.append(sortDescriptor[0])
        let entries = try! context!.fetch(request)
        
        let entry = entries[blacklistTableView.selectedRow]
        
        if let sheet = dialogueSheet {
            sheet.setup(address: entry.address, action: entry.action)
            sheet.title = "Update Entry for Blacklist: \(selectPopUpButton.titleOfSelectedItem ?? "???")"
            window?.beginSheet(sheet, completionHandler: nil)
        }
        else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find the blacklist sheet")
        }
    }
    
    @IBAction func removeButtonAction(sender: AnyObject?) {
        
        let request = NSFetchRequest<SCBlacklistItem>(entityName: "SCBlacklistItem")
        request.sortDescriptors?.append(sortDescriptor[0])
        let entries = try! context!.fetch(request)
        
        let entry = entries[blacklistTableView.selectedRow]

        let target = selectPopUpButton.titleOfSelectedItem!
        
        toSwiftfire?.transfer(ModifyBlacklistCommand(source: target, address: entry.address!, action: entry.action!, remove: true))
    }
    
    @IBAction func saveButtonAction(sender: AnyObject?) {
        if let toSwiftfire = toSwiftfire {
            let target = selectPopUpButton.titleOfSelectedItem!
            toSwiftfire.transfer(SaveBlacklistCommand(source: target))
        }
        else {
            showErrorInKeyWindow(message: "Not connected to Swiftfire")
        }
    }

    @IBAction func restoreButtonAction(sender: AnyObject?) {
        if let toSwiftfire = toSwiftfire {
            let target = selectPopUpButton.titleOfSelectedItem!
            toSwiftfire.transfer(RestoreBlacklistCommand(source: target))
        }
        else {
            showErrorInKeyWindow(message: "Not connected to Swiftfire")
        }
    }

    
    // MARK: - Sheet button handlers
    
    
    // Close the sheet
    
    @IBAction func sheetCancelButtonAction(sender: AnyObject?) {
        guard let sheet = dialogueSheet else { return }
        sheet.orderOut(self)
        window?.endSheet(sheet)
    }
    
    
    // Create and send the modify command, then close the sheet
    
    @IBAction func sheetUpdateAddButtonAction(sender: AnyObject?) {
        
        guard let sheet = dialogueSheet else { return }
        
        guard let target = selectPopUpButton.titleOfSelectedItem else { return }

        guard let action = sheet.actionPopUpButton.titleOfSelectedItem else { return }

        // The button this action is for is only enabled if the address is a valid IPv4 or IPv6 address
        let address = sheet.clientAddressTextField.stringValue
        
        let updateCommand = ModifyBlacklistCommand(source: target, address: address, action: action, remove: false)
        toSwiftfire?.transfer(updateCommand)

        sheetCancelButtonAction(sender: nil)
    }
}
