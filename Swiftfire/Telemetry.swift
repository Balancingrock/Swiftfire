// =====================================================================================================================
//
//  File:       ServerTelemetry.swift
//  Project:    Swiftfire
//
//  Version:    0.9.14
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
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
// v0.9.14 - Updated description for nofHttp400Replies
//         - Added nofHttp500Replies
//         - Renamed to Telemetry
//         - Upgraded to Xcode 8 beta 6
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.11 - Moved global definition from main.swift to here.
// v0.9.6  - Header update
// v0.9.3  - Renamed from Telemetry to ServerTelemetry
//         - Moved domain related telemetry to DomainTelemetry
//         - Moved TelemetryProtocol to its own file
//         - Moved UIntTelemetry to its own file
//         - Removed singleton limitation and definition
// v0.9.0  - Initial release
// =====================================================================================================================


import Foundation


let telemetry = Telemetry()


final class Telemetry: CustomStringConvertible, CustomDebugStringConvertible {
    
    
    // Don't allow instances outside this file
    
    fileprivate init() {}
    
    
    /// The reset of the telemetry values
    
    func reinitialize() {
        
        nofAcceptWaitsForConnectionObject.reinitialize()
        nofAcceptedHttpRequests.reinitialize()
        
        nofHttp400Replies.reinitialize()
        nofHttp500Replies.reinitialize()
        nofHttp502Replies.reinitialize()
    }

    
    /// Counts the number of times an accept had to wait for a free connection object. Wraps around at 999_999.
    ///
    /// This is 'for info' only. It does not indicate a serious error. Simply monitor this value, it should ideally stay at zero. For each time it increases it means that one or more client(s) had to wait for 1 second. If this is incremented often, it may be advantageous to increase the number of connection objects. However keep in mind that when more connection objects are available, there will be more requests executing in parallel and other bottlenecks may occur.
    
    let nofAcceptWaitsForConnectionObject = UIntTelemetry()

    
    /// The number of accepted HTTP requests. Wraps around at 999_999.
    ///
    /// For information only.
    
    let nofAcceptedHttpRequests = UIntTelemetry()
    
    
    /// The number of bad HTTP requests. Wraps around at 999_999.
    ///
    /// It is incremented in HttpConnection.HttpWorker when a request cannot be mapped to a (hosted) domain or when no HTTP version is present in the request. Check the logfile and see why the domain could not be mapped. If necessary enable the domain or fix/add a domain.
    
    let nofHttp400Replies = UIntTelemetry()

    
    /// The number of "Bad Gateway" replies for a forwarding request. Wraps around at 999_999.
    ///
    /// Forwarding failed. Check the setup, both Swiftfire and the destination of the forwarding.
    
    let nofHttp502Replies = UIntTelemetry()
    
    
    /// The number of "Server Error" replies for HTTP 1.0 requests. Wraps around at 999_999.
    ///
    /// The parameter "http1_0DomainName" does not refer to an existing domain specification. Update the parameter or add the domain specification.
    
    let nofHttp500Replies = UIntTelemetry()

    
    // MARK: - CustomStringConvertible protocol
    
    var description: String {
        return "nofAcceptWaitsForConnectionObject = \(nofAcceptWaitsForConnectionObject),\n" +
            "nofAcceptedHttpRequests = \(nofAcceptedHttpRequests),\n" +
            "nofHttp400Replies = \(nofHttp400Replies),\n" +
            "nofHttp500Replies = \(nofHttp500Replies),\n" +
            "nofHttp502Replies = \(nofHttp502Replies),\n"
    }
    
    
    // MARK: - CustomDebugStringConvertible protocol

    var debugDescription: String {
        return "Telemetry values:\n\(description)"
    }
}
