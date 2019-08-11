// =====================================================================================================================
//
//  File:       Functions.SF.Registration.swift
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

import Core


// =================================
// Names for the available functions
// =================================

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
let SF_STATISTICS_PAGE = "sf-statisticsPage"
let SF_DOMAIN_BUTTON = "sf-domainButton"


// ==================================================
// Add to the next function to register new functions
// ==================================================
// The sequence is not important

/// Register the functions

public func sfRegisterFunctions() {
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
    functions.register(name: SF_DOMAIN_BUTTON, function: function_sf_domainButton)
}
