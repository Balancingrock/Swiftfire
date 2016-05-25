// =====================================================================================================================
//
//  File:       UInt8Buffer.swift
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
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


class UInt8Buffer {
    
    
    // The buffer area (is allocated during init)
    
    private var area: UnsafeMutablePointer<UInt8>
    
    
    /// The maximum number of bytes that can be contained in this buffer, is fixed during init and cannot be changed afterwards.
    
    let size: Int
    
    
    /// The number of bytes contained in the buffer.
    
    var fill: Int { return _fill }
    private var _fill = 0
    
    
    /// Access to the data in the buffer area.
    /// - Note: Adding or removing data invalidates previously returned buffer pointers.

    var ptr: UnsafeBufferPointer<UInt8> {
        return UnsafeBufferPointer<UInt8>(start: area, count: _fill)
    }
    
    
    /// - Returns: The value of the received data interpreted as an UTF-8 encoded String. Nil if the data could not be converted.
    /// - Note: The returned value is a struct and thus a copy of the data in the buffer.
    
    var stringValue: String {
        return String(bytes: ptr, encoding: NSUTF8StringEncoding) ?? ""
    }
    
    
    /// Creates a new buffer
    
    init(sizeInBytes: Int) {
        size = sizeInBytes
        area = UnsafeMutablePointer<UInt8>.alloc(size)
    }
    
    
    /// Creates a new buffer with the data from the given buffer starting at the byte at startByteOffset and ending with the byte at endByteOffset.
    /// The fill property will be set to the number of bytes. Hence no further data can be added to this buffer without first making room for it.
    
    convenience init(from: UInt8Buffer, startByteOffset start: Int, endByteOffset end: Int) {
        let theSize = end - start + 1
        self.init(sizeInBytes: theSize)
        memcpy(area, from.area + start, theSize)
        _fill = theSize
    }
    
    
    /// Creates a new buffer with the data from the given buffers.
    /// The fill property will be set to the total number of bytes. Hence no further data can be added to this buffer without first making room for it.

    convenience init(buffers: NSData?...) {
        let totalSize: Int = buffers.reduce(0) { (sum, buf) -> Int in sum + (buf?.length ?? 0) }
        self.init(sizeInBytes: totalSize)
        for b in buffers { if b != nil { self.add(b!) }}
    }
    
    
    /// Creates a new buffer with the data from the given buffers.
    /// The fill property will be set to the total number of bytes. Hence no further data can be added to this buffer without first making room for it.
    
    convenience init(buffers: UInt8Buffer?...) {
        let totalSize: Int = buffers.reduce(0) { (sum, buf) -> Int in sum + (buf?._fill ?? 0) }
        self.init(sizeInBytes: totalSize)
        for b in buffers { if b != nil { self.add(b!) }}
    }

    
    /// Destroys and frees the data area
    
    deinit {
        area.dealloc(size)
    }
    
    
    /// Add the given data to this buffer.
    /// - Note: This operation invalidates any 'ptr' value that was read previously.
    /// - Returns: True when successful, false when not all data could be added (buffer-full)
    
    func add(data: UInt8Buffer) -> Bool {
        guard _fill < size else { return false }
        let nofBytesToCopy = min((size - _fill), data._fill)
        memcpy(area + _fill, data.area, nofBytesToCopy)
        _fill += nofBytesToCopy
        return nofBytesToCopy == data._fill
    }
    
    
    /// Add the given data to this buffer.
    /// - Note: This operation invalidates any 'ptr' value that was read previously.
    /// - Returns: True when successful, false when not all data could be added (buffer-full)

    func add(srcPtr: UnsafePointer<UInt8>, length: Int) -> Bool {
        guard _fill < size else { return false }
        let nofBytesToCopy = min((size - _fill), length)
        memcpy(area+_fill, srcPtr, nofBytesToCopy)
        _fill += nofBytesToCopy
        return nofBytesToCopy == length
    }
    
    
    /// Add the given data to this buffer.
    /// - Note: This operation invalidates any 'ptr' value that was read previously.
    /// - Returns: True when successful, false when not all data could be added (buffer-full)

    func add(buffer: UnsafeBufferPointer<UInt8>) -> Bool {
        return self.add(buffer.baseAddress, length: buffer.count)
    }
    
    
    /// Add the given data to this buffer.
    /// - Note: This operation invalidates any 'ptr' value that was read previously.
    /// - Returns: True when successful, false when not all data could be added (buffer-full)

    func add(data: NSData) -> Bool {
        return self.add(UnsafePointer<UInt8>(data.bytes), length: data.length)
    }
    
    
    /// Removes the indicated number of bytes from the start of the buffer.
    /// - Note: This operation invalidates any 'ptr' value that was read previously.

    func remove(bytes: Int) {
        let nofBytesToRemove = min(bytes, _fill)
        if nofBytesToRemove == _fill { _fill = 0; return }
        let nofBytesToMove = _fill - nofBytesToRemove
        memcpy(area + nofBytesToRemove, area, nofBytesToMove)
    }
    
    
    /// Removes everything.
    /// - Note: This operation invalidates any 'ptr' value that was read previously.
    
    func removeAll() {
        _fill = 0
    }
}
