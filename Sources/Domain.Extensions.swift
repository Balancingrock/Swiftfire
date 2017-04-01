// =====================================================================================================================
//
//  File:       Domain.Extensions.swift
//  Project:    Swiftfire
//
//  Version:    0.9.18
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2015-2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// 0.9.18 - Header update
// 0.9.15 - General update and switch to frameworks
//        - Added removeUnknownServices & rebuildServices
// 0.9.14 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Add functionality to the Mutation (defined in SwiftfireCore)
//
// =====================================================================================================================

import Foundation
import SwiftfireCore


extension Domain {

    
    /// Returns the custom error message for the given http response code if there is one.
    ///
    /// - Parameter for: The error code for which to return the custom error message.
    
    func customErrorResponse(for code: HttpResponseCode) -> Data? {
        
        do {
            let url = URL(fileURLWithPath: sfresources).appendingPathComponent(code.rawValue.replacingOccurrences(of: " ", with: "_")).appendingPathExtension("html")
            let reply = try Data(contentsOf: url)
            return reply
        } catch {
            return nil
        }        
    }
    
    
    /// Removes service names that are not in the available domain services
    
    func removeUnknownServices() {
        
        for (index, serviceName) in serviceNames.enumerated().reversed() {
            if Swiftfire.services.registered[serviceName] == nil {
                serviceNames.remove(at: index)
            }
        }
    }
    
    
    /// Rebuild the services member from the serviceNames and the available services (the later is a member of domainServices)
    
    func rebuildServices() {
        
        services = []
        for serviceName in serviceNames {
            if let service = Swiftfire.services.registered[serviceName] {
                services.append(service)
            }
        }
    }
}
