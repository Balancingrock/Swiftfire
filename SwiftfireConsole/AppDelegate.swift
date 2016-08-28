// =====================================================================================================================
//
//  File:       AppDelegate.swift
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
// v0.9.14 - Upgraded to Xcode 8 beta 6
//         - Major update: split main window tab into several window/controller combinations.
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.12 - Added initialization of the statisticsWindowController in the statistics object.
//         - Added conformance to GuiRequest protocol
//         - Moved testcontent generation to Statistics
// v0.9.11 - Added statistics
//         - Merged into Swiftfire project
// v0.9.4  - Header update
// v0.9.1  - Minor changes to accomodate changes in SwifterSockets/SwifterLog/SwifterJSON
// v0.9.0  - Initial release
// =====================================================================================================================

import Cocoa
import CoreData


func showErrorInKeyWindow(message: String) {
    
    if let window = NSApp.keyWindow {
        
        DispatchQueue.main.async {
            
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = message
            alert.addButton(withTitle: "Dismiss")
            alert.beginSheetModal(for: window, completionHandler: nil)
        }
        
    }
    else {
        log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not send error message '\(message)' to key window")
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var windowController: ConsoleWindowViewController!


    func applicationDidFinishLaunching(_ notification: Notification) {
        
        log.aslFacilityRecordAtAndAboveLevel = SwifterLog.Level.none
        log.fileRecordAtAndAboveLevel = SwifterLog.Level.none
        log.stdoutPrintAtAndAboveLevel = SwifterLog.Level.debug
        log.networkTransmitAtAndAboveLevel = SwifterLog.Level.none
        log.callbackAtAndAboveLevel = SwifterLog.Level.none
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    // MARK: - Server Parameters Window
    
    var serverParametersWindowController: ServerParametersWindowController?
    
    @IBAction func serverParametersWindow(sender: AnyObject?) {
        if serverParametersWindowController == nil {
            serverParametersWindowController = ServerParametersWindowController(windowNibName: "ServerParametersWindow")
        }
        serverParametersWindowController!.showWindow(nil)
    }
    
    
    // MARK: - Server Telemetry Window

    var serverTelemetryWindowController: ServerTelemetryWindowController?

    @IBAction func serverTelemetryWindow(sender: AnyObject?) {
        if serverTelemetryWindowController == nil {
            serverTelemetryWindowController = ServerTelemetryWindowController(windowNibName: "ServerTelemetryWindow")
        }
        serverTelemetryWindowController!.showWindow(nil)
    }
    
    
    // MARK: - Server Log Window

    var logWindowController: LogWindowController?

    @IBAction func serverLogWindow(sender: AnyObject?) {
        if logWindowController == nil {
            logWindowController = LogWindowController(windowNibName: "LogWindow")
        }
        logWindowController!.showWindow(nil)
    }
    
    
    // MARK: - Domains Window

    var domainsWindowController: DomainsWindowController?

    @IBAction func domainsWindow(sender: AnyObject?) {
        if domainsWindowController == nil {
            domainsWindowController = DomainsWindowController(windowNibName: "DomainsWindow")
        }
        domainsWindowController!.showWindow(nil)
    }
    
    
    // MARK: - Statistics Window
    
    var statisticsWindowController: StatisticsWindowController?

    @IBAction func statisticsWindow(sender: AnyObject?) {
        if statisticsWindowController == nil {
            statisticsWindowController = StatisticsWindowController(windowNibName: "StatisticsWindow")
        }
        statisticsWindowController!.showWindow(nil)
    }
    
    
    // MARK: - Blacklists Window
    
    var blacklistWindowController: BlacklistWindowController?

    @IBAction func blacklistsWindow(sender: AnyObject?) {
        if blacklistWindowController == nil {
            blacklistWindowController = BlacklistWindowController(windowNibName: "BlacklistWindow")
        }
        blacklistWindowController!.showWindow(nil)
    }
    
    
    var historyControllers: Dictionary<String, HistoricalUsageWindowController> = [:]
    
    func displayHistory(pathPart: CDPathPart) {
        if let hwc = historyControllers[pathPart.pathPart!] {
            hwc.showWindow(nil)
        }
        else {
            let hwc = HistoricalUsageWindowController(pathPart: pathPart)
            historyControllers[pathPart.pathPart!] = hwc
            hwc.showWindow(nil)
        }
    }
}

