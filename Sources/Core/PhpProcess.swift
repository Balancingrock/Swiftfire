// =====================================================================================================================
//
//  File:       PhpProcess.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019 Marinus van der Lugt, All rights reserved.
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


public func loadPhpFile(file: URL, domain: Domain) -> Data {
    
    
    // Ensure that a PHP interpreter is set.
    
    guard let phpPath = domain.phpPath else {
        let message = "No PHP interpreter set for domain \(domain.name)"
        Log.atError?.log(message)
        return message.data(using: .utf8)!
    }
    
    var options: Array<String> = []
    options.append("-f")
    options.append(file.path)
    if let clo = domain.phpOptions, !clo.isEmpty { options.append(clo) }

    Log.atDebug?.log("PHP Options: \(options.reduce("") { "\($0) \($1)" })")
    
    let errpipe = Pipe()
    let outpipe = Pipe()

    
    // Setup the process that will interprete the PHP file
    
    let process = Process()
    if #available(OSX 10.13, *) {
        process.executableURL = phpPath
    } else {
        process.launchPath = phpPath.path
    }
    process.arguments = options
    process.standardError = errpipe
    process.standardOutput = outpipe
    if #available(OSX 10.13, *) {
        process.currentDirectoryURL = domain.phpDir!
    } else {
        process.currentDirectoryPath = domain.phpDir!.path
    }
    
    
    // Start the php process
    
    let data: Data
    do {
        
        Log.atDebug?.log("Starting PHP processing for \(file.path)")

        
        // Start the PHP process
        
        if #available(OSX 10.13, *) {
            try process.run()
        } else {
            process.launch()
        }
        
        
        // Set a timeout so programming errors in the PHP script will not result in hanging connections.
        
        let timeoutAfter = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + UInt64(domain.phpTimeout) * 1000000)
        DispatchQueue.global().asyncAfter(deadline: timeoutAfter) {
            [weak process] in
            Log.atDebug?.log("PHP Timeout expired, process \(process != nil ? "is still running" : "has exited already")")
            process?.terminate()
        }
        
        
        // Wait for PHP to complete
        
        process.waitUntilExit()
        
        Log.atDebug?.log("PHP processing for \(file.path) terminated")

        
        // Check termination reason & status
        
        if (process.terminationReason == .exit) && (process.terminationStatus == 0) {
            
            // Exited OK, return data
            
            data = outpipe.fileHandleForReading.readDataToEndOfFile()
        
            Log.atDebug?.log("Read \(data.count) bytes from PHP processor")
        
        } else {
            
            // An error of some kind happened
            
            Log.atError?.log("PHP process terminations status = \(process.terminationStatus), reason = \(process.terminationReason.rawValue )")

            let now = Date()
            let dateFormatter: DateFormatter = {
                let ltf = DateFormatter()
                ltf.dateFormat = "yyyy-MM-dd'T'HH.mm.ss.SSSZ"
                return ltf
            }()

            
            Log.atError?.log("PHP process failure, check php domain (\(domain.name)) directory for an error entry with timestamp \(dateFormatter.string(from: now))")
            
            
            // Error, grab all possible output and create a file with all error info
            
            let e = errpipe.fileHandleForReading.readDataToEndOfFile()
            let d = outpipe.fileHandleForReading.readDataToEndOfFile()
            
            let dump =
                """
                    Process Termination Reason: \(process.terminationReason.rawValue)
                    PHP exit status: \(process.terminationStatus) (code 15 will be raised if a timeout occured)
                    Details:
                    - File            : \(file.path)
                    - PHP Executable  : \(domain.phpPath?.path ?? "Unknown")
                    - PHP Options     : \(domain.phpOptions ?? "")
                    - PHP Timeout     : \(domain.phpTimeout) mSec
                    - PHP Error output: \(e.count) bytes
                    - PHP Output      : \(d.count) bytes
                    Below the output of the PHP interpreter is given in the following block format:
                    (----- Standard Error -----)
                    ...
                    (----- Standard Out -----)
                    ...
                    (----- End of output -----)
                    
                    (----- Standard Error -----)
                    \(String(bytes: e, encoding: .utf8) ?? "")
                    (----- Standard Out -----)
                    \(String(bytes: d, encoding: .utf8) ?? "")
                    (----- End of output -----)
                """.data(using: .utf8)
            
            let errorFileName = "php-error-log-" + dateFormatter.string(from: now)
            if let errorFileUrl = domain.phpDir?.appendingPathComponent(errorFileName).appendingPathExtension("txt") {
                try dump?.write(to: errorFileUrl)
            } else {
                Log.atError?.log("Cannot create to PHP error file url for directory = \(domain.phpDir?.path  ?? "") & filename = \(errorFileName)")
            }
            data = Data()
        }

    } catch let error {
        
        Log.atError?.log("Exception occured during PHP execution, message = \(error.localizedDescription)")
        data = Data()
    }
    
    return data
}
