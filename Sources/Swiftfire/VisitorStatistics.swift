// =====================================================================================================================
//
//  File:       VisitorStatistics.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
//  Like you, I need to make a living:
//
//   - You can send payment (you choose the amount) via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (again: rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation
import BRUtils
import Http
import SwifterLog
import BRBON


// Layout of the visitor statistics database
//
// Root (table, rowByteCount = ca 620 bytes)
//    received: Int64 (valueByteCount = 8)
//    completed: Int64 (valueByteCount = 8)
//    url: Array (type: crcString, valueByteCount = 512)
//    address: crcString (characters = 45 => valueByteCount = 54)
//    session: UUID (valueByteCount = 16)
//    account: crcString (valueByteCount = 38 uuid + 8 = 46)
//    response code: crcString (characters = 40 => valueByteCount = 48)
//    entryUuid: UUID (valueByteCount = 16)

fileprivate let receivedColumnName = NameField("Received")!
fileprivate let completedColumnName = NameField("Completed")!
fileprivate let urlColumnName = NameField("Url")!
fileprivate let addressColumnName = NameField("Address")!
fileprivate let sessionColumnName = NameField("Session")!
fileprivate let accountColumnName = NameField("Account")!
fileprivate let responseCodeColumnName = NameField("ResponseCode")!
fileprivate let entryUuidColumnName = NameField("EntryUuid")!

fileprivate let visitsTableTemplate: ItemManager = {
    let receivedColumn = ColumnSpecification(type: .int64, nameField: receivedColumnName, byteCount: 8)
    let completedColumn = ColumnSpecification(type: .int64, nameField: completedColumnName, byteCount: 8)
    let urlColumn = ColumnSpecification(type: .array, nameField: urlColumnName, byteCount: 512)
    let addressColumn = ColumnSpecification(type: .crcString, nameField: addressColumnName, byteCount: 49)
    let sessionColumn = ColumnSpecification(type: .uuid, nameField: sessionColumnName, byteCount: 16)
    let accountColumn = ColumnSpecification(type: .crcString, nameField: accountColumnName, byteCount: 54)
    let responseCodeColumn = ColumnSpecification(type: .crcString, nameField: responseCodeColumnName, byteCount: 48)
    let entryUuidColumn = ColumnSpecification(type: .uuid, nameField: entryUuidColumnName, byteCount: 16)
    var columns: Array<ColumnSpecification> = [receivedColumn, completedColumn, urlColumn, addressColumn, sessionColumn, accountColumn, responseCodeColumn, entryUuidColumn]
    return ItemManager.createTableManager(columns: &columns, initialRowsAllocated: 1, endianness: machineEndianness)
}()

fileprivate var receivedColumnIndex: Int! = { return visitsTableTemplate.root.tableColumnIndex(for: receivedColumnName) }()
fileprivate let completedColumnIndex: Int! = { return visitsTableTemplate.root.tableColumnIndex(for: completedColumnName) }()
fileprivate let urlColumnIndex: Int! = { return visitsTableTemplate.root.tableColumnIndex(for: urlColumnName) }()
fileprivate let addressColumnIndex: Int! = { return visitsTableTemplate.root.tableColumnIndex(for: addressColumnName) }()
fileprivate let sessionColumnIndex: Int! = { return visitsTableTemplate.root.tableColumnIndex(for: sessionColumnName) }()
fileprivate let accountColumnIndex: Int! = { return visitsTableTemplate.root.tableColumnIndex(for: accountColumnName) }()
fileprivate let responseCodeColumnIndex: Int! = { return visitsTableTemplate.root.tableColumnIndex(for: responseCodeColumnName) }()
fileprivate let entryUuidColumnIndex: Int! = { return visitsTableTemplate.root.tableColumnIndex(for: entryUuidColumnName) }()


struct Visit {
    
    
    // Time of receipt in milliseconds since 1 Jan 1970
    
    let received: Int64
    
    
    // Time of completion in milliseconds since 1 Jan 1970
    
    let completed: Int64
    
    
    // The URL that was requested
    
    let url: String
    
    
    // The IP address of the client
    
    let address: String
    
    
    // The session id of the request
    
    let session: UUID?

    
    // The account (if any)
    
    let account: String?
    
    
    // The result
    
    let responseCode: Response.Code
    
    
    // The UUID stamp for this visit
    
    let uuid: UUID
    
    
    // The full response
    
    var responseData: Data?
    
    
    // The full request
    
