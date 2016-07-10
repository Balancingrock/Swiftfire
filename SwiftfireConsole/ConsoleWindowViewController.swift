// =====================================================================================================================
//
//  File:       ConsoleWindowViewController.swift
//  Project:    SwiftfireConsole
//
//  Version:    0.9.11
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
private let NO_CONNECTION_AVAILABLE = "No Swiftfire server connected.\nIf the connection has timed-out, click 'Connect' again"


// Button titles

private let startSwiftfireServerButtonTitle = "Start"
private let stopSwiftfireServerButtonTitle = "Stop"


// Above the tabs (Uses Cocoa bindings)

class AboveTabs: NSObject {
    var serverIpAddress: String = "127.0.0.1"
    var serverPortNumber: String = "2043"
    var cacConnectionTimeout: Int = 30
    var serverVersionNumber: String = "-"
    var serverStatus: String = "-"
    func serverAddressAndPort() -> (ip: String, port: String)? {
        guard serverPortNumber.characters.count != 0 else { return nil }
        guard serverIpAddress.characters.count != 0 else { return nil }
        return (serverIpAddress, serverPortNumber)
    }
}


// The main window controller, overriding super functions and storage requirements for the extensions.

class ConsoleWindowViewController: NSViewController {

    
    var swiftfireMacInterface: SwiftfireMacInterface!

    
    // Setup the runloop observer to update the GUI with messages from other threads
    
    override func viewDidLoad() {
        
        swiftfireMacInterface = SwiftfireMacInterface(delegate: self)
        
        for p in ServerParameter.all {
            parameterTable.append(ParameterTabTableRow(parameter: p, swiftfireMacInterface: swiftfireMacInterface))
        }
        
        for t in ServerTelemetryItem.all {
            telemetryTable.append(TelemetryTabTableRow(telemetryItem: t, swiftfireMacInterface: swiftfireMacInterface))
        }

        
        let runLoopObserver = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,
            CFRunLoopActivity.BeforeWaiting.rawValue,
            true,
            0,
            { [unowned self] (_, _) -> Void in
                self.processQueuedReplies()
                self.displayErrorMessage()
            })
        
        CFRunLoopAddObserver(CFRunLoopGetCurrent(), runLoopObserver, kCFRunLoopCommonModes)
    }
    
    
    // ***************************************************************
    // MARK: Storage for the area above the Tabs (Uses Cocoa bindings)
    // ***************************************************************
    
    let aboveTabs: AboveTabs = AboveTabs()
    @IBOutlet weak var connectButton: NSButton!
    
    
    // *********************************
    // MARK: Storage for the Domains tab
    // *********************************
    
    var domains = Domains()
    @IBOutlet weak var domainNameColumn: NSTableColumn!
    @IBOutlet weak var domainValueColumn: NSTableColumn!
    @IBOutlet weak var domainOutlineView: NSOutlineView!
    
    
    // *******************************************
    // MARK: Storage for the Domains Telemetry tab
    // *******************************************
    
    dynamic var domainTelemetry: Array<TelemetryItem>? = Array<TelemetryItem>()
    @IBOutlet weak var dtAutofetchCheckbox: NSButton!
    @IBOutlet weak var dtDelayBetweenAutofetches: NSTextField!
    @IBOutlet weak var dtSelectDomainPopupBox: NSPopUpButton!
    
    var domainTelemetryFetchTimer: NSTimer?

    
    // *********************************************************
    // MARK: Storage for the Parameter Tab (Uses Cocoa Bindings)
    // *********************************************************
    
    dynamic var parameterTable = Array<ParameterTabTableRow>()

    
    // ****************************************************************
    // MARK: Storage for the Server Telemetry Tab (Uses Cocoa Bindings)
    // ****************************************************************

    @IBOutlet weak var autofetchCheckbox: NSButton!
    @IBOutlet weak var delayBetweenAutoFetches: NSTextField!

    dynamic var telemetryTable = Array<TelemetryTabTableRow>()
    
    var telemetryFetchTimer: NSTimer?

    
    // *****************************
    // MARK: Storage for the Log Tab
    // *****************************
    
    @IBOutlet weak var swiftfireSendLogLevelPopupButton: NSPopUpButton!
    @IBOutlet weak var displayLogLevelPopupButton: NSPopUpButton!
    @IBOutlet var logTextView: NSTextView!
    
    private let logLinesDispatchQueue = dispatch_queue_create("log-line-queue", DISPATCH_QUEUE_SERIAL)
    private var abortReceivingLogLines = false
    
    private let queuedLogLinesLockObject = NSString()   // Dummy object to allow locking the queuedLogLines member
    private var queuedLogLines: Array<LogLine> = []     // Collects the updates from other threads until the runloop observer is triggered
    private var acceptedLogLines: Array<LogLine> = []   // Holds all LogLines

    
    // ************************************************************
    // MARK: Storage for the SwiftfireMacInterfaceDelegate protocol
    // ************************************************************
    
    private let parameterUpdateLockObject = NSString()
    private var parameterUpdates: Dictionary<ServerParameter, VJson> = [:]
    
    private let errorMessageLockObject = NSString()
    private var errorMessageIsActive = false
    private var errorMessages: Array<String> = []
    private var previousErrorMessage: String?
    
    private let queuedRepliesLockObject = NSString()
    private var queuedReplies: Array<VJson> = [] // Holds all replies from a Swiftfire server
}


// MARK: - For above the tabs

extension ConsoleWindowViewController {
    
    @IBAction func connectButtonAction(sender: AnyObject?) {
        
        if connectButton.title == "Connect" {
        
            if !swiftfireMacInterface.communicationIsEstablished {
            
                if let (address, port) = aboveTabs.serverAddressAndPort() {
                    swiftfireMacInterface.openConnectionToAddress(address, onPortNumber: port)
                } else {
                    queueErrorMessage(MISSING_SERVER_ADDRESS_OR_PORT)
                    return
                }
                
                if !swiftfireMacInterface.communicationIsEstablished {
                    queueErrorMessage("Connection failed, please check Swiftfire IP Address and Port Number")
                    return
                }
            }
            
            aboveTabs.setValue(" ", forKeyPath: "serverVersionNumber")
            aboveTabs.setValue(" ", forKeyPath: "serverStatus")
            
            var readAllParameters = Array<VJson?>()
            
            for parameter in ServerParameter.all {
                if let command = ReadServerParameterCommand(parameter: parameter) {
                    readAllParameters.append(command.json)
                }
            }
            
            for telemetryItem in ServerTelemetryItem.all {
                if let command = ReadServerTelemetryCommand(telemetryItem: telemetryItem) {
                    readAllParameters.append(command.json)
                }
            }
            
            readAllParameters.append(ReadDomainsCommand().json)
            
            swiftfireMacInterface.sendMessages(readAllParameters)
        
        } else {
            
            swiftfireMacInterface.closeConnection()

            aboveTabs.setValue(" ", forKeyPath: "serverVersionNumber")
            aboveTabs.setValue(" ", forKeyPath: "serverStatus")

            connectButton.title = "Connect"
        }
    }
    
    @IBAction func startButtonAction(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        aboveTabs.setValue(" ", forKeyPath: "serverStatus")
        // Send three commands: start, wait 5 sec, read status.
        swiftfireMacInterface.sendMessages([
            ServerStartCommand().json,
            DeltaCommand(delay: 1)!.json,
            ReadServerTelemetryCommand(telemetryItem: .SERVER_STATUS)!.json
            ])
    }
    
    @IBAction func stopButtonAction(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        aboveTabs.setValue(" ", forKeyPath: "serverStatus")
        // Send three commands: start, wait 10 sec, read status.
        swiftfireMacInterface.sendMessages([
            ServerStopCommand().json,
            DeltaCommand(delay: 1)!.json,
            ReadServerTelemetryCommand(telemetryItem: .SERVER_STATUS)!.json
            ])
    }
    
    @IBAction func quitSwiftfireServerButtonAction(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(MISSING_SERVER_ADDRESS_OR_PORT)
            return
        }
        swiftfireMacInterface.sendMessages([ServerStopCommand().json])
    }
}


// MARK: - For the Parameters Tab

extension ConsoleWindowViewController {
    
    @IBAction func getAllParametersButtonAction(sender: AnyObject?) {
        for p in parameterTable {
            p.readValueFromSwiftfireServer()
        }
    }

}


