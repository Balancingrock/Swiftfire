// =====================================================================================================================
//
//  File:       Logfile.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2019 Marinus van der Lugt, All rights reserved.
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


/// A base class to be used for logging purposes.

class Logfile {

    
    /// Options for the Logfile initializer
    
    enum InitOption {
        
        
        /// When a logfile has become larger than this number (in KBytes), a new logfile will be started.
        
        case maxFileSize(Int)
        
        
        /// When a new logfile is created and there are more files in the logfile directory than this number (exclusing hidden files), the oldest file will be deleted.
        /// - Note: This assumes that the filename is a unique string among the other filenames in the logfile directory. The oldest file is determined through sorting of the files containing the 'filename' string.
        
        case maxNofFiles(Int)
        
        
        /// A new logfile will be started -when necessary- every time this time elapses. Notice that when no log entries are made, no file will be created. There will be no creep in the starttime. The wallclock time uses the current calendar.
        
        case newFileAfterDelay(WallclockTime)
        
        
        /// Starts a new logfile daily at the specified wallclock time.
        
        case newFileDailyAt(WallclockTime)
    }

    
    /// The queue on which all file logging activity will take place
    
    private static let queue = DispatchQueue(label: "Logfile Sync Queue", qos: .background, attributes: DispatchQueue.Attributes(), autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    
    
    /// The date formatter used to generate filenames
    
    static var dateFormatter: DateFormatter = {
        let ltf = DateFormatter()
        ltf.dateFormat = "yyyy-MM-dd'T'HH.mm.ss.SSSZ"
        return ltf
    }()

    
    /// The actual file handle, note that this parameter will be set to nil when a file is closed.
    ///
    /// The recording function has to evaluate the presence of a filehandle without the side effect of creating one.
    /// Hence the split implementation of this member.
    
    private var _fileHandle: FileHandle?
    
    
    /// The first part of the name of the logfiles
    
    private(set) var filename: String
    
    
    /// The file extension of the logfiles
    
    private(set) var fileExtension: String
    
    
    /// The URL of the directory the logfiles are located
    
    private(set) var directory: URL
    
    
    /// The maximum filesize of a logfile (in bytes)
    
    private(set) var maxFileSize: Int?
    
    
    /// The maximum number of logfiles
    
    private(set) var maxNofFiles: Int?
    
    
    /// The time at which a new logfile is started every day
    
    private(set) var newFileDailyAt: WallclockTime? {
        didSet {
            self.nextDailyFileAt = (newFileDailyAt == nil) ? nil : Date.firstFutureDate(with: newFileDailyAt!)
        }
    }
    
    
    /// The next daily logfile creation
    
    private(set) var nextDailyFileAt: Date?
    
    
    /// The delay between new logfiles
    
    private(set) var newFileAfterDelay: WallclockTime? {
        didSet {
            self.nextDelayedFileAt = (newFileAfterDelay == nil) ? nil : Date() + newFileAfterDelay!
        }
    }
    
    
    /// The time when the next logfile must be created
    
    private(set) var nextDelayedFileAt: Date?
    
    
    /// Creates a new logfile(s) object with the given name, extension and location. The filenames of the logfiles will follow the pattern: <filename>_<date>T<time><zone>.<extension>. Where date will be "yyyy-MM-dd" such that the files will appear sorted in directory listings.
    ///
    /// - Parameters:
    ///   - name: The first name part of the logfiles. Default is 'logfile'.
    ///   - ext: The file extension of the logfiles. default is 'txt'.
    ///   - dir: The URL of the directory in which the logfiles will be created.
    ///   - options: A series of option enums that will be processed in order, hence last-come overrides earlier same-option settings.
    
    init(name: String = "logfile", ext: String = "txt", dir: URL, options: InitOption ...) {
        
        self.filename = name
        self.fileExtension = ext
        self.directory = dir
        
        for option in options {
            
            switch option {
                
            case let .maxFileSize(size):
                self.maxFileSize = size * 1024
                
            case let .maxNofFiles(num):
                self.maxNofFiles = num
                
            case let .newFileAfterDelay(delay):
                self.newFileAfterDelay = delay
                self.nextDelayedFileAt = Date() + delay
                
            case let .newFileDailyAt(time):
                self.newFileDailyAt = time
                self.nextDailyFileAt = Date.firstFutureDate(with: time)
            }
        }
    }
}



extension Logfile {
    
    
    /// Returns the current file handle if there is one, or creates a new one if necessary.
    