    var request: Data?

    
    init(
        received: Int64,
        completed: Int64,
        url: String,
        address: String,
        session: UUID?,
        account: String?,
        responseCode: Response.Code,
        request: Data?,
        responseData: Data?) {
    
        self.received = received
        self.completed = completed
        self.url = url
        self.address = address
        self.session = session
        self.account = account
        self.responseCode = responseCode
        self.request = request
        self.responseData = responseData
        self.uuid = UUID()
    }
    
    
    func writeToTableFields(portal: Portal) {
        
        guard let columnIndex = portal.column else {
            Log.atError?.log("Column should be present", type: "VisitorStatistics")
            return
        }
        
        switch columnIndex {
            
        case receivedColumnIndex:
            
            portal.int64 = received
            
            
        case completedColumnIndex:
            
            portal.int64 = completed

        case urlColumnIndex:
            
            let parts = url.components(separatedBy: "/")
            let am = ItemManager.createArrayManager(values: parts)
            portal.assignField(atRow: portal.index!, inColumn: portal.column!, fromManager: am)
            
            
        case addressColumnIndex:
            
            portal.crcString =  BRCrcString(address)


        case sessionColumnIndex:
            
            portal.uuid = session
        
        
        case accountColumnIndex:
            
            portal.crcString = BRCrcString(account ?? "None")


        case responseCodeColumnIndex:
            
            portal.crcString = BRCrcString(responseCode.rawValue)


        case entryUuidColumnIndex:
            
            portal.uuid = uuid

            
        default:
            Log.atError?.log("Unknown column index \(columnIndex)", type: "VisitorStatistics")
            return
        }
    }
}


final class VisitorStatistics {
    
    
    /// The BRBON store
    
    private let dbase: ItemManager
    
    
    /// Maximum number of rows in the dbase
    
    private let maxRowCount: Int
    
    
    /// The queue on which this visitor statistics instance runs
    
    private let queue: DispatchQueue = DispatchQueue(label: "VisitorStatistics")
    
    
    /// The number of most recent requests that are recorded.
    ///
    /// Set to zero (default) to not keep any requests at all.
    
    public var nofRecentRequests: Int = 0
    
    
    /// The number of most recent responses that are recorded.
    ///
    /// Set to zero (default) to not keep any responses at all.
    
    public var nofRecentResponses: Int = 0
    
    
    /// The time at which a new logfile is started every day
    
    public private(set) var timeForDailyLogRestart: WallclockTime {
        didSet {
            nextDailyFileAt = Date.firstFutureDate(with: timeForDailyLogRestart)
        }
    }

    
    /// The time for the next logfile
    
    private var nextDailyFileAt: Date
    
    
    /// The directory to which the statistics and recordings are written
    
    private let directory: URL

    
    /// The URL for the visitor statistics directory
    
