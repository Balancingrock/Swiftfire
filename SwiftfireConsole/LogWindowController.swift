// =====================================================================================================================
//
//  File:       LogWindowController.swift
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

class LogWindowController: NSWindowController {
    
    
    @IBOutlet weak var sendLogLevelPopUpButton: NSPopUpButton!
    @IBOutlet weak var displayLogLevelPopUpButton: NSPopUpButton!
    @IBOutlet var displayTextView: NSTextView!
    
    
    override func windowDidLoad() {
        logLineWindowDataSource.windowController = self
        reloadData()
    }

    
    @IBAction func sendLogLevelPopUpButtonAction(sender: AnyObject?) {
        guard toSwiftfire != nil else {
            showErrorInKeyWindow(message: "No connection to Swiftfire")
            return
        }
        let logLevel = sendLogLevelPopUpButton.indexOfSelectedItem
        toSwiftfire?.transfer(WriteServerParameterCommand(parameter: .callbackAtAndAboveLevel, value: logLevel))
        toSwiftfire?.transfer(ReadServerParameterCommand(parameter: .callbackAtAndAboveLevel))
    }
    
    
    @IBAction func displayLogLevelPopUpButton(sender: AnyObject?) {
        if let level = SwifterLog.Level(rawValue: displayLogLevelPopUpButton.indexOfSelectedItem) {
            logLineWindowDataSource.displayLogLevel = level
        } else {
            showErrorInKeyWindow(message: "Cannot create SwifterLog.Level from popup selection \(displayLogLevelPopUpButton.indexOfSelectedItem)")
        }
    }
    
    
    @IBAction func clearDisplayButtonAction(sender: AnyObject?) {
        logLineWindowDataSource.clearLogLines()
    }
    
    
    @IBAction func saveButtonAction(sender: AnyObject?) {
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save"
        savePanel.message = "Specify a name/location for the file"
        savePanel.beginSheetModal(for: self.window!, completionHandler: { (choice: Int) in
            log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Choice = \(choice)")
            if choice == 1 {
                if let url = savePanel.url {
                    var fileContent: String = ""
                    logLineWindowDataSource.displayedLogLines.forEach() { fileContent += $0 + "\n" }
                    do { try fileContent.write(to: url, atomically: true, encoding: String.Encoding.utf8) }
                    catch let error { showErrorInKeyWindow(message: "Could not write file: \(error)") }
                } else {
                    showErrorInKeyWindow(message: "Cannot get path for file")
                }
            }
        })
    }
    
    
    func addLineToView(logLine: LogLine) {
        DispatchQueue.main.async {
            [unowned self] in
            self.displayTextView.textStorage?.beginEditing()
            self.displayTextView.textStorage?.mutableString.append("\n\(logLine)")
            self.displayTextView.textStorage?.endEditing()
            self.displayTextView.scrollToEndOfDocument(nil)
        }
    }
    
    
    func reloadData() {
        DispatchQueue.main.async {
            [unowned self] in
            self.displayTextView.textStorage?.beginEditing()
            self.displayTextView.string = ""
            for line in logLineWindowDataSource.displayedLogLines {
                self.displayTextView.textStorage?.mutableString.append("\n\(line)")
            }
            self.displayTextView.textStorage?.endEditing()
            self.displayTextView.scrollToEndOfDocument(nil)
        }
    }
}
