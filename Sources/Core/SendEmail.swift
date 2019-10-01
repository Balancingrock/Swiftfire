// =====================================================================================================================
//
//  File:       SendEmail.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
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
// 1.3.0 - Initial version
//
// =====================================================================================================================

// Note - Setting up postfix on macOS 12.14
//
// In /etc/postfix edit the main.cf file to contain the following (at the end, check for possible conflicts):
//
// tls_random_source = dev:/dev/urandom
// smtp_sasl_mechanism_filter = plain
// smtp_sasl_auth_enable = yes
// smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
// smtp_sasl_security_options =
// smtp_use_tls=yes
// smtp_tls_security_level=encrypt
// relayhost = smtp.<your-email-provider>.com:587
//
// Also in /etc/postfix create the file referenced above: sassl_passwd with the following content:
//
// smtp.<your-email-provider>.com:587 <your-name>:<your-password>
//
// Then create a map from the file with: sudo postmap sasl_passwd
//
// Start postscript with: sudo postscript start
// or reload if already running with: sudo postfix reload
//
// Test by creating a file with an email header and transfer the file with: sendmail -vt < mail.txt
//
// Check with unix mail if the email (file) was transferred correctly. (type 'mail' and once mail opened follow it by the number of the mail you want to see)


import Foundation


/// This queue/thread will be used to transfer the mails.

fileprivate let mailQueue = DispatchQueue.global(qos: .background)


/// Sends an email using the postfix unix utility.
///
/// - Note: Ths function only works if postfix is running (and set up correctly)
///
/// - Parameters:
///   - mail: The email to be transmitted. It should -as a minimum- contain the To, From and Subject fields.
///   - domainName: The domain this email is sent from, used for logging purposes only.

public func sendEmail(_ mail: String, domainName: String) {
    
    
    // Do this on a seperate queue in the background so this operation is non-blocking.
    
    mailQueue.async { [mail, domainName] in
        
        // Ensure the mail is ok
        
        guard let utf8mail = mail.data(using: .utf8), utf8mail.count > 0 else {
            Log.atDebug?.log("No mail present")
            return
        }
        
        let options: Array<String> = ["-t"] // This option tells sendmail to read the from/to/subject from the email string itself.
        
        let errpipe = Pipe() // should remain empty
        let outpipe = Pipe() // should remain empty (but if you use other options you may get some text)
        let inpipe = Pipe()  // will be used to transfer the mail to sendmail
        
        
        // Setup the process that will send the mail
        
        let process = Process()
        if #available(OSX 10.13, *) {
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/sendmail")
        } else {
            process.launchPath = "/usr/sbin/sendmail"
        }
        process.arguments = options
        process.standardError = errpipe
        process.standardOutput = outpipe
        process.standardInput = inpipe
        
        
        // Start the sendmail process
        
        let data: Data
        do {
            
            Log.atDebug?.log("\n\(mail)")
            
            
            // Setup the data to be sent
            
            inpipe.fileHandleForWriting.write(utf8mail)
            
            
            // Start the sendmail process
            
            if #available(OSX 10.13, *) {
                try process.run()
            } else {
                process.launch()
            }
            
            
            // Data transfer complete
            
            inpipe.fileHandleForWriting.closeFile()
            
            
            // Set a timeout. 10 seconds should be more than enough.
            
            let timeoutAfter = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + UInt64(10000) * 1000000)
            
            
            // Setup the process timeout on another queue
            
            DispatchQueue.global().asyncAfter(deadline: timeoutAfter) {
                [weak process] in
                Log.atDebug?.log("Sendmail Timeout expired, process \(process != nil ? "is still running" : "has exited already")")
                process?.terminate()
            }
            
            
            // Wait for sendmail to complete
            
            process.waitUntilExit()
            
            Log.atDebug?.log("Sendmail terminated")
            
            
            // Check termination reason & status
            
            if (process.terminationReason == .exit) && (process.terminationStatus == 0) {
                
                // Exited OK, return data
                
                data = outpipe.fileHandleForReading.readDataToEndOfFile()
                
                if data.count > 0 {
                    Log.atDebug?.log("Unexpectedly read \(data.count) bytes from sendmail, content: \(String(data: data, encoding: .utf8) ?? "")")
                } else {
                    Log.atDebug?.log("Sendmail completed without error")
                }
                
            } else {
                
                // An error of some kind happened
                
                Log.atError?.log("Sendmail process terminations status = \(process.terminationStatus), reason = \(process.terminationReason.rawValue )")
                
                let now = dateFormatter.string(from: Date())
                
                Log.atError?.log("Sendmail process failure, check domain (\(domainName)) logging directory for an error entry with timestamp \(now)")
                
                
                // Error, grab all possible output and create a file with all error info
                
                let e = errpipe.fileHandleForReading.readDataToEndOfFile()
                let d = outpipe.fileHandleForReading.readDataToEndOfFile()
                
                let dump =
                """
                Process Termination Reason: \(process.terminationReason.rawValue)
                Sendmail exit status: \(process.terminationStatus)
                Details:
                - Sendmail Executable  : /usr/sbin/sendmail
                - Sendmail Options     : -t
                - Sendmail Timeout     : 10,000 mSec
                - Sendmail Error output: \(e.count) bytes
                - Sendmail Output      : \(d.count) bytes
                Below the output of sendmail is given in the following block format:
                (----- Email input -----)
                ...
                (----- Standard Error -----)
                ...
                (----- Standard Out -----)
                ...
                (----- End of output -----)
                
                (----- Email input -----)
                \(mail)
                (----- Standard Error -----)
                \(String(bytes: e, encoding: .utf8) ?? "")
                (----- Standard Out -----)
                \(String(bytes: d, encoding: .utf8) ?? "")
                (----- End of output -----)
                """
                
                let errorFileName = "sendmail-error-log-" + now
                if
                    let errorFileUrl = Urls.domainLoggingDir(for: domainName)?.appendingPathComponent(errorFileName).appendingPathExtension("txt"),
                    let dumpData = dump.data(using: .utf8),
                    ((try? dumpData.write(to: errorFileUrl)) != nil) {
                } else {
                    Log.atError?.log("Cannot create sendmail error file, content is: \n\(dump)\n")
                }
            }
            
        } catch let error {
            
            Log.atError?.log("Exception occured during sendmail execution, message = \(error.localizedDescription)")
        }
    }
}