    private var visitorStatisticsDir: URL {
        let dirurl = directory.appendingPathComponent("visits")
        do {
            try FileManager.default.createDirectory(at: dirurl, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            Log.atError?.log("Could not create directory at \(dirurl.path), message = \(error.localizedDescription)", type: "VisitorStatistics")
        }
        return dirurl
    }

    
    /// The URL for the request recordings directory
    
    private var requestRecordingDir: URL {
        let dirurl = directory.appendingPathComponent("requests")
        do {
            try FileManager.default.createDirectory(at: dirurl, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            Log.atError?.log("Could not create directory at \(dirurl.path), message = \(error.localizedDescription)", type: "VisitorStatistics")
        }
        return dirurl
    }
    
    
    /// The URL for the response recordings directory
    
    private var responseRecordingDir: URL {
        let dirurl = directory.appendingPathComponent("responses")
        do {
            try FileManager.default.createDirectory(at: dirurl, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            Log.atError?.log("Could not create directory at \(dirurl.path), message = \(error.localizedDescription)", type: "VisitorStatistics")
        }
        return dirurl
    }

    
    /// Create a new name for the request recording file.
    
    private func requestRecordingURL(_ uuid: UUID) -> URL {
        let name = "Recording_\(Logfile.dateFormatter.string(from: Date()))\(uuid.uuidString).brbon"
        return requestRecordingDir.appendingPathComponent(name)
    }
    
    
    /// Create a new name for the response recording file.
    
    private func responseRecordingURL(_ uuid: UUID) -> URL {
        let name = "Response_\(Logfile.dateFormatter.string(from: Date()))\(uuid.uuidString).brbon"
        return responseRecordingDir.appendingPathComponent(name)
    }


    /// Create a new statistics file URL
    
    private var visitorStatisticsUrl: URL {
        let name = "VisitorStatistics_\(Logfile.dateFormatter.string(from: Date())).brbon"
        return visitorStatisticsDir.appendingPathComponent(name)
    }

    
    /// Create a new visitor statistics manager
    ///
    /// - Parameters:
    ///   - directory: The directory for the logfiles.
    ///   - dailyLogFileAt: The time of day when a new logfile is started.
    
    init?(directory: URL?, timeForDailyLogRestart: WallclockTime, maxRowCount: Int) {
        
        guard let directory = directory else { return nil }
        
        self.directory = directory
        self.maxRowCount = maxRowCount
        
        self.timeForDailyLogRestart = timeForDailyLogRestart
        self.nextDailyFileAt = Date.firstFutureDate(with: timeForDailyLogRestart)
        
        
        // Always create a new database
        
        self.dbase = visitsTableTemplate.copyWithRecalculatedBufferSize(ask: 1000 * visitsTableTemplate.data.count)
    }
    
    
    public func close() {
        
        do {
            try dbase.data.write(to: visitorStatisticsUrl)
        } catch let error {
            Log.atError?.log("Cannot write visitor log to directory: \(directory), error = (\(error.localizedDescription))", type: "VisitorStatistics")
        }

        Log.atNotice?.log("Domain statistics saved", type: "VisitorStatistics")
    }
    
    private func restartVisitorStatistics() {
        
        
        // First write the old visitor database to file
        
        do {
            try dbase.data.write(to: visitorStatisticsUrl)
        } catch let error {
            Log.atError?.log("Cannot write visitor log to directory: \(directory), error = (\(error.localizedDescription))", type: "VisitorStatistics")
        }
        
        
        // Clean the table
        
        dbase.root.tableReset()
    }
    
    
    /// Starts a new daily log if necessary, based on time.
    
    private func startNewDailyLogIfRequired() {
        
        let now = Date()
        
        if now.compare(nextDailyFileAt) == .orderedDescending {
            
            //restartVisitorStatistics()
            
            
            // Prime for the next daily log
            
            nextDailyFileAt = Date.firstFutureDate(with: timeForDailyLogRestart)
        }
    }
    
    
    /// Handle the recording of the request
    
    private func handleRequestLogging(_ visit: Visit) {
        
        
        // Check if recordings must be made.
        //
        // Note: By cheking "if" before "how many" the older recordings will stay in storage when recording is stopped.
        
        if nofRecentRequests == 0 { return }
        
        
        // Check if older recordings must be removed
        
        do {
            
            let files = try FileManager.default.contentsOfDirectory(
                at: requestRecordingDir,
                includingPropertiesForKeys: nil,
                options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            
            if files.count > nofRecentRequests {
                var sortedFiles = files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                try FileManager.default.removeItem(at: sortedFiles.remove(at: 0))
                // Remove another file if there are still too many
                // (this will in due time reduce the number of recordings to the desired number)
                if files.count > nofRecentRequests {
                    try FileManager.default.removeItem(at: sortedFiles.remove(at: 0))
                }
            }
        } catch {}

        
        // Make the new recording
        
        let dm = ItemManager.createDictionaryManager()
        dm.root!.updateItem(visit.url, withName: "url")
        dm.root!.updateItem(visit.request, withName: "request")
        try? dm.data.write(to: requestRecordingURL(visit.uuid))
    }
    
    
    /// Handle the recording of the response
    
    private func handleResponseLogging(_ visit: Visit) {
        
        
        // Check if recordings must be made.
        //
        // Note: By cheking "if" before "how many" the older recordings will stay in storage when recording is stopped.
        
        if nofRecentResponses == 0 { return }
        
        
        // Keep the recordings to the maximum limit
        
        do {
            
            let files = try FileManager.default.contentsOfDirectory(
                at: responseRecordingDir,
                includingPropertiesForKeys: nil,
                options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            
            if files.count > nofRecentResponses {
                var sortedFiles = files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                try FileManager.default.removeItem(at: sortedFiles.remove(at: 0))
                // Remove another file if there are still too many
                // (this will in due time reduce the number of recordings to the desired number)
                if files.count > nofRecentRequests {
                    try FileManager.default.removeItem(at: sortedFiles.remove(at: 0))
                }
            }
        } catch {}
        
        
        // Make the new recording
        
        let dm = ItemManager.createDictionaryManager()
        dm.root.updateItem(visit.url, withName: "url")
        dm.root.updateItem(visit.responseData, withName: "response")
        try? dm.data.write(to: responseRecordingURL(visit.uuid))
    }
    
    
    /// Append a new visit to the visitor log database
    
    func append(_ visit: Visit) {
        
        queue.async { [weak self] in
            
            guard let `self` = self else { return }
            

            // Check if the date rolled-over, if so, start a new logfile
        
            self.startNewDailyLogIfRequired()
        
        
            // Check if the buffer is full, if so, start a new logfile
        
            if self.dbase.root.rowCount == self.maxRowCount { self.restartVisitorStatistics() }
        
        
            // Append this visit to the logfile
        
            self.dbase.root.addRows(1, values: visit.writeToTableFields)
            
            
            // Record the request if appropriate
            
            self.handleRequestLogging(visit)
            
            
            // Record the response if appropriate
            
            self.handleResponseLogging(visit)
        }
    }
}
