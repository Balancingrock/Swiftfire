// =====================================================================================================================
//
//  File:       Logfile.swift
//  Project:    Swiftfire
//
//  Version:    0.9.9
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
// v0.9.9 - Renamed FileLog to Logfile and general overhaul for publication on Swiftrien.
//        - Fixed several bugs that messed up file creation (sorry!).
//        - Changed the way in which the oldest file is determined, files are now filtered for containing the 'filename' string.
//        - Added flush operations
// v0.9.7 - Initial release
// =====================================================================================================================

import Foundation


// Implementation note: To provide the header and footer of the file an override approach was used rather than a delegate or protocol approach. This is because all file operations will be done from a dispatch queue and a callee thus does not know when the callback would occur. By using a parent/child approach we can be sure that the child will in fact exist when the footer must be provided if the callee uses "close" to flush the file to disk before nilling (deallocating) the child.

class Logfile {

    
    /// Options for the Logfile initializer
    
    enum InitOption {
        
        
        /// When a logfile has become larger than this number (in KBytes), a new logfile will be started.
        
        case MaxFileSize(Int)
        
        
        /// When a new logfile is created and there are more files in the logfile directory than this number (exclusing hidden files), the oldest file will be deleted.
        /// - Note: This assumes that the filename is a unique string among the other filenames in the logfile directory. The oldest file is determined through sorting of the files containing the 'filename' string.
        
        case MaxNofFiles(Int)
        
        
        /// A new logfile will be started -when necessary- every time this time elapses. Notice that when no log entries are made, no file will be created. There will be no creep in the starttime. The wallclock time uses the current calendar.
        
        case NewFileAfterDelay(WallclockTime)
        
        
        /// Starts a new logfile daily at the specified wallclock time.
        
        case NewFileDailyAt(WallclockTime)
    }

    
    // The queue on which all file logging activity will take place for thread-safety
    
    private static let queue = dispatch_queue_create("Logfile", DISPATCH_QUEUE_SERIAL)
    
    
    // The date formatter used to generate filenames (can also be used for loggin info inside the files)
    
    static var dateFormatter: NSDateFormatter = {
        let ltf = NSDateFormatter()
        ltf.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return ltf
    }()

    
    // Returns the current file handle if there is one, creates a new one if necessary.
    // Note: Accessing this fileHandle in whatever manner will create a fileHandle if there is none and if a file can be created.
    
    private var fileHandle: NSFileHandle? {
        
        if _fileHandle == nil {
            
            // Create the file
            
            if let fileUrl = fileUrl {
                
                if NSFileManager.defaultManager().createFileAtPath(fileUrl.path!, contents: nil, attributes: [NSFilePosixPermissions : NSNumber(int: 0o640)]) {
                    _fileHandle = NSFileHandle(forUpdatingAtPath: fileUrl.path!)
                    if let startData = createFileStart()?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) { _fileHandle?.writeData(startData) }
                    log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Created new logfile at: \(fileUrl.path!)")
                    _filepathForNotice = fileUrl.path!
                } else {
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not generate logfile at: \(fileUrl.path!)")
                    _fileHandle = nil
                }
                
                
                // Check if there are more than MaxNofFiles in the logfile directory, if so, remove the oldest
                
                if maxNofFiles != nil {
                    do {
                        
                        // Get all files that are not hidden
                        
                        let files = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(
                            directory,
                            includingPropertiesForKeys: nil,
                            options: NSDirectoryEnumerationOptions())
                        
                        
                        // Remove all files that do not contain the choosen filename
                        
                        let onlyLogfiles = files.flatMap({$0.path!.containsString(filename) ? $0 : nil})
                        
                        if onlyLogfiles.count > maxNofFiles! {
                            let sortedLogfiles = onlyLogfiles.sort({ $0.lastPathComponent < $1.lastPathComponent })
                            try NSFileManager.defaultManager().removeItemAtURL(sortedLogfiles.first!)
                            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Removed oldest logfile at: \(sortedLogfiles.first!.path!)")
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
    
    private var _fileHandle: NSFileHandle?
    
    
    // The first part of the name of the logfiles
    
    private var filename: String
    
    
    // The file extension of the logfiles
    
    private var fileExtension: String
    
    
    // The URL of the directory the logfiles are located
    
    private var directory: NSURL
    
    
    /// The maximum filesize of a logfile (in bytes)
    
    var maxFileSize: Int?
    
    
    /// The maximum number of logfiles
    
    var maxNofFiles: Int?
    
    
    /// The time at which a new logfile is started every day
    
    var newFileDailyAt: WallclockTime? {
        didSet {
            self.nextDailyFileAt = NSDate.firstFutureDate(with: newFileDailyAt!)
        }
    }
    
    
    /// The next daily logfile creation
    
    var nextDailyFileAt: NSDate?
    
    
    /// The delay between new logfiles
    
    var newFileAfterDelay: WallclockTime? {
        didSet {
            self.nextDelayedFileAt = NSDate() + newFileAfterDelay!
        }
    }
    
    
    /// The time when the next logfile must be created
    
    var nextDelayedFileAt: NSDate?
    
    
    /**
     Creates a new logfile(s) object with the given name, extension and location. The filenames of the logfiles will follow the pattern: <filename>_<date>T<time><zone>.<extension>. Where date will be "yyyy-MM-dd" such that the files will appear sorted in directory listings.
    
     - Parameter filename: The first name part of the logfiles. Default is 'logfile'.
     - Parameter fileExtension: The file extension of the logfiles. default is 'txt'.
     - Parameter directory: The URL of the directory in which the logfiles will be created. If 'nil' then the logfiles will be located in a 'logfiles' directory in the application's "Application Support" directory.
     - Parameter options: A series of option enums that will be processed in order, hence last-come overrides earlier same-option settings.
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
                
            case let .MaxFileSize(size):
                self.maxFileSize = size * 1024
                
            case let .MaxNofFiles(num):
                self.maxNofFiles = num
                
            case let .NewFileAfterDelay(delay):
                self.newFileAfterDelay = delay
                self.nextDelayedFileAt = NSDate() + delay
                
            case let .NewFileDailyAt(time):
                self.newFileDailyAt = time
                self.nextDailyFileAt = NSDate.firstFutureDate(with: time)
            }
        }
    }

    
    // Create a new filename based on the current time.
    
    private var fullFilename: String {
        return filename + "_" + Logfile.dateFormatter.stringFromDate(NSDate()) +  "." + fileExtension
    }
    
    
    // Create a new file URL
    
    private var fileUrl: NSURL? {
        return directory.URLByAppendingPathComponent(fullFilename)
    }
    
    
    // Keep track of the most recent created file
    
    private var _filepathForNotice: String?
    
    
    /// Close the logfile.
    /// - Note: This method will block until the file has been closed (it is safe to 'nil' a logger object afterwards)
    /// - Note: If a new 'record' call is made after this operation was called then a new logfile will be created.
    
    func close() {
        dispatch_sync(Logfile.queue, { [weak self] in self?._close() }) // Use weak because the app may have removed the Filelog object
    }
    
    
    // Close the current logfile (if any)
    
    private func _close() {
        if let file = self._fileHandle {
            log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Closed current logfile \(_filepathForNotice)")
            file.seekToEndOfFile()
            if let endData = createFileEnd()?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) { file.writeData(endData) }
            file.closeFile()
            self._fileHandle = nil
            self._filepathForNotice = nil
        }
    }
    
    
    /// Force possible buffer content to permanent storage
    
    func flush() {
        dispatch_sync(Logfile.queue, { [weak self] in self?._flush() }) // Use weak because the app may have removed the Filelog object
    }

    // Force possible buffer content to permanent storage
    
    private func _flush() {
        if let file = self._fileHandle {
            file.synchronizeFile()
        }
    }
    
    
    /// Records the given string in the current logfile. Will create a new logfile if neccesary.
    
    func record(message: String) {
        dispatch_async(Logfile.queue, { [weak self] in self?._record(message) }) // Use weak because the app may have removed the Filelog object
    }

    
    // Records the given string in the current logfile. Will create a new logfile if neccesary.

    private func _record(message: String) {
        
        // Implementation detail: Almost everything is done in this operation, from file creation to recoring to closing and deleting. And since all invokations are placed on the queue, this guarantees thread safety. An alternative solution would be to use timers for the timed-renewal of the files, that would be slightly more efficient.

        // If the file exists, check if a new file must be created based on the present options for file renewal
        
        if let file = self._fileHandle { // Don't want side effect of creating a new fileHandle
            
            let now = NSDate() // Caching current time
            
            
            // Close the current file if it is bigger than a maxFileSize assuming that maxFileSize is set.
            
            let fileSize = file.seekToEndOfFile()
            if let maxSize = self.maxFileSize where fileSize > UInt64(maxSize) { self._close() }
            
            
            // If the daily time has been set, and is in the past, then close the current file.
            
            if let newFileDailyAt = self.newFileDailyAt {
                
                if self.nextDailyFileAt!.compare(now) == NSComparisonResult.OrderedAscending {
                    
                    self._close()
                    
                    self.nextDailyFileAt = NSDate.firstFutureDate(with: newFileDailyAt)
                }
            }
            
            
            // If the delay was set, and is in the past, then close the current file.
            
            if let newFileAfterDelay = self.newFileAfterDelay {
                
                if self.nextDelayedFileAt!.compare(now) == NSComparisonResult.OrderedAscending {
                    
                    self._close()
                    
                    // Increase the time for the next new file, and make sure it is after the current time.
                    
                    while self.nextDelayedFileAt!.compare(now) == NSComparisonResult.OrderedAscending {
                        self.nextDelayedFileAt! = self.nextDelayedFileAt! + newFileAfterDelay
                    }
                }
            }
        }
        
        if let file = self.fileHandle { // Want the side effect of creating a new fileHandle (if necessary or possible)
            
            if let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
                file.writeData(data)
            } else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not convert log string to UTF8")
            }
        }
    }
    
    /// Use this function to create the first bit of data that will be prepended to any file that is opened.
    
    func createFileStart() -> String? { return nil }
    
    
    /// Use this function to create the last bit of data that will be appened to any file that is closed.
    
    func createFileEnd() -> String? { return nil }
}