    private var fileHandle: FileHandle? {
        
        if _fileHandle == nil {
            
            // Create the file
            
            if let fileUrl = fileUrl {
                
                if FileManager.default.createFile(atPath: fileUrl.path, contents: nil, attributes: [FileAttributeKey(rawValue: FileAttributeKey.posixPermissions.rawValue) : NSNumber(value: 0o640)]) {
                    _fileHandle = FileHandle(forUpdatingAtPath: fileUrl.path)
                    if let startData = createFileStart()?.data(using: String.Encoding.utf8, allowLossyConversion: true) { _fileHandle?.write(startData) }
                    //_filepathForNotice = fileUrl.path
                } else {
                    _fileHandle = nil
                }
                
                
                // Check if there are more than MaxNofFiles in the logfile directory, if so, remove the oldest
                
                if maxNofFiles != nil {
                    
                    // Get all files that are not hidden
                    
                    if let files = try? FileManager.default.contentsOfDirectory(at: directory as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions()) {
                        
                        
                        // Remove all files that do not contain the choosen filename
                        
                        let onlyLogfiles = files.compactMap({$0.path.contains(filename) ? $0 : nil})
                        
                        if onlyLogfiles.count > maxNofFiles! {
                            let sortedLogfiles = onlyLogfiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                            try? FileManager.default.removeItem(at: sortedLogfiles.first!)
                        }
                    }
                }
                
            } else {
                _fileHandle = nil
            }
        }
        return _fileHandle
    }
    
    
    /// Create a new filename based on the current time.
    
    private var fullFilename: String {
        return filename + "_" + Logfile.dateFormatter.string(from: Date()) +  "." + fileExtension
    }
    
    
    // Create a new file URL
    
    private var fileUrl: URL? {
        return directory.appendingPathComponent(fullFilename)
    }
    
    
    // Keep track of the most recent created file
    
    //private(set) var _filepathForNotice: String?
    
    
    /// Close the current logfile immediately (if any)
    ///
    /// - Parameter optional: A closure that will be executed immediately before the file is closed. This closure is intended to clean up or reinitialize members when the file is closed. If close, flush or record is called from within the closure, a deadlock will occur.
    
    private func _close(cleanup: (() -> ())? = nil) {
        
        cleanup?()
        
        if let file = self._fileHandle {
            file.seekToEndOfFile()
            if let endData = createFileEnd()?.data(using: String.Encoding.utf8, allowLossyConversion: true) { file.write(endData) }
            file.closeFile()
            self._fileHandle = nil
            //self._filepathForNotice = nil
        }
    }

}


// MARK: - Operational

extension Logfile {
    
    /// Close the logfile.
    ///
    /// - Note: This method will block until the file has been closed (it is safe to 'nil' a logger object afterwards)
    /// - Note: If a new 'record' call is made after this operation was called then a new logfile will be created.
    ///
    /// - Parameter cleanup: A closure that will be executed immediately before the file is closed. This closure is intended to clean up or reinitialize members when the file is closed. If close, flush or record is called from within the closure, a deadlock will occur.
    
    func close(cleanup: (() -> ())? = nil) {
        Logfile.queue.sync() { [weak self] in self?._close(cleanup: cleanup) }
    }
    
    
    /// Force possible buffer content to permanent storage
    
    func flush() {
        
        Logfile.queue.sync() { [weak self] in self?._fileHandle?.synchronizeFile() }
    }
    
    
    /// Records the given string in the current logfile. Will create a new logfile if neccesary.
    
    @objc
    func record(message: String) {
        
        Logfile.queue.sync(execute: {
            
            [weak self] in
            
            guard let `self` = self else { return }
            
            // Implementation detail: Almost everything is done in this operation, from file creation to recording to closing and deleting. And since all invokations are placed on the queue, this guarantees thread safety. An alternative solution would be to use timers for the timed-renewal of the files, that would be slightly more efficient.
            
            // If the file exists, check if a new file must be created based on the present options for file renewal
            
            if let file = self._fileHandle { // Don't want side effect of creating a new fileHandle
                
                let now = Date() // Caching current time
                
                
                // Close the current file if it is bigger than a maxFileSize assuming that maxFileSize is set.
                
                let fileSize = file.seekToEndOfFile()
                if let maxSize = self.maxFileSize, fileSize > UInt64(maxSize) { self._close() }
                
                
                // If the daily time has been set, and is in the past, then close the current file.
                
                if let newFileDailyAt = self.newFileDailyAt {
                    
                    if self.nextDailyFileAt!.compare(now) == ComparisonResult.orderedAscending {
                        
                        self._close()
                        
                        self.nextDailyFileAt = Date.firstFutureDate(with: newFileDailyAt)
                    }
                }
                
                
                // If the delay was set, and is in the past, then close the current file.
                
                if let newFileAfterDelay = self.newFileAfterDelay {
                    
                    if self.nextDelayedFileAt!.compare(now) == ComparisonResult.orderedAscending {
                        
                        self._close()
                        
                        // Increase the time for the next new file, and make sure it is after the current time.
                        
                        while self.nextDelayedFileAt!.compare(now as Date) == ComparisonResult.orderedAscending {
                            self.nextDelayedFileAt! = self.nextDelayedFileAt! + newFileAfterDelay
                        }
                    }
                }
            }
            
            if let file = self.fileHandle { // Want the side effect of creating a new fileHandle (if necessary or possible)
                
                if let data = message.data(using: String.Encoding.utf8, allowLossyConversion: true) {
                    file.write(data)
                }
            }
            
        })
    }
    
    
    /// Use this function to create the first bit of data that will be prepended to any file that is opened.
    ///
    /// Override this function to create a header when a new logfile is openend.
    
    func createFileStart() -> String? { return nil }
    
    
    /// Use this function to create the last bit of data that will be appened to any file that is closed.
    ///
    /// Override this function to add a footer when a logfile is closed.
    
    func createFileEnd() -> String? { return nil }
}
