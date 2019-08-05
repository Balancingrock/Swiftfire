// =====================================================================================================================
//
//  File:       DateFormatters.swift
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
// 1.0.0 - Initial version
//
// =====================================================================================================================

import Foundation


public let dateFormatter: DateFormatter = {
    let ltf = DateFormatter()
    ltf.dateFormat = "yyyy-MM-dd'T'HH.mm.ss.SSSZ"
    return ltf
}()


/// Use to create filenames when they have to be time-stamped
/// The timestamp will have a leading separator '-' and a trailing '.'.
///
/// - Note: THis formatter is thread safe

fileprivate let filenameTimestampFormatter: DateFormatter = {
    let ltf = DateFormatter()
    ltf.dateFormat = "-yyyy-MM-dd'T'HH.mm.ss.SSSZ."
    return ltf
}()


/// Create a time stamped filename from the given name and extension combined with the current time.
///
/// - Note: The timestamp will have a leading seperator '-'

public func timestampedFilename(name: String, ext: String) -> String {
    return name + filenameTimestampFormatter.string(from: Date()) + ext
}


/// Create a time stamped URL from the given directory URL plus name/extension.

public func timestampedFileUrl(dir url: URL?, name: String, ext: String) -> URL? {
    guard let url = url else { return nil }
    return url.appendingPathComponent(timestampedFilename(name: name, ext: ext))
}
