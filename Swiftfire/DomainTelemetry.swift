// =====================================================================================================================
//
//  File:       DomainTelemetry.swift
//  Project:    Swiftfire
//
//  Version:    0.9.11
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
// v0.9.11 - Updated for VJson 0.9.8
// v0.9.6  - Header update
// v0.9.3  - Initial release
// =====================================================================================================================


import Foundation

func == (left: TelemetryItem, right: TelemetryItem) -> Bool {
    if left.value != right.value { return false }
    if left.guiLabel != right.guiLabel { return false }
    return true
}

class TelemetryItem: NSObject {
    
    var value: Int = 0

    var guiLabel: String
    
    func copyFrom(t: TelemetryItem) {
        self.value = t.value
        self.guiLabel = t.guiLabel
    }
    
    func json(id: String) -> VJson {
        let j = VJson.object(id)
        j["Value"] &= value
        j["GuiLabel"] &= guiLabel
        return j
    }
    
    func increment() {
        value += 1
        if value == 1_000_000 { value = 0 }
    }
    
    init(guiLabel: String) {
        self.guiLabel = guiLabel
        super.init()
    }
    
    convenience init(guiLabel: String, value: Int) {
        self.init(guiLabel: guiLabel)
        self.value = value
    }
    
    convenience init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jguiLabel = (json|"GuiLabel")?.stringValue else { return nil }
        guard let jvalue = (json|"Value")?.integerValue else { return nil }
        self.init(guiLabel: jguiLabel, value: jvalue)
    }
}


func == (left: DomainTelemetry, right: DomainTelemetry) -> Bool {
    if left.nofRequests != right.nofRequests { return false }
    if left.nof200 != right.nof200 { return false }
    if left.nof400 != right.nof400 { return false }
    if left.nof403 != right.nof403 { return false }
    if left.nof404 != right.nof400 { return false }
    if left.nof500 != right.nof500 { return false }
    if left.nof501 != right.nof501 { return false }
    if left.nof505 != right.nof500 { return false }
    return true
}

class DomainTelemetry: NSObject {
    
    
    /// The total number of requests processed. Includes error replies, but excludes forwarding.
    
    let nofRequests = TelemetryItem(guiLabel: "Total Number of Requests")
    
    
    /// The number of 200 (Successfull reply)
    
    let nof200 = TelemetryItem(guiLabel: "Number of Succesfull Replies (200)")
    
    
    /// The number of 400 (Bad Request)
    
    let nof400 = TelemetryItem(guiLabel: "Number of Bad Requests (400)")
    
    
    /// The number of 403 (Forbidden)
    
    let nof403 = TelemetryItem(guiLabel: "Number of Forbidden (403)")
    
    
    /// The number of 404 (File/Resource Not Found)
    
    let nof404 = TelemetryItem(guiLabel: "Number of Not Found (404)")
    
    
    /// The number of 500 (Server Error)
    
    let nof500 = TelemetryItem(guiLabel: "Number of Server Errors (500)")
    
    
    /// The number of 501 (Not Implemented)
    
    let nof501 = TelemetryItem(guiLabel: "Number of Not Implemented (501)")
    
    
    /// The number of 505 (HTTP version not supported)
    
    let nof505 = TelemetryItem(guiLabel: "Number of HTTP Version Not Supported (505)")
    
    
    /// All the telemetry in an array
    
    var all: Array<TelemetryItem>
    
    
    /// Creates a duplicate of the telemetry and returns that
    
    var duplicate: DomainTelemetry {
        let new = DomainTelemetry()
        new.nofRequests.value = self.nofRequests.value
        new.nof200.value = self.nof200.value
        new.nof400.value = self.nof400.value
        new.nof403.value = self.nof403.value
        new.nof404.value = self.nof404.value
        new.nof500.value = self.nof500.value
        new.nof501.value = self.nof501.value
        new.nof505.value = self.nof505.value
        return new
    }

    
    /// The JSON representation for this object
    
    func json(id: String) -> VJson {
        let j = VJson.object(id)
        j.add(nofRequests.json("NofRequests"))
        j.add(nof200.json("Nof200"))
        j.add(nof400.json("Nof400"))
        j.add(nof403.json("Nof403"))
        j.add(nof404.json("Nof404"))
        j.add(nof500.json("Nof500"))
        j.add(nof501.json("Nof501"))
        j.add(nof505.json("Nof505"))
        return j
    }
    
    
    /// Allow default initializer
    
    override init() {
        all = [nofRequests, nof200, nof400, nof403, nof404, nof500, nof501, nof505]
        super.init()
    }
    
    
    /// The recreation from JSON code
    
    convenience init?(json: VJson?) {
        
        guard let json = json else { return nil }
        
        guard let jnofRequests = TelemetryItem(json: json|"NofRequests") else { return nil }
        guard let jNof200 = TelemetryItem(json: json|"Nof200") else { return nil }
        guard let jNof400 = TelemetryItem(json: json|"Nof400") else { return nil }
        guard let jNof403 = TelemetryItem(json: json|"Nof403") else { return nil }
        guard let jNof404 = TelemetryItem(json: json|"Nof404") else { return nil }
        guard let jNof500 = TelemetryItem(json: json|"Nof500") else { return nil }
        guard let jNof501 = TelemetryItem(json: json|"Nof501") else { return nil }
        guard let jNof505 = TelemetryItem(json: json|"Nof505") else { return nil }

        self.init()

        nofRequests.copyFrom(jnofRequests)
        nof200.copyFrom(jNof200)
        nof400.copyFrom(jNof400)
        nof403.copyFrom(jNof403)
        nof404.copyFrom(jNof404)
        nof500.copyFrom(jNof500)
        nof501.copyFrom(jNof501)
        nof505.copyFrom(jNof505)
    }
    
    
    /// Reset all telemetry values to their default value.
    
    func reset() {
        
        nofRequests.value = 0
        nof200.value = 0
        nof400.value = 0
        nof403.value = 0
        nof404.value = 0
        nof500.value = 0
        nof501.value = 0
        nof505.value = 0
    }
}