// MARK: - For the Domains Tab

extension ConsoleWindowViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil { return domains.count }
        return Domain.nofContainedItems
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        guard let ditem = item as? Domain else { return false }
        return domains.contains(ditem)
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            for (i, d) in domains.enumerate() {
                if i == index { return d }
            }
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unexpected item in call")
            return domains // should never happen
        }
        for d in domains {
            if item === d {
                if let result = d.itemForIndex(index) { return result }
                log.atLevelError(id: 0, source: #file.source(#function, #line), message: "Index out of range: \(index)")
            }
        }
        return "Index out of range error"
    }
    
    // Using "Cell Based" content mode (specify this in IB)
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        if tableColumn === domainNameColumn {
            for d in domains {
                if let title = d.titleForItem(item) { return title }
            }
        } else if tableColumn === domainValueColumn {
            for d in domains {
                if item === d { return "" }
                if let value = d.valueForItem(item) { return value }
            }
        }
        return nil
    }
    
    func outlineView(outlineView: NSOutlineView, shouldEditTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
        for d in domains {
            if let editable = d.itemIsEditable(item, inNameColumn: (tableColumn === domainNameColumn)) { return editable }
        }
        return false
    }
    
    func outlineView(outlineView: NSOutlineView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) {
        
        var old, new: Domain?
        
        var errorMessage: String? // Will be set when an update fails due to wrong arguments
        
        
        // Test each domain if contains the item to be updated
        
        for d in domains {
            old = d.copy
            var ready: Bool
            (ready, errorMessage) = d.updateItem(item, withValue: object)
            
            
            // Stop when a domain accepted the item
            
            if ready {
                new = d
                break
            }
        }
        
        if errorMessage != nil {
            
            queueErrorMessage(errorMessage!)
            
        } else if new != nil {
            
            if let command = UpdateDomainCommand(oldDomainName: old?.name, newDomain: new) {
                swiftfireMacInterface.sendMessages([command.json])
            }

            // Re-acquire the domains
            let command = ReadDomainsCommand()
            
            swiftfireMacInterface.sendMessages([command.json])
        
        } else {
            
            queueErrorMessage("Program error: Could not identify item to be updated")
        }
    }
    
    @IBAction func addDomain(sender: AnyObject?) {
        
        var domainName = "Domain.com"
        
        while domains.contains(domainName) {
            domainName = domainName + ".new"
        }
        
        if let command = CreateDomainCommand(domainName: domainName) {
        
            self.swiftfireMacInterface.sendMessages([command.json])
        
            // Re-acquire the domains
            
            self.swiftfireMacInterface.sendMessages([ReadDomainsCommand().json])
            
        } else {
            
            log.atLevelError(source: #file.source(#function, #line), message: "Failed to create CreateDomainCommand")
        }
    }
    
    @IBAction func removeDomain(sender: AnyObject?) {
        
        let selectedRows = domainOutlineView.selectedRowIndexes
        
        var selectedDomains: Array<Domain> = []
        
        for row in selectedRows {
            let item = domainOutlineView.itemAtRow(row)
            for d in domains {
                if item === d { if !selectedDomains.contains(d) { selectedDomains.append(d) }}
                else if item === d.nameItemTitle { if !selectedDomains.contains(d) { selectedDomains.append(d) }}
                else if item === d.enabledItemTitle { if !selectedDomains.contains(d) { selectedDomains.append(d) }}
                else if item === d.wwwIncludedItemTitle { if !selectedDomains.contains(d) { selectedDomains.append(d) }}
                else if item === d.rootItemTitle { if !selectedDomains.contains(d) { selectedDomains.append(d) }}
                else if item === d.forwardUrlItemTitle { if !selectedDomains.contains(d) { selectedDomains.append(d) }}
            }
        }
        
        // Ask the user if he is sure
        
        var info = "You are about to remove the following domain(s): "
        for domain in selectedDomains { info += (domain.name as String) + " " }
        
        let alert = NSAlert()
        alert.messageText = "Delete Domain(s)"
        alert.informativeText = info
        alert.addButtonWithTitle("Delete")
        alert.addButtonWithTitle("Cancel")
        
        alert.beginSheetModalForWindow(self.view.window!) { [unowned self] (response) -> Void in
            if response == NSAlertFirstButtonReturn {
                // Send one REMOVE command for each domain that is selected
                for domain in selectedDomains {
                    if let command = RemoveDomainCommand(domainName: domain.name) {
                        self.swiftfireMacInterface.sendMessages([command.json])
                    }
                }
                // Re-acquire the domains
                self.swiftfireMacInterface.sendMessages([ReadDomainsCommand().json])
            }
        }
        
    }
}


