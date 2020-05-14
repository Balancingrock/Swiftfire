// =====================================================================================================================
//
//  File:       CertificateGeneration.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2020 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Updated for Swift 5.2
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
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
public func generateKeyAndCertificate(privateKeyLocation keyUrl: URL?, certificateLocation certUrl: URL?) -> SwiftfireResult<Bool> {
    
    guard let keyUrl = keyUrl else { return .success(false) }
    guard let certUrl = certUrl else { return .success(false) }
    
    
    // Create key container
    
    guard let pkey = Pkey() else {
        return .failure(SwiftfireError("Failed to create key pair"))
    }
    
    
    // Create key pair
    
    if case .failure(let message) = pkey.assignNewRsa(withLength: 4096, andExponent: 65537) {
        return .failure(SwiftfireError(message.localizedDescription))
    }
    
    
    // Create certificate
    
    let certificate = X509()
    
    certificate.serialNumber = 1
    
    certificate.validNotBefore = Int64(Date().timeIntervalSince1970)
    
    certificate.validNotAfter = Int64(Date().timeIntervalSince1970 + 2 * 365 * 24 * 60 * 60) // 2 year validity
    
    if case .failure(let message) = certificate.setPublicKey(toPublicKeyIn: pkey) {
        return .failure(SwiftfireError(message.localizedDescription))
    }
    
    
    // Self signed, issuer and subject name are the same
    
    certificate.subjectCountryCode = "nl"
    certificate.issuerCountryCode = "nl"
    
    certificate.subjectCommonName = "Swiftfire"
    certificate.issuerCommonName = "Swiftfire"
    
    certificate.subjectOrganizationName = "Balancingrock"
    certificate.issuerOrganizationName = "Balancingrock"
    
    
    // Sign the certificate
    
    if case .failure(let message) = certificate.sign(withPrivateKeyIn: pkey) {
        return .failure(SwiftfireError(message.localizedDescription))
    }
    
    
    // Save the certificate
    
    if case .failure(let message) = certificate.write(to: certUrl) {
        return .failure(SwiftfireError(message.localizedDescription))
    }
    
    
    // Save the private key
    
    if case .failure(let message) = pkey.writePrivateKey(to: keyUrl) {
        return .failure(SwiftfireError(message.localizedDescription))
    }
    
    
    return .success(true)
}

