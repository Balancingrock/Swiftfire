// =====================================================================================================================
//
//  File:       Custom.swift
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
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Use this file to call out to project specific setup code that must be run before the servers become active.
//
// =====================================================================================================================

import Foundation

func customSetup() {
    
    // Do any setup/initialization necessary at startup from here.
    // All global data is already initialized.
    
    // Registering services can be done here, but is probably done better in the file Service.Registration.swift
    
    // Registering functions can be done here, but is probably done better in the file Function.Registration.swift

    // As soon as this function returns the monitoring & control loop will be started and the auto-start feature may start the HTTP and HTTPS server.
    
    // If it is necessary to abort the start, use "fatalError" or "exit(EXIT_FAILURE)", but put a "sleep(1)" in front of it to enable the logging process to catch up with all log messages.
}
