// =====================================================================================================================
//
//  File:       CommandLineArguments.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2020 Marinus van der Lugt, All rights reserved.
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
// Description
// =====================================================================================================================
//
// Processes command line options.
//
// =====================================================================================================================

import Foundation
import Core


fileprivate let optionsText =
"""
    Usage: $ swiftfire <options>

    Available Options:
    ------------------

    -d <string>
        Set application root directory (within the application directory).
        Default: "production"
        This option allows multiple instances of swiftfire to be run in parallel.
        For example: $ swiftfire -d debug
            Runs swiftfire in a 'debug' root directory, even when the production
            version is still running using the default 'production' root directory.

    -h | -help | -? | ?
        This help text.

    -http <number>
        Set the port on which to listen for incoming HTTP requests, will override
        the port number given in the parameter settings.

    -https <number>
        Set the port on which to listen for incoming HTTPS requests, will override
        the port number given in the parameter settings. Note that the HTTPS server
        will not be started when no certificates are present.
"""

var commandLineArguments: CommandLineArguments = CommandLineArguments()

struct CommandLineArguments {
    
    var httpPortNumber: String?
    var httpsPortNumber: String?
}

extension CommandLineArguments {
    
    
    func updateServerParameters() {
        
        if let val = httpPortNumber {
            serverParameters.httpServicePortNumber.value = val
        }
        
        if let val = httpsPortNumber {
            serverParameters.httpsServicePortNumber.value = val
        }
    }


    mutating func read() {
        
        var index = 0
        
        for arg in CommandLine.arguments {
            
            index += 1
            
            // The first argument is the path to the Swiftfire application
        
            if index == 1 {
                
                Log.atNotice?.log("Running swiftfire executable at: \(arg)")
                
            } else {
                
                switch arg {
                
                case "-d": option_d(&index)
                
                case "-h", "-help", "?", "-?" : option_h(&index)
                
                case "-http": option_http(&index)
                
                case "-https": option_https(&index)
                
                default: option_unknown(arg)
                }
            }
        }
    }


    fileprivate func option_d(_ index: inout Int) {
        
        guard CommandLine.arguments.count < index else {
            print("Missing argument for root directory option (-d)\n\n\(optionsText)")
            exit(0)
        }
        
        Urls.rootDir = Urls.applicationSupportDir.appendingPathComponent(CommandLine.arguments[index])
        
        index += 1
    }
    
    
    fileprivate func option_h(_ index: inout Int) {
        
        print(optionsText)
        exit(0)
    }
    

    fileprivate mutating func option_http(_ index: inout Int) {
        
        guard CommandLine.arguments.count < index else {
            print("Missing argument for http port number option (-http)\n\n\(optionsText)")
            exit(0)
        }
        
        httpPortNumber = CommandLine.arguments[index]
        
        index += 1
    }
    

    fileprivate mutating func option_https(_ index: inout Int) {
        
        guard CommandLine.arguments.count < index else {
            print("Missing argument for https port number option (-https)\n\n\(optionsText)")
            exit(0)
        }
        
        httpsPortNumber = CommandLine.arguments[index]
        
        index += 1
    }

    
    fileprivate func option_unknown(_ arg: String) {
        
        print(
            """
            Unknown option: \(arg)
            
            \(optionsText)
            """)
        
        exit(0)
    }
}
