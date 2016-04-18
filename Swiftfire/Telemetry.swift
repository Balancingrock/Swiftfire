// =====================================================================================================================
//
//  File:       Telemetry.swift
//  Project:    Swiftfire
//
//  Version:    0.9.0
//
//  Author:     Marinus van der Lugt
//  Website:    http://www.balancingrock.nl/swiftfire.html
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
//
//  License:    Use this code any way you like with the following three provision:
//
//  1) You are NOT ALLOWED to redistribute this source code.
//
//  2) You ACCEPT this source code AS IS without any guarantees that it will work as intended. Any liability from its
//  use is YOURS.
//
//  3) You WILL NOT seek compensation for possible damages from the author or balancingrock.nl.
//
//  I also ask you to please leave this header with the source code.
//
//  I strongly believe that NAP is the way for societies to function optimally. I thus reject the implicit use of force
//  to extract payment. Since I cannot negotiate with you about the price of this code, I have choosen to leave it up to
//  you to determine its price. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/google to ensure that you actually pay me and not some imposter)
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
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


// Singleton

let telemetry = Telemetry()


// All telemetry items must implement this protocol

protocol TelemetryProtocol {
    func reinitialize()
    var stringValue: String { get }
}


/// The UInt telemetry type, the integer this class represents has a range from 0 .. 1_000_000. It wraps around while incrementing but does not wrap around while decrementing.

class UIntTelemetry: NSObject, TelemetryProtocol {
    private var value: UInt = 0
    override var description: String { return synchronized(self, { return self.value.description })}
    var stringValue: String { return synchronized(self, { return self.value.description })}
    var intValue: Int { return synchronized(self, { return Int(self.value) })}
    func reinitialize() { synchronized(self, { self.value = 0 })}
    func increment() { synchronized(self, { if self.value < 999_999 { self.value += 1 } else { self.value = 0 }})}
    func decrement() { synchronized(self, { if self.value != 0 { self.value -= 1 }})}
}


class Telemetry: CustomStringConvertible, CustomDebugStringConvertible {

    
    /// Prevent another instance
    
    private init() {}
    
    
    /// The reset of the telemetry values
    
    func reinitialize() {
        
        nofAcceptWaitsForConnectionObject.reinitialize()
        nofAcceptedHttpRequests.reinitialize()
        nofProcessedHttpRequests.reinitialize()
        
        nofReceiveTimeouts.reinitialize()
        nofReceiveErrors.reinitialize()
        nofReceiveClientClosedErrors.reinitialize()
        
        nofSuccessfulHttpReplies.reinitialize()
        nofHttp400Replies.reinitialize()
        nofHttp404Replies.reinitialize()
        nofHttp500Replies.reinitialize()
        nofHttp501Replies.reinitialize()
        nofHttp505Replies.reinitialize()
    }

    
    /**
     Counts the number of times an accept had to wait for a free connection object. Wraps around at 999_999.
    
     This is 'for info' only. It does not indicate a serious error. Simply monitor this value, it should ideally stay at zero. For each time it increases it means that one or more client(s) had to wait for 1 second. If this is incremented often, it may be advantagious to increase the number of connection objects. However keep in mind that when more connection objects are available, there will be more requests executing in parallel and other bottlenecks may occur.
     */
    
    let nofAcceptWaitsForConnectionObject = UIntTelemetry()

    
    /**
     The number of processed HTTP requests. Wraps around at 999_999.
     
     For information only.
     */

    let nofProcessedHttpRequests = UIntTelemetry()
    
    
    /**
     The number of accepted HTTP requests. Wraps around at 999_999.
     
     For information only.
    */
    
    let nofAcceptedHttpRequests = UIntTelemetry()
    
    
    /**
     The number of times the receive loop timed out after a connection request was already accepted. Wraps around at 999_999.
     
     Ideally this number should remain zero. However clients can do anything they want, and the network is also not 100% relyable. So just keep an eye on this. There is no recommended recovery strategy if this does indeed happen frequently. Maybe a time-distribution pattern analysis could work to determine a possible cause.
     */

    let nofReceiveTimeouts = UIntTelemetry()

    
    /**
     The number of times the recv statement produced an error after a connection request was already accepted. Wraps around at 999_999.
     
     This number should stay at zero. Any other number should be investigated, probably with the use of a network analyzer.
     */

    let nofReceiveErrors = UIntTelemetry()

    
    /**
     The number of times the recv statement detected a closed connection. Wraps around at 999_999.
     
     Ideally this number should remain zero. However clients can do anything they want, and the network is also not 100% relyable. So just keep an eye on this. There is no recommended recovery strategy if this does indeed happen frequently. Maybe a time-distribution pattern analysis could work to determine a possible cause.
     */

    let nofReceiveClientClosedErrors = UIntTelemetry()

    
    /**
     The number of sucessful HTTP replies.  Wraps around at 999_999.
     
     For information only.
     */
    
    let nofSuccessfulHttpReplies = UIntTelemetry()
    
    
    /**
     The number of bad HTTP requests. Wraps around at 999_999.
     
     This is for info only. It does not indicate an error, but if it happens a lot, it could be advantagious to analyse why it happens.
     */
    
    let nofHttp400Replies = UIntTelemetry()

    
    /**
     The number of failed HTTP replies. Wraps around at 999_999.
     
     This is for info only. It does not indicate an error, but if it happens a lot, it could be advantagious to analyse why it happens, chances are that it is possible to increase usefull traffic by handling 404 erros in a diffeent way.
     */
    
    let nofHttp404Replies = UIntTelemetry()
    
    
    /**
     The number of HTTP replies for an internal server error. Wraps around at 999_999.
     
     This should never happen. Always investigate why it happened and fix the error.
     */
    
    let nofHttp500Replies = UIntTelemetry()
    
    
    /**
     The number of HTTP replies for a not implemented feature. Wraps around at 999_999.
     
     This is for info only. It does not indicate an error.
     */
    
    let nofHttp501Replies = UIntTelemetry()
    
    
    /**
     The number of HTTP replies for a not supported HTTP version. Wraps around at 999_999.
     
     This is for info only. It does not indicate an error. However, this should not happen a lot. HTTP 1.1 is standard and HTTP 2 is initiated via a HTTP 1.1 request. Hence this kind of error should be seldom or never.
     */
    
    let nofHttp505Replies = UIntTelemetry()

    
    // MARK: - CustomStringConvertible protocol
    
    var description: String {
        return "nofAcceptWaitsForConnectionObject = \(nofAcceptWaitsForConnectionObject),\n" +
            "nofAcceptedHttpRequests = \(nofAcceptedHttpRequests),\n" +
            "nofReceiveTimeouts = \(nofReceiveTimeouts),\n" +
            "nofReceiveErrors = \(nofReceiveErrors),\n" +
            "nofReceiveClientClosedErrors = \(nofReceiveClientClosedErrors),\n" +
            "nofSuccessfulHttpReplies = \(nofSuccessfulHttpReplies),\n" +
            "nofHttp400Replies = \(nofHttp400Replies),\n" +
            "nofHttp404Replies = \(nofHttp404Replies),\n" +
            "nofHttp500Replies = \(nofHttp500Replies),\n" +
        "nofHttp501Replies = \(nofHttp501Replies),\n" +
        "nofHttp505Replies = \(nofHttp505Replies),\n"
    }
    
    
    // MARK: - CustomDebugStringConvertible protocol

    var debugDescription: String {
        return "Telemetry values:\n\(description)"
    }
}