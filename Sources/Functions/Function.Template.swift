// =====================================================================================================================
//
//  File:       Functions.Template.swift
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

import Foundation

import Core


/// Returns the value of the parameter
///
/// __Webpage Use__:
///
/// _Signature_: .comments(reference)
///
/// _Number of arguments_: 1
///
/// _Type of argument_:
///   - pageReference: String, uniquely identifies the page this template will be run on
///
/// _Other input_:
///   These parameters are read from the POST dictionary.
///   - firstCommentOffset: The offset of the first comment to be displayed.
///   - commentCount: The number of comments to be displayed.
///
///
/// _Returns_: The resulting HTML code in utf8, ***error***

public func function_template(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    
    // There must be precisely one argument
    
    guard case .arrayOfString(let arr) = args, arr.count == 1 else {
        Log.atError?.log("Expected only one argument")
        return "***error***".data(using: .utf8)
    }
    
    
    // Get the reference string
    
    let reference = arr[0]
    
    
    // Convert the reference to a file url
    
    let refSubs = reference.split(separator: ".")
    guard var refUrl = Urls.domainCommentsRootDir(for: environment.domain.name) else {
        Log.atError?.log("No URL found for domainCommentsRotDir")
        return "***error***".data(using: .utf8)
    }
    for p in refSubs {
        refUrl = refUrl.appendingPathComponent(String(p))
    }
    
    
    // Get the start offset
    
    guard let startOffsetStr = environment.request.info["CommentsStartOffset"], let startOffset = Int(startOffsetStr) else {
        Log.atError?.log("Could not retrieve the CommentsStartOffset from the postInfo dictionary")
        return "***error***".data(using: .utf8)
    }
    
    
    // Get the number of comments
    
    guard let commentsCountStr = environment.request.info["CommentsCount"], let commentsCount = Int(commentsCountStr) else {
        Log.atError?.log("Could not retrieve the CommentsCount from the postInfo dictionary")
        return "***error***".data(using: .utf8)
    }

    
    // Get the file with comments links
    
    // TODO: continue
    
    // Run from 
    
    return nil
}
