// =====================================================================================================================
//
//  File:       FileLog.swift
//  Project:    Swiftfire
//
//  Version:    0.9.7
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
//
// v0.9.7 - Initial release
// =====================================================================================================================

import Foundation


class FileLog {
    
    /// Options for the FileLog initializer
    
    enum InitOption {
        
        /// When a logfile has become larger than this number (in KBytes), a new logfile will be started.
        case MaxFileSize(Int)
        
        /// When a new logfile is created and there are more files in the logfile directory than this number (exclusing hidden files), the oldest file will be deleted.
        /// - Note: This assumes that only logfiles are present in the logfile directory. The oldest file is determined through sorting of the filenames.
        case MaxNofFiles(Int)
        
        /// A new logfile will be started -when necessary- every time this time elapses. Notice that when no log entries are made, no file will be created. There will be no creep in the starttime. The wallclock time uses the current calendar.
        case NewFileAfterDelay(WallclockTime)
        
        /// Starts a new logfile daily at the specified wallclock time.
        case NewFileDailyAt(WallclockTime)
    }

    
    // The queue on which all file logging activity will take place
    
    private static let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    
    
    // A new filehandle will be created if this handle is nil
    
    private var _fileHandle: NSFileHandle?
    
    
    // The date formatter used to generate filenames (can also be used for loggin info inside the files)
    
    static var dateFormatter: NSDateFormatter = {
        let ltf = NSDateFormatter()
        ltf.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return ltf
    }()

    
    // The first part of the name of the logfiles
    
    private var filename: String
    
    
    // The file extension of the logfiles
    
    private var fileExtension: String
    
    
    // The URL of the directory the logfiles are located
    
    private var directory: NSURL
    
    
    // The maximum filesize of a logfile
    
    var maxFileSize: Int?
    
    
    // The maximum number of logfiles
    
    var maxNofFiles: Int?
    
    
    // The time at which a new logfile is started every day
    
    var newFileDailyAt: WallclockTime?
    
    
    // The delay between new logfiles
    
    var newFileAfterDelay: WallclockTime?
    
    
    // The time when the next logfile must be created
    
    var nextFileAt: NSDate?
    
    
    /**
     Creates a new logfile(s) object with the given name, extension and location. The filenames of the logfiles will follow the pattern: <filename>_<date>T<time><zone>.<extension>. Where date will be "yyyy-MM-dd" such that the files will appear sorted in the directory listings.
    
     - Parameter filename: The first name part of the logfiles. Default is 'logfile'.
     - Parameter fileExtension: The file extension of the logfiles. default is 'txt'.
     - Parameter directory: The URL of the directory in which the logfiles will be created. If 'nil' then the logfiles will be located in the 'logfiles' directory in the application's "Application Support" directory.
     - Parameter options: A series of option enums that will be processed in order, hence last-come overrides earlier settings.
     */
    
