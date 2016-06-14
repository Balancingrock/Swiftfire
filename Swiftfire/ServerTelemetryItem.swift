// =====================================================================================================================
//
//  File:       ServerTelemetryItems.swift
//  Project:    Swiftfire
//
//  Version:    0.9.6
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
// v0.9.6 - Header update
// v0.9.4 - Initial release (replaces part of MacDef.swift)
// =====================================================================================================================

import Foundation

enum ServerTelemetryItem: String {
    
    case SERVER_VERSION = "ServerVersion"
    case SERVER_STATUS = "ServerStatus"
    case NOF_ACCEPT_WAITS_FOR_CONNECTION_OBJECT = "NofAcceptWaitsForConnectionObject"
    case NOF_ACCEPTED_HTTP_REQUESTS = "NofAcceptedHttpRequests"
    case NOF_HTTP_400_REPLIES = "NofHttp400Replies"
    case NOF_HTTP_502_REPLIES = "NofHttp502Replies"
    
    var guiLabel: String {
        switch self {
        case NOF_ACCEPT_WAITS_FOR_CONNECTION_OBJECT: return "Number of times the accept call had to wait for a connection"
        case SERVER_VERSION: return "The Version Number of Swiftfire"
        case SERVER_STATUS: return "The Status of Swiftfire"
        case NOF_ACCEPTED_HTTP_REQUESTS: return "The Total Number of Accepted Http Requests"
        case NOF_HTTP_400_REPLIES: return "The Total Number of HTTP 400 Errors Generated"
        case NOF_HTTP_502_REPLIES: return "The Total Number of HTTP 502 Errors Generated"
        }
    }
    
    var toolTip: String {
        switch self {
        case NOF_ACCEPT_WAITS_FOR_CONNECTION_OBJECT: return "Number of times the accept call had to wait for a connection"
        case SERVER_VERSION: return "The Version Number of Swiftfire"
        case SERVER_STATUS: return "The Status of Swiftfire"
        case NOF_ACCEPTED_HTTP_REQUESTS: return "The Total Number of Accepted Http Requests"
        case NOF_HTTP_400_REPLIES: return "The Total Number of HTTP 400 Errors Generated"
        case NOF_HTTP_502_REPLIES: return "The Total Number of HTTP 502 Errors Generated"
        }
    }

    static let all: Array<ServerTelemetryItem> = [.SERVER_VERSION, .SERVER_STATUS, .NOF_ACCEPT_WAITS_FOR_CONNECTION_OBJECT, .NOF_ACCEPTED_HTTP_REQUESTS, .NOF_HTTP_400_REPLIES, .NOF_HTTP_502_REPLIES]
}