// MARK: - For the Domains Telemetry tab

extension ConsoleWindowViewController {
    
    
    /// Changes the domain for which the telemetry is displayed
    
    @IBAction func handleSelectedDomainPopupButton(sender: AnyObject?) {
        
        // Note: Error handling is implicit through the use of optionals
    
        
        // Get the name of the domain for which to display the telemetry
        
        let selectedItemTitle = dtSelectDomainPopupBox.titleOfSelectedItem
        
        
        // Get the of which the telemetry must be displayed
        
        let domain = domains.domainForName(selectedItemTitle)

        
        // Update the telemetry items (bindings are used, hence the setValue)
        
        setValue(domain?.telemetry.all, forKey: "domainTelemetry")
        
        
        // Also, read the current telemetry from the domain
        
        handleRefreshDomainTelemetryButton(nil)
    }
    
    
    /// Sends a command to read the telemetry of the selected domain.
    
    @IBAction func handleRefreshDomainTelemetryButton(sender: AnyObject?) {

        // Note: Error handling is implicit through the use of optionals

        
        // Get name of domain for which the telemetry must be requested
        
        let selectedItemTitle = dtSelectDomainPopupBox.titleOfSelectedItem
        
        
        // Create the command to read the telemetry
        
        let command = ReadDomainTelemetryCommand(domainName: selectedItemTitle)

        
        // Send the command
        
        swiftfireMacInterface.sendMessages([command?.json])
    }
    
    
    /// Enables or disables a timer-initiated command to fetch domain telemetry from Swiftfire.
    