    init?(filename: String = "logfile", fileExtension: String = "txt", directory: NSURL? = nil, options: InitOption ...) {
        
        self.filename = filename
        self.fileExtension = fileExtension
        
        if directory == nil {
            
            do {
                let applicationSupportDirectory =
                    try NSFileManager.defaultManager().URLForDirectory(
                        NSSearchPathDirectory.ApplicationSupportDirectory,
                        inDomain: NSSearchPathDomainMask.UserDomainMask,
                        appropriateForURL: nil,
                        create: true).path!
                
                let appName = NSProcessInfo.processInfo().processName
                let url = NSURL(fileURLWithPath: applicationSupportDirectory, isDirectory: true).URLByAppendingPathComponent(appName).URLByAppendingPathComponent("logfiles")
                
                try NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
                
                self.directory = url
                
            } catch let error as NSError {
                
                let message: String = "Could not get application support directory, error = " + (error.localizedDescription ?? "Unknown reason")
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: message)
                return nil
            }
            
        } else {
            self.directory = directory!
        }
        
        
        for option in options {
            switch option {
            case let .MaxFileSize(size): self.maxFileSize = size
            case let .MaxNofFiles(num): self.maxNofFiles = num
            case let .NewFileAfterDelay(delay): self.newFileAfterDelay = delay
            case let .NewFileDailyAt(time): self.newFileDailyAt = time
            }
        }
    }

    
    // Create a new filename based on the current time.
    
    private var fullFilename: String {
        return filename + "_" + FileLog.dateFormatter.stringFromDate(NSDate()) +  "." + fileExtension
    }
    
    
    // Create a new file URL
    
    private var fileUrl: NSURL? {
        return directory.URLByAppendingPathComponent(fullFilename)
    }
    
    
    // Keep track of the most recent created file
    
    private var _filepathForNotice: String?
    
    
    // Returns the current file handle if there is one, creates a new one if necessary.
    
    private var fileHandle: NSFileHandle? {
        
        if _fileHandle == nil {
            
            // Create the file
            if let fileUrl = fileUrl {
                
                if NSFileManager.defaultManager().createFileAtPath(fileUrl.path!, contents: nil, attributes: [NSFilePosixPermissions : NSNumber(int: 0o640)]) {
                    _fileHandle = NSFileHandle(forUpdatingAtPath: fileUrl.path!)
                    if let startData = createFileStart() { _fileHandle?.writeData(startData) }
                    log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Created new logfile at: \(fileUrl.path!)")
                    _filepathForNotice = fileUrl.path!
                } else {
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not generate logfile at: \(fileUrl.path!)")
                    _fileHandle = nil
                }
                
                
                // Check if there are more than MaxNofFiles in the logfile directory, if so, remove the oldest
                
                if maxNofFiles != nil {
                    do {
                        let files = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(
                            directory,
                            includingPropertiesForKeys: nil,
                            options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
                        
                        if files.count > maxNofFiles! {
                            let sortedFiles = files.sort({ $0.lastPathComponent < $1.lastPathComponent })
                            try NSFileManager.defaultManager().removeItemAtURL(sortedFiles.first!)
                            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Removed oldest logfile at: \(sortedFiles.first!.path!)")
                        }
                    } catch {
                        log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not remove 'oldest' logfile")
                    }
                }
                
            } else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not retrieve logfile fileUrl")
                _fileHandle = nil
            }
        }
        return _fileHandle
    }
    
    
    /// Close the logfile.
    /// - Note: This method will block until the file has been closed (and it is safe to 'nil' the logger)
    /// - Note: If a new 'record' call is made after this operation was called then a new logfile will be created.
    
    func close() {
        dispatch_sync(FileLog.queue, { [weak self] in self?._close() })
    }
    
    
    // Close the current logfile (if any)
    
    private func _close() {
        if let file = self._fileHandle {
            log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Closed current logfile \(_filepathForNotice)")
            file.seekToEndOfFile()
            if let endData = createFileEnd() { file.writeData(endData) }
            file.closeFile()
            self._fileHandle = nil
            self._filepathForNotice = nil
        }
    }
    
    
    /// Records the given string in the current logfile. Will create a new logfile if neccesary.
    
    func record(message: String) {
        
        // Implementation detail: Almost everything is done in this operation, from file creation to recoring to closing and deleting. And since all invokations are placed on the queue, this guarantees thread safety. An alternative solution would be to use timers for the timed-renewal of the files, that would be slightly more efficient. However since the queue on which this operation takes place is a low priority queue the present implementation is good enough as it is.
        
        dispatch_async(FileLog.queue, { [unowned self] in
            
            if let file = self.fileHandle {
                
                let now = NSDate()
                
                // Close the current file if it is bigger than a maxFileSize assuming that maxFileSize is set.
                let fileSize = file.seekToEndOfFile()
                if let maxSize = self.maxFileSize where fileSize > UInt64(maxSize) { self._close() }
                
                
                // If the daily time has been set, and is in the past, then close the current file.
                if let time = self.newFileDailyAt {
                    if time >= now.wallclockTime { self._close() }
                }
                
                
                // If the delay was set, and is in the past, then close the current file.
                if self.newFileAfterDelay != nil {
                    if self.nextFileAt!.compare(now) == NSComparisonResult.OrderedAscending {
                        self._close()
                        
                        // Increase the time for the next new file, and make sure it is after the current time.
                        while self.nextFileAt!.compare(now) == NSComparisonResult.OrderedAscending {
                            self.nextFileAt! = self.nextFileAt! + self.newFileAfterDelay!
                        }
                    }
                }
            }
            
            if let file = self.fileHandle {
                
                if let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
                    file.writeData(data)
                } else {
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not convert log string to UTF8")
                }
            }
        })
    }
    
    
    /// Use this function to create the first bit of data that will be prepended to any file that is opened.
    
    func createFileStart() -> NSData? { return nil }
    
    
    /// Use this function to create the last bit of data that will be appened to any file that is closed.
    
    func createFileEnd() -> NSData? { return nil }
}