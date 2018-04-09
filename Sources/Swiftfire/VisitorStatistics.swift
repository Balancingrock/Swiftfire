// =====================================================================================================================
//
//  File:       VisitorStatistics.swift
//  Project:    Swiftfire
//
//  Version:    0.10.12
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// 0.10.12 - Initial release
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

fileprivate let receivedColumn = ColumnSpecification(type: .int64, name: receivedColumnName, byteCount: 8)
fileprivate let completedColumn = ColumnSpecification(type: .int64, name: completedColumnName, byteCount: 8)
fileprivate let urlColumn = ColumnSpecification(type: .array, name: urlColumnName, byteCount: 512)
fileprivate let addressColumn = ColumnSpecification(type: .crcString, name: addressColumnName, byteCount: 49)
fileprivate let sessionColumn = ColumnSpecification(type: .uuid, name: sessionColumnName, byteCount: 16)
fileprivate let accountColumn = ColumnSpecification(type: .crcString, name: accountColumnName, byteCount: 54)
fileprivate let responseCodeColumn = ColumnSpecification(type: .crcString, name: responseCodeColumnName, byteCount: 48)
fileprivate let entryUuidColumn = ColumnSpecification(type: .uuid, name: entryUuidColumnName, byteCount: 16)

fileprivate let visitorDbColumns: Array<ColumnSpecification> = [receivedColumn, completedColumn, urlColumn, addressColumn, sessionColumn, accountColumn, responseCodeColumn, entryUuidColumn]

fileprivate let receivedColumnIndex = 0
fileprivate let completedColumnIndex = 1
fileprivate let urlColumnIndex = 2
fileprivate let addressColumnIndex = 3
fileprivate let sessionColumnIndex = 4
fileprivate let accountColumnIndex = 5
fileprivate let responseCodeColumnIndex = 6
fileprivate let entryUuidColumnIndex = 7


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
            Log.atError?.log(
                message: "Column should be present",
                from: Source(id: -1, file: #file, type: "VisitorStatistics", function: #function, line: #line)
            )
            return
        }
        
        switch columnIndex {
            
        case receivedColumnIndex: portal.int64 = received
            
        case completedColumnIndex: portal.int64 = completed

        case urlColumnIndex:
            
            let parts = url.components(separatedBy: "/")
            let arr = BrbonArray(content: parts, type: .string)
            let am = ItemManager.createArrayManager(arr)
            portal.assignField(at: portal.index!, in: portal.column!, fromManager: am)
            
            
        case addressColumnIndex: portal.crcString = address.crcString
        case sessionColumnIndex: portal.uuid = session
        case accountColumnIndex: portal.crcString = account?.crcString ?? "None".crcString
        case responseCodeColumnIndex: portal.crcString = responseCode.rawValue.crcString
        case entryUuidColumnIndex: portal.uuid = uuid

        default:
            Log.atError?.log(
                message: "Unknown column index \(columnIndex)",
                from: Source(id: -1, file: #file, type: "VisitorStatistics", function: #function, line: #line)
            )
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
            Log.atError?.log(
                message: "Could not create directory at \(dirurl.path), message = \(error.localizedDescription)",
                from: Source(id: -1, file: #file, type: "VisitorStatistics", function: #function, line: #line)
            )
        }
        return dirurl
    }

    
    /// The URL for the request recordings directory
    
    private var requestRecordingDir: URL {
        let dirurl = directory.appendingPathComponent("requests")
        do {
            try FileManager.default.createDirectory(at: dirurl, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            Log.atError?.log(
                message: "Could not create directory at \(dirurl.path), message = \(error.localizedDescription)",
                from: Source(id: -1, file: #file, type: "VisitorStatistics", function: #function, line: #line)
            )
        }
        return dirurl
    }
    
    
    /// The URL for the response recordings directory
    
    private var responseRecordingDir: URL {
        let dirurl = directory.appendingPathComponent("responses")
        do {
            try FileManager.default.createDirectory(at: dirurl, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            Log.atError?.log(
                message: "Could not create directory at \(dirurl.path), message = \(error.localizedDescription)",
                from: Source(id: -1, file: #file, type: "VisitorStatistics", function: #function, line: #line)
            )
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
        
        self.dbase = ItemManager.createTableManager(columns: visitorDbColumns, name: nil, initialRowAllocation: 1000, minimalBufferIncrement: 0, endianness: machineEndianness)
        
    }
    
    
    public func close() {
        
        do {
            try dbase.data.write(to: visitorStatisticsUrl)
        } catch let error {
            Log.atError?.log(
                message: "Cannot write visitor log to directory: \(directory), error = (\(error.localizedDescription))",
                from: Source(id: -1, file: #file, type: "VisitorStatistics", function: #function, line: #line)
            )
        }

        Log.atNotice?.log(
            message: "Domain statistics saved",
            from: Source(id: -1, file: #file, type: "VisitorStatistics", function: #function, line: #line)
        )
    }
    
    private func restartVisitorStatistics() {
        
        
        // First write the old visitor database to file
        
        do {
            try dbase.data.write(to: visitorStatisticsUrl)
        } catch let error {
            Log.atError?.log(
                message: "Cannot write visitor log to directory: \(directory), error = (\(error.localizedDescription))",
                from: Source(id: -1, file: #file, type: "VisitorStatistics", function: #function, line: #line)
            )
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
        dm.root.updateValue(visit.url, forName: "url")
        dm.root.updateValue(visit.request, forName: "request")
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
        dm.root.updateValue(visit.url, forName: "url")
        dm.root.updateValue(visit.responseData, forName: "response")
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