    @IBAction func dtAutofetchCheckboxAction(sender: AnyObject?) {
        
        
        // Retrieve the interval for the timer
        
        guard let interval = Int(dtDelayBetweenAutofetches.stringValue) where interval > 0 else { return }
        
        
        // Whatever happens, we need to invalidate and remove an existing timer
        
        if domainTelemetryFetchTimer != nil {
            domainTelemetryFetchTimer!.invalidate()
            domainTelemetryFetchTimer = nil
        }
        
        
        // Create a new timer if the checkbox is switched to "on"
        
        if dtAutofetchCheckbox.state == NSOnState {
            
            domainTelemetryFetchTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(ConsoleWindowViewController.handleRefreshDomainTelemetryButton(_:)), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func dtDelayBetweenAutoFetchesUpdates(sender: AnyObject?) {
        
        if let interval = Int(dtDelayBetweenAutofetches.stringValue) {
            if interval == 0 {
                queueErrorMessage("Please provide an Autorefresh > 0")
                return
            }
        } else {
            queueErrorMessage("Please provide an Integer value > 0")
        }
        
        dtAutofetchCheckboxAction(nil)
    }
    
    @IBAction func resetTelemetryButtonAction(sender: AnyObject?) {
        
        // Get name of domain for which the telemetry must be reset
        
        let selectedItemTitle = dtSelectDomainPopupBox.titleOfSelectedItem
        
        
        // Create the command to reset the telemetry
        
        let command = ResetDomainTelemetryCommand(domainName: selectedItemTitle)
        
        
        // Send the command
        
        swiftfireMacInterface.sendMessages([command?.json])
    }
}


// MARK: - For the Telemetry Tab

extension ConsoleWindowViewController {

    @IBAction func getAllTelemetryButtonAction(sender: AnyObject?) {
        for t in telemetryTable {
            t.readValueFromSwiftfireServer()
        }
    }

    @IBAction func autofetchCheckboxAction(sender: AnyObject?) {
        
        log.atLevelDebug(id: -1, source: "ConsoleWindowViewController.autofetchCheckboxAction", message: "called")
        
        
        // Make sure the interval is valid
        
        guard let interval = Int(delayBetweenAutoFetches.stringValue) where interval > 0 else { return }
        
        
        // Whatever happens, we need to invalidate and remove an existing timer
        
        if telemetryFetchTimer != nil {
            telemetryFetchTimer!.invalidate()
            telemetryFetchTimer = nil
        }
        
        
        // Create a new timer if the checkbox is switched to "on"
        
        if autofetchCheckbox.state == NSOnState {
            
            telemetryFetchTimer = NSTimer.scheduledTimerWithTimeInterval(Double(interval), target: self, selector: #selector(ConsoleWindowViewController.getAllTelemetryButtonAction(_:)), userInfo: nil, repeats: true)
        }
    }

    @IBAction func delayBetweenAutoFetchesUpdates(sender: AnyObject?) {
        
        if let interval = Int(delayBetweenAutoFetches.stringValue) {
            if interval == 0 {
                queueErrorMessage("Please provide an Autorefresh > 0")
                return
            }
        } else {
            queueErrorMessage("Please provide an Integer value > 0")
        }
        
        autofetchCheckboxAction(nil)
    }
}


// MARK: - For the Log Tab

extension ConsoleWindowViewController {
    
    @IBAction func swiftfireSendLogLevelAction(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        let logLevel = swiftfireSendLogLevelPopupButton.indexOfSelectedItem
        let writeCommand = WriteServerParameterCommand(parameter: .CALLBACK_AT_AND_ABOVE_LEVEL, value: logLevel)!.json
        let readCommand = ReadServerParameterCommand(parameter: .CALLBACK_AT_AND_ABOVE_LEVEL)!.json
        swiftfireMacInterface.sendMessages([writeCommand, readCommand])
    }
    

    @IBAction func displayLogLevelAction(sender: AnyObject?) {
        logTextView.string = ""
        for ll in acceptedLogLines {
            addLogLineConditionallyToView(ll)
        }
    }
    
    
    @IBAction func clearLogViewAction(sender: AnyObject?) {
        logTextView.string = ""
        acceptedLogLines = []
    }

    
    // Copies loglines from the queue to the displayable loglines
    
    private func addQueuedToAcceptedLogLines() {
        synchronized(queuedLogLinesLockObject, {
            [unowned self] in
            var ll = self.queuedLogLines.popLast()
            while ll != nil {
                self.acceptedLogLines.append(ll!)
                self.addLogLineConditionallyToView(ll!)
                ll = self.queuedLogLines.popLast()
            }
        })
    }
    
    
    // Adds a logline to the view, based on the level of
    private func addLogLineConditionallyToView(ll: LogLine) {
        logTextView.font = NSFont(name: "courier", size: 12.0)
        if ll.level.rawValue >= displayLogLevelPopupButton.indexOfSelectedItem {
            logTextView.textStorage?.mutableString.appendString("\n\(ll)")
        }
    }
}


// MARK: - SwiftfireMacInterfaceDelegate

extension ConsoleWindowViewController: SwiftfireMacInterfaceDelegate {
    
    // ---------------------
    // For the error display
    
    func swiftfireMacInterface(swiftfireMacInterface: SwiftfireMacInterface, message: String) {
        synchronized(errorMessageLockObject, { [unowned self] in self.errorMessages.insert(message, atIndex: 0) })

    }
    
    func queueErrorMessage(message: String) {
        synchronized(errorMessageLockObject, { [unowned self] in self.errorMessages.insert(message, atIndex: 0) })
    }

    func displayErrorMessage() {
        
        guard !errorMessageIsActive else { return }
        
        if errorMessages.count == 0 {
            previousErrorMessage = nil
            return
        }
        
        if previousErrorMessage != nil {
            
            var message: String
            
            repeat {
                
                guard let msg = synchronized(errorMessageLockObject, { [unowned self] in return self.errorMessages.popLast() }) else { return }
                message = msg
                
            } while message != previousErrorMessage!
            
            previousErrorMessage = message
            
        } else {
            
            guard let msg = synchronized(errorMessageLockObject, { [unowned self] in return self.errorMessages.popLast() }) else { return }
            previousErrorMessage = msg
        }
        
        errorMessageIsActive = true
        
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = previousErrorMessage!
        alert.addButtonWithTitle("Dismiss")
        alert.beginSheetModalForWindow(self.view.window!, completionHandler: { [unowned self] (_) in self.errorMessageIsActive = false })
    }
    
    
    // ---------------------------
    // For messages from Swiftfire
    
    func swiftfireMacInterface(swiftfireMacInterface: SwiftfireMacInterface, reply: VJson) {
        synchronized(queuedRepliesLockObject, { [unowned self] in self.queuedReplies.insert(reply, atIndex: 0) })
    }
    
    func processQueuedReplies() {
        
        while let reply = queuedReplies.popLast() {
            
            // Check if the reply is a log line
            
            if let logLine = LogLine(json: reply) {
                
                acceptedLogLines.append(logLine)
                addLogLineConditionallyToView(logLine)
                
                
            } else if let message = ReadDomainTelemetryReply(json: reply) {
                
                processReadDomainTelemetryReply(message)
                
                
            } else if let message = ReadServerTelemetryReply(json: reply) {
                
                switch message.item {
                
                case .SERVER_VERSION:
                    aboveTabs.setValue(message.value, forKeyPath: "serverVersionNumber")
                    connectButton.title = "Disconnect"
                    
                case .SERVER_STATUS:
                    aboveTabs.setValue(message.value, forKeyPath: "serverStatus")
                
                default: break
                }

                for row in telemetryTable {
                    row.updateIfParametersMatch(message.item, value: message.value)
                }

                
            } else if let message = ReadServerParameterReply(json: reply) {
                
                for row in parameterTable {
                    row.updateIfParametersMatch(message.parameter, value: message.value)
                }

                
            } else if let message = ReadDomainsReply(json: reply) {
                
                domains.updateWithDomains(message.domains)
                
                // When updated, make sure to update the domain telemetry as well
                
                let selectedTitle = dtSelectDomainPopupBox.titleOfSelectedItem
                dtSelectDomainPopupBox.removeAllItems()
                for d in domains {
                    dtSelectDomainPopupBox.addItemWithTitle(d.name)
                }
                if selectedTitle != nil {
                    dtSelectDomainPopupBox.selectItemWithTitle(selectedTitle!)
                }
                if dtSelectDomainPopupBox.indexOfSelectedItem < 0 {
                    if domains.count > 0 {
                        dtSelectDomainPopupBox.selectItemAtIndex(0)
                    }
                }
                
                if let titleOfSelectedDomain = dtSelectDomainPopupBox.titleOfSelectedItem {
                    if let domain = domains.domainForName(titleOfSelectedDomain) {
                        setValue(domain.telemetry.all, forKey: "domainTelemetry")
                    }
                }
                
                domainOutlineView.reloadData()
                
            } else if let message = ReadStatisticsReply(json: reply) {
                
                log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Received statistics: \(reply)")
                statistics.load(message.statistics)
                

            } else if ClosingMacConnection(json: reply) != nil {
                
                aboveTabs.setValue(" ", forKeyPath: "serverVersionNumber")
                aboveTabs.setValue(" ", forKeyPath: "serverStatus")
                connectButton.title = "Connect"

            } else {
                
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Cannot decode received message: \(reply)")
            }
        }
    }
    
    private func processReadDomainTelemetryReply(reply: ReadDomainTelemetryReply) {
        
        guard let domain = domains.domainForName(reply.domainName) else {
            return
        }
        
        domain.telemetry = reply.domainTelemetry
        
        // Update the domain telemetry tab also (if the selected domain is the one in the reply)
        
        if dtSelectDomainPopupBox.titleOfSelectedItem == reply.domainName {
            setValue(reply.domainTelemetry.all, forKey: "domainTelemetry")
        }
    }
}


// MARK: - Menu commands

extension ConsoleWindowViewController {
    
    @IBAction func handleMenuItemSaveParameters(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        swiftfireMacInterface.sendMessages([SaveServerParametersCommand().json])
    }
    
    @IBAction func handleMenuItemSaveDomains(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        swiftfireMacInterface.sendMessages([SaveDomainsCommand().json])
    }

    @IBAction func handleMenuItemRestoreParameters(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        swiftfireMacInterface.sendMessages([RestoreServerParametersCommand().json])
    }

    @IBAction func handleMenuItemRestoreDomains(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        swiftfireMacInterface.sendMessages([RestoreDomainsCommand().json, ReadDomainsCommand().json])
    }
}