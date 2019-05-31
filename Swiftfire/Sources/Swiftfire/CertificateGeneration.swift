// =====================================================================================================================
//
//  File:       CertificateGeneration.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.9.18 - Moved Result from SwifterSockets to BRUtils
// 0.9.17 - Initial release
// =====================================================================================================================

import Foundation
import SecureSockets
import BRUtils


/// Generates a certificate file with corresponding private key file
///
/// - Parameters:
///   - privateKeyLocation: The URL where to store the private key file.
///   - certificateLocation: The URL where to store the certificate file.
///
/// - Returns: .error(String) when an error occured. .success(true) when the operation completed successfully, .success(false) when the operation did not generate an error, but also did not generate the key and certificate.

@discardableResult
public func generateKeyAndCertificate(privateKeyLocation keyUrl: URL?, certificateLocation certUrl: URL?) -> Result<Bool> {
    
    guard let keyUrl = keyUrl else { return .success(false) }
    guard let certUrl = certUrl else { return .success(false) }
    
    
    // Create key container
    
    guard let pkey = Pkey() else {
        return .error(message: "Failed to create key pair")
    }
    
    
    // Create key pair
    
    if case .error(let message) = pkey.assignNewRsa(withLength: 4096, andExponent: 65537) {
        return .error(message: message)
    }
    
    
    // Create certificate
    
    let certificate = X509()
    
    certificate.serialNumber = 1
    
    certificate.validNotBefore = Int64(Date().timeIntervalSince1970)
    
    certificate.validNotAfter = Int64(Date().timeIntervalSince1970 + 2 * 365 * 24 * 60 * 60) // 2 year validity
    
    if case .error(let message) = certificate.setPublicKey(toPublicKeyIn: pkey) {
        return .error(message: message)
    }
    
    
    // Self signed, issuer and subject name are the same
    
    certificate.subjectCountryCode = "nl"
    certificate.issuerCountryCode = "nl"
    
    certificate.subjectCommonName = "Swiftfire"
    certificate.issuerCommonName = "Swiftfire"
    
    certificate.subjectOrganizationName = "Balancingrock"
    certificate.issuerOrganizationName = "Balancingrock"
    
    
    // Sign the certificate
    
    if case let .error(message) = certificate.sign(withPrivateKeyIn: pkey) {
        return .error(message: message)
    }
    
    
    // Save the certificate
    
    if case .error(let message) = certificate.write(to: certUrl) {
        return .error(message: message)
    }
    
    
    // Save the private key
    
    if case .error(let message) = pkey.writePrivateKey(to: keyUrl) {
        return .error(message: message)
    }
    
    
    return .success(true)
}

