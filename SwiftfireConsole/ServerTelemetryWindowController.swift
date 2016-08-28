// =====================================================================================================================
//
//  File:       ServerTelemetryWindowController.swift
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

class ServerTelemetryWindowController: NSWindowController {
    
    
    // The window uses bindings to this managed object context
    
    var context = consoleData.context
    
    
    // Orders the appearanche of the telemetry items in the window
    
    var sortDescriptor: [NSSortDescriptor] = [NSSortDescriptor(key: "sequence", ascending: true)]


    // Performs periodic fetching of the server telemetry from the Swiftfire Server
    
    var telemetryFetchTimer: Timer?

    
    // The telemetry is automatically loaded when the window loads
    
    override func windowDidLoad() {
        super.windowDidLoad()
        handleRefreshButtonAction(sender: nil)
    }

    
    @IBOutlet weak var autoRefreshCheckbox: NSButton!
    @IBOutlet weak var intervalTextField: NSTextField!
    
    
    @IBAction func handleRefreshButtonAction(sender: AnyObject?) {
        
        guard toSwiftfire != nil else {
            showErrorInKeyWindow(message: "Not connected to Swiftfire")
            return
        }
        
        for item in serverTelemetryArray {
            toSwiftfire?.transfer(ReadServerTelemetryCommand(telemetryName: item.name))
        }
    }
    
    
    @IBAction func handleAutoRefreshCheckboxAction(sender: AnyObject?) {
        
        
        // Make sure the interval is valid
        
        let interval = intervalTextField.integerValue
        
        if interval < 10 || interval > 2*24*60*60 {
            showErrorInKeyWindow(message: "Interval out of range, should be > 10 and < (2 * 24 * 60 * 60)")
            return
        }
        
        
        // Invalidate and remove existing timer
        
        if telemetryFetchTimer != nil {
            telemetryFetchTimer!.invalidate()
            telemetryFetchTimer = nil
        }
        
        
        // Create a new timer if the checkbox is switched to "on"
        
        if autoRefreshCheckbox.state == NSOnState {
            
            telemetryFetchTimer = Timer.scheduledTimer(
                timeInterval: Double(interval),
                target: self,
                selector: #selector(handleAutoRefreshCheckboxAction(sender:)),
                userInfo: nil,
                repeats: true)
            

            // And fetch the telemetry right now
            
            handleRefreshButtonAction(sender: nil)
        }
    }
    
    
    @IBAction func handleIntervalTextFieldAction(sender: AnyObject?) {
        handleAutoRefreshCheckboxAction(sender: nil)
    }
}
