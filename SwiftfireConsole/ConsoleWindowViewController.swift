// =====================================================================================================================
//
//  File:       ConsoleWindowViewController.swift
//  Project:    SwiftfireConsole
//
//  Version:    0.9.1
//
//  Author:     Marinus van der Lugt
//  Website:    http://www.balancingrock.nl/swiftfire.html
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// v0.9.1 - Minor adjustment to acomodate changes in SwifterLog
// v0.9.0 - Initial release
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
        
        parameterTable = [
            ParameterTabTableRow(parameter: .DEBUG_MODE, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .SERVICE_PORT_NUMBER, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .MAX_NOF_PENDING_CLIENT_MESSAGES, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .MAX_CLIENT_MESSAGE_SIZE, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .MAX_NOF_ACCEPTED_CONNECTIONS, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .MAX_NOF_PENDING_CONNECTIONS, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .MAX_WAIT_FOR_PENDING_CONNECTIONS, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .ASL_LOGLEVEL, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .STDOUT_LOGLEVEL, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .FILE_LOGLEVEL, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .NETWORK_LOGLEVEL, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .NETWORK_LOG_TARGET_ADDRESS, swiftfireMacInterface: swiftfireMacInterface),
            ParameterTabTableRow(parameter: .NETWORK_LOG_TARGET_PORT, swiftfireMacInterface: swiftfireMacInterface)
        ]
        
        telemetryTable = [
            TelemetryTabTableRow(parameter: .NOF_ACCEPTED_CLIENTS, swiftfireMacInterface: swiftfireMacInterface),
            TelemetryTabTableRow(parameter: .NOF_HTTP_400_REPLIES, swiftfireMacInterface: swiftfireMacInterface),
            TelemetryTabTableRow(parameter: .NOF_HTTP_404_REPLIES, swiftfireMacInterface: swiftfireMacInterface),
            TelemetryTabTableRow(parameter: .NOF_HTTP_500_REPLIES, swiftfireMacInterface: swiftfireMacInterface),
            TelemetryTabTableRow(parameter: .NOF_HTTP_501_REPLIES, swiftfireMacInterface: swiftfireMacInterface),
            TelemetryTabTableRow(parameter: .NOF_HTTP_505_REPLIES, swiftfireMacInterface: swiftfireMacInterface),
            TelemetryTabTableRow(parameter: .NOF_SUCCESSFUL_HTTP_REPLIES, swiftfireMacInterface: swiftfireMacInterface),
            TelemetryTabTableRow(parameter: .NOF_RECEIVE_ERRORS, swiftfireMacInterface: swiftfireMacInterface),
            TelemetryTabTableRow(parameter: .NOF_RECEIVE_TIMEOUTS, swiftfireMacInterface: swiftfireMacInterface)
        ]

        
        let runLoopObserver = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,
            CFRunLoopActivity.BeforeWaiting.rawValue,
            true,
            0,
            { [unowned self] (_, _) -> Void in self.displayErrorMessage(); self.updateParameterValuesInGui(); self.addQueuedToAcceptedLogLines() })
        
        CFRunLoopAddObserver(CFRunLoopGetCurrent(), runLoopObserver, kCFRunLoopCommonModes)
    }
    
    
    // ***************************************************************
    // MARK: Storage for the area above the Tabs (Uses Cocoa bindings)
    // ***************************************************************
    
    let aboveTabs: AboveTabs = AboveTabs()
    
    
    // *********************************
    // MARK: Storage for the Domains tab
    // *********************************
    
    @IBOutlet weak var domainNameColumn: NSTableColumn!
    @IBOutlet weak var domainValueColumn: NSTableColumn!
    @IBOutlet weak var domainOutlineView: NSOutlineView!
    
    
    // *********************************************************
    // MARK: Storage for the Parameter Tab (Uses Cocoa Bindings)
    // *********************************************************
    
    dynamic var parameterTable = Array<ParameterTabTableRow>()

    
    // *********************************************************
    // MARK: Storage for the Telemetry Tab (Uses Cocoa Bindings)
    // *********************************************************

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
    private var parameterUpdates: Dictionary<MacDef.Parameter, VJson> = [:]
    
    private let errorMessageLockObject = NSString()
    private var errorMessageIsActive = false
    private var errorMessages: Array<String> = []
    private var previousErrorMessage: String?
}


