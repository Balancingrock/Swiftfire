// =====================================================================================================================
//
//  File:       ConsoleWindowViewController.swift
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
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you may also send me a gift from my amazon.co.uk
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
// v0.9.14 - Upgraded to Xcode 8 beta 6
//         - Major update (effects everything)
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.11 - Merged into Swiftfire project
// v0.9.5  - Minor updates to accomodate parameter updates on Swiftfire
// v0.9.4  - Header update
//         - Added detection of closing of the M&C connection
//         - Added 'reset telemetry' button to domain tab
// v0.9.3  - Changed due to new M&C interface
// v0.9.2  - Added DomainTelemetry
// v0.9.1  - Minor adjustment to acomodate changes in SwifterLog
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation
import Cocoa


// Error messages

private let MISSING_SERVER_ADDRESS_OR_PORT = "Please provide the IP address and Port number of the server first"
private let NO_CONNECTION_AVAILABLE = "Swiftfire Server not connected."


// Button titles

private let CONNECT = "Connect"
private let DISCONNECT = "Disconnect"


// The main window controller.

final class ConsoleWindowViewController: NSViewController {

    
    let swiftfireStatus: NSManagedObject? = {
        let fetchRequest = NSFetchRequest<SCTelemetry>(entityName: "SCTelemetry")
        fetchRequest.predicate = NSPredicate(format: "name == %@", ServerTelemetryName.serverStatus.rawValue)
        do {
            let items = try consoleData.context.fetch(fetchRequest)
            if items.count != 1 { return nil }
            return items[0]
        } catch { return nil }
    }()
    
    
    let swiftfireVersion: NSManagedObject? = {
        let fetchRequest = NSFetchRequest<SCTelemetry>(entityName: "SCTelemetry")
        fetchRequest.predicate = NSPredicate(format: "name == %@", ServerTelemetryName.serverVersion.rawValue)
        do {
            let items = try consoleData.context.fetch(fetchRequest)
            if items.count != 1 { return nil }
            return items[0]
        } catch { return nil }
    }()

    
    dynamic var swiftfireAddress: String = "127.0.0.1"
    
    dynamic var swiftfirePort: String = "2043"
    
    dynamic var swiftfireTimeout: Int = 30
    
    func serverAddressAndPort() -> (ip: String, port: String)? {
        guard swiftfireAddress.characters.count != 0 else { return nil }
        guard swiftfirePort.characters.count != 0 else { return nil }
        return (swiftfireAddress, swiftfirePort)
    }

    @IBOutlet weak var connectButton: NSButton!
    
    @IBAction func connectButtonAction(sender: AnyObject?) {
        
        if connectButton.title == CONNECT {
        
            if !smi.communicationIsEstablished {
            
                if let (address, port) = serverAddressAndPort() {
                    smi.openConnectionToAddress(address: address, onPortNumber: port)
                } else {
                    showErrorInKeyWindow(message: MISSING_SERVER_ADDRESS_OR_PORT)
                    return
                }
                
                if !smi.communicationIsEstablished { return }
            }
            
            connectButton.title = DISCONNECT

            swiftfireStatus?.setValue(" ", forKey: "value")
            swiftfireVersion?.setValue(" ", forKey: "value")
            
            toSwiftfire?.transfer(ReadServerTelemetryCommand(telemetryName: ServerTelemetryName.serverStatus))
            toSwiftfire?.transfer(ReadServerTelemetryCommand(telemetryName: ServerTelemetryName.serverVersion))
        
        } else {
            
            smi.closeConnection()
            macConnectionClosed()
        }
    }
    
    @IBAction func startButtonAction(sender: AnyObject?) {
        // Send three commands: start, wait, read status.
        if let toSwiftfire = toSwiftfire {
            swiftfireStatus?.setValue(" ", forKey: "value")
            toSwiftfire.transfer(ServerStartCommand())
            toSwiftfire.transfer(DeltaCommand(delay: 5))
            toSwiftfire.transfer(ReadServerTelemetryCommand(telemetryName: ServerTelemetryName.serverStatus))
        }
        else {
            showErrorInKeyWindow(message: NO_CONNECTION_AVAILABLE)
        }
    }
    
    @IBAction func stopButtonAction(sender: AnyObject?) {
        // Send three commands: stop, wait, read status.
        if let toSwiftfire = toSwiftfire {
            swiftfireStatus?.setValue(" ", forKey: "value")
            toSwiftfire.transfer(ServerStopCommand())
            toSwiftfire.transfer(DeltaCommand(delay: 5)!)
            toSwiftfire.transfer(ReadServerTelemetryCommand(telemetryName: ServerTelemetryName.serverStatus))
        }
        else {
            showErrorInKeyWindow(message: NO_CONNECTION_AVAILABLE)
        }
    }
    
    @IBAction func quitSwiftfireServerButtonAction(sender: AnyObject?) {
        if let toSwiftfire = toSwiftfire {
            toSwiftfire.transfer(ServerQuitCommand())
        }
        else {
            showErrorInKeyWindow(message: NO_CONNECTION_AVAILABLE)
        }
    }

    
    /// Updates the GUI when the connection to swiftfire has been closed.
    
    func macConnectionClosed() {
        swiftfireVersion?.setValue(" ", forKey: "value")
        swiftfireStatus?.setValue(" ", forKey: "value")
        connectButton.title = CONNECT
    }
}
