// =====================================================================================================================
//
//  File:       Functions.Registration.swift
//  Project:    Swiftfire
//
//  Version:    0.10.9
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.9 - Added sf-blacklistTable, sf-domainBlacklistTable
// 0.10.6 - Added getSession
// 0.10.0 - Initial release
//
// =====================================================================================================================

import Foundation


// =================================
// Names for the available functions
// =================================


/// Returns the number of hits for the requested resource (path).
///
/// Necessary arguments: None.
///
/// Optional argument: A string with the path of a resource for which the hitcount must be returned.
///
/// Example: .nofPageHits() will have the name "nofPageHits"

let NOF_PAGE_HITS = "nofPageHits"
let GET_SESSION = "getSession"
let TIMESTAMP = "timestamp"
let POSTING_LINK = "postingLink"
let POSTING_BUTTON = "postingButton"
let POSTING_BUTTONED_INPUT = "postingButtonedInput"


// Note: The functions below need an active (logged-in) server admin.

let SF_PARAMETER_VALUE = "sf-parameterValue"
let SF_TELEMETRY_VALUE = "sf-telemetryValue"
let SF_COMMAND = "sf-command"
let SF_PARAMETER_TABLE = "sf-parameterTable"
let SF_TELEMETRY_TABLE = "sf-telemetryTable"
let SF_BLACKLIST_TABLE = "sf-blacklistTable"
let SF_DOMAINS_MENU = "sf-domainsMenu"
let SF_DOMAINS_TABLE = "sf-domainsTable"
let SF_DOMAIN_DETAIL = "sf-domainDetail"
let SF_DELETE_DOMAIN = "sf-deleteDomain"
let SF_DOMAIN_TELEMETRY_TABLE = "sf-domainTelemetryTable"
let SF_POSTING_BUTTONED_INPUT = "sf-postingButtonedInput"
let SF_DOMAIN_SERVICES_TABLE = "sf-domainServicesTable"
let SF_DOMAIN_BLACKLIST_TABLE = "sf-domainBlacklistTable"


// ==================================================
// Add to the next function to register new functions
// ==================================================
// The sequence is not important

/// Register the functions

func registerFunctions() {
    functions.register(name: NOF_PAGE_HITS, function: function_nofPageHits)
    functions.register(name: GET_SESSION, function: function_getSession)
    functions.register(name: TIMESTAMP, function: function_timestamp)
    functions.register(name: POSTING_LINK, function: function_postingLink)
    functions.register(name: POSTING_BUTTON, function: function_postingButton)
    functions.register(name: POSTING_BUTTONED_INPUT, function: function_postingButtonedInput)
    functions.register(name: SF_PARAMETER_VALUE, function: function_sf_parameterValue)
    functions.register(name: SF_TELEMETRY_VALUE, function: function_sf_telemetryValue)
    functions.register(name: SF_COMMAND, function: function_sf_command)
    functions.register(name: SF_PARAMETER_TABLE, function: function_sf_parameterTable)
    functions.register(name: SF_TELEMETRY_TABLE, function: function_sf_telemetryTable)
    functions.register(name: SF_BLACKLIST_TABLE, function: function_sf_blacklistTable)
    functions.register(name: SF_DOMAINS_MENU, function: function_sf_domainsMenu)
    functions.register(name: SF_DOMAINS_TABLE, function: function_sf_domainsTable)
    functions.register(name: SF_DOMAIN_DETAIL, function: function_sf_domainDetail)
    functions.register(name: SF_DELETE_DOMAIN, function: function_sf_deleteDomain)
    functions.register(name: SF_DOMAIN_TELEMETRY_TABLE, function: function_sf_domainTelemetryTable)
    functions.register(name: SF_DOMAIN_SERVICES_TABLE, function: function_sf_domainServicesTable)
    functions.register(name: SF_DOMAIN_BLACKLIST_TABLE, function: function_sf_domainBlacklistTable)
    functions.register(name: SF_POSTING_BUTTONED_INPUT, function: function_sf_postingButtonedInput)
}
