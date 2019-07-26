// =====================================================================================================================
//
//  File:       Function.Timestamp.swift
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
// Description
// =====================================================================================================================
//
// Returns a timestamp in the format: yyyy-MM-dd HH:mm:ss of the current time in the server timezone.
//
//
// Signature:
// ----------
//
// .timestamp()
//
//
// Parameters:
// -----------
//
// None.
//
//
// Other Input:
// ------------
//
// None.
//
//
// Returns:
// --------
//
// The current time
//
//
// Other Output:
// -------------
//
// None.
//
//
// =====================================================================================================================

import Foundation


private var dateFormatter: DateFormatter = {
    let ltf = DateFormatter()
    ltf.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return ltf
}()


/// Returns the current time.
///
/// - Returns: The current time.

func function_timestamp(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    let now = dateFormatter.string(from: Date())
    
    return now.data(using: String.Encoding.utf8)
}