// MARK: - For above the tabs

extension ConsoleWindowViewController {
    
    @IBAction func connectButtonAction(sender: AnyObject?) {
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
        for parameter in MacDef.Parameter.all {
            readAllParameters.append(MacDef.Command.READ.jsonHierarchyWithValue(parameter)!)
        }
        swiftfireMacInterface.sendMessages(readAllParameters)
    }
    
    @IBAction func startButtonAction(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        aboveTabs.setValue(" ", forKeyPath: "serverStatus")
        // Send three commands: start, wait 5 sec, read status.
        swiftfireMacInterface.sendMessages([
            MacDef.Command.START.jsonHierarchyWithValue(nil),
            MacDef.Command.DELTA.jsonHierarchyWithValue(1),
            MacDef.Command.READ.jsonHierarchyWithValue(MacDef.Parameter.SERVER_STATUS)
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
            MacDef.Command.STOP.jsonHierarchyWithValue(nil),
            MacDef.Command.DELTA.jsonHierarchyWithValue(1),
            MacDef.Command.READ.jsonHierarchyWithValue(MacDef.Parameter.SERVER_STATUS)
            ])
    }
    
    @IBAction func quitSwiftfireServerButtonAction(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(MISSING_SERVER_ADDRESS_OR_PORT)
            return
        }
        swiftfireMacInterface.sendMessages([MacDef.Command.QUIT.jsonHierarchyWithValue(nil)])
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
        var errorMessage: String?
        for d in domains {
            old = d.copy
            var ready: Bool
            (ready, errorMessage) = d.updateItem(item, withValue:object)
            if ready {
                new = d
                break
            }
        }
        if errorMessage != nil {
            queueErrorMessage(errorMessage!)
            return
        }
        if new != nil {
            let json = VJson.createJsonHierarchy()
            json[MacDef.Command.UPDATE.rawValue][MacDef.CommandUpdate.NEW.rawValue].addChild(new!.json)
            json[MacDef.Command.UPDATE.rawValue][MacDef.CommandUpdate.OLD.rawValue].addChild(old!.json)
            swiftfireMacInterface.sendMessages([json])

            // Re-acquire the domains
            self.swiftfireMacInterface.sendMessages([MacDef.Command.READ.jsonHierarchyWithValue(MacDef.Parameter.DOMAINS)])
        }
    }
    
    @IBAction func addDomain(sender: AnyObject?) {
        
        let domain = Domain()
        
        while domains.contains(domain.name) {
            domain.name = domain.name + ".new"
        }
        
        let command = MacDef.Command.CREATE.jsonHierarchyWithValue(domain.json)
        
        self.swiftfireMacInterface.sendMessages([command])
        
        // Re-acquire the domains
        self.swiftfireMacInterface.sendMessages([MacDef.Command.READ.jsonHierarchyWithValue(MacDef.Parameter.DOMAINS)])
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
                    let command = MacDef.Command.REMOVE.jsonHierarchyWithValue(domain.json)
                    self.swiftfireMacInterface.sendMessages([command])
                }
                // Re-acquire the domains
                self.swiftfireMacInterface.sendMessages([MacDef.Command.READ.jsonHierarchyWithValue(MacDef.Parameter.DOMAINS)])
            }
        }
        
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
        let parameter = MacDef.Parameter.CALLBACK_LOGLEVEL
        swiftfireMacInterface.sendMessages([
            MacDef.Command.WRITE.jsonHierarchyWithValue(parameter.jsonWithValue(logLevel)),
            MacDef.Command.READ.jsonHierarchyWithValue(parameter)
            ])
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
    
    // -------------------------
    // For the parameter updates
    
    func swiftfireMacInterface(swiftfireMacInterface: SwiftfireMacInterface, parameter: MacDef.Parameter, value: VJson) {
        synchronized(parameterUpdateLockObject, { [unowned self] in self.parameterUpdates[parameter] = value })
    }
    
    func updateParameterValuesInGui() {
        
        func parameterUpdateAboveTabs(parameter: MacDef.Parameter, _ value: VJson) {
            if let str = parameter.valueFromJson(value) as? String {
                switch parameter {
                case .VERSION_NUMBER: aboveTabs.setValue(str, forKeyPath: "serverVersionNumber")
                case .SERVER_STATUS: aboveTabs.setValue(str, forKeyPath: "serverStatus")
                default: break
                }
            }
        }
        
        func parameterUpdateOnParameterTab(parameter: MacDef.Parameter, _ value: VJson) {
            for row in parameterTable {
                row.updateIfParametersMatch(parameter, value: value)
            }
        }
        
        func parameterUpdateOnTelemetryTab(parameter: MacDef.Parameter, _ value: VJson) {
            for row in telemetryTable {
                row.updateIfParametersMatch(parameter, value: value)
            }
        }
        
        func parameterUpdateOnLogTab(parameter: MacDef.Parameter, _ value: VJson) {
            if let i = parameter.valueFromJson(value) as? Int {
                switch parameter {
                case .CALLBACK_LOGLEVEL: swiftfireSendLogLevelPopupButton.selectItemAtIndex(i)
                default: break
                }
            }
        }
        
        func parameterUpdateOnDomainTab(parameter: MacDef.Parameter, _ value: VJson) {
            if parameter == MacDef.Parameter.DOMAINS {
                let locDom = Domains()
                for jd in value {
                    if jd.isObject && jd.nameValue == nil && jd.nofChildren == 1 {
                        let domain = Domain(json: jd.arrayValue![0])
                        if domain != nil {
                            locDom.add(domain!)
                        }
                    }
                }
                domains.updateWithDomains(locDom)
                domainOutlineView.reloadData()
            }
        }

        synchronized(parameterUpdateLockObject, {
            [unowned self] in
            for (parameter, value) in self.parameterUpdates {
                parameterUpdateAboveTabs(parameter, value)
                parameterUpdateOnParameterTab(parameter, value)
                parameterUpdateOnTelemetryTab(parameter, value)
                parameterUpdateOnLogTab(parameter, value)
                parameterUpdateOnDomainTab(parameter, value)
            }
            
            self.parameterUpdates = [:]
        })
    }
    
    
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
    
    
    // -------------------
    // For the log display
    
    func swiftfireMacInterface(swiftfireMacInterface: SwiftfireMacInterface, logline: LogLine) {
        synchronized(queuedLogLinesLockObject, { [unowned self] in self.queuedLogLines.insert(logline, atIndex: 0) })
    }
}


// MARK: - Menu commands

extension ConsoleWindowViewController {
    
    @IBAction func handleMenuItemSaveParameters(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        swiftfireMacInterface.sendMessages([MacDef.Command.SAVE_PARAMETERS.jsonHierarchyWithValue(nil)])
    }
    
    @IBAction func handleMenuItemSaveDomains(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        swiftfireMacInterface.sendMessages([MacDef.Command.SAVE_DOMAINS.jsonHierarchyWithValue(nil)])
    }

    @IBAction func handleMenuItemRestoreParameters(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        swiftfireMacInterface.sendMessages([MacDef.Command.RESTORE_PARAMETERS.jsonHierarchyWithValue(nil)])
    }

    @IBAction func handleMenuItemRestoreDomains(sender: AnyObject?) {
        guard swiftfireMacInterface.communicationIsEstablished else {
            queueErrorMessage(NO_CONNECTION_AVAILABLE)
            return
        }
        swiftfireMacInterface.sendMessages([MacDef.Command.RESTORE_DOMAINS.jsonHierarchyWithValue(nil)])
    }
}