// =====================================================================================================================
//
//  File:       AppDelegate.swift
//  Project:    SwiftfireConsole
//
//  Version:    0.9.13
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/SwiftfireConsole
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
// v0.9.13 - Upgraded to Swift 3 beta
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

// Unused, must be present because of multi-target environment
var quitSwiftfire = false

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, GuiRequest {

    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var windowController: ConsoleWindowViewController!


    var statisticsWindowController: StatisticsWindowController!
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Insert code here to initialize your application
        log.aslFacilityRecordAtAndAboveLevel = SwifterLog.Level.none
        log.fileRecordAtAndAboveLevel = SwifterLog.Level.none
        log.stdoutPrintAtAndAboveLevel = SwifterLog.Level.debug
        log.networkTransmitAtAndAboveLevel = SwifterLog.Level.none
        log.callbackAtAndAboveLevel = SwifterLog.Level.none
        
        statistics.gui = self
        
        statistics.generateTestContent()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func showStatisticsWindow(sender: AnyObject?) {
        statisticsWindowController = StatisticsWindowController(windowNibName: "StatisticsWindow")
        statisticsWindowController.showWindow(nil)
        statistics.statisticsWindowController = statisticsWindowController
    }
    
    @IBAction func refreshStatistics(sender: AnyObject?) {
        let macif = windowController.swiftfireMacInterface
        let readCmd = ReadStatisticsCommand()
        log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Sending message \(readCmd.json)")
        macif?.sendMessages(messages: [readCmd.json])
    }
    
    
    var historyControllers: Dictionary<String, HistoricalUsageWindowController> = [:]
    
    func displayHistory(pathPart: CDPathPart) {
        if let hwc = historyControllers[pathPart.pathPart!] {
            hwc.showWindow(nil)
        } else {
            let hwc = HistoricalUsageWindowController(pathPart: pathPart)
            historyControllers[pathPart.pathPart!] = hwc
            hwc.showWindow(nil)
        }
    }
}

