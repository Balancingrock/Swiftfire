// =====================================================================================================================
//
//  File:       SFDocument.Parse.swift
//  Project:    Swiftfire
//
//  Version:    0.10.0
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
// 0.10.0 - Initial release
//
// =====================================================================================================================
//
// Extended-BNF notation of a function call:
//
// Note: {} = sequence, [] = optional, | = or, .. = any in range
//
// <function> ::= <leading-sign><name>[<priority-seperator>[<priority>]]<arguments>
//
// <leading-sign>          ::= "."
// <name>                  ::= <letter>|<digit>|<allowed-signs-in-name>{<letter>|<digit>|<allowed-signs-in-name>}
// <letter>                ::= "A" .. "Z" | "a" .. "z"
// <digit>                 ::= "0" .. "9"
// <allowed-signs-in-name> ::= "-"|"_"
// <priority-seperator>    ::= ":"
// <priority>              ::= <digit>{<digit>}
//
// <arguments>             ::= "("[<argument>[{<argument-separator><argument>}]]")"|<json-object>
// <json-object>           ::= "{"<json-code>"}"
// <argument>              ::= <string>|<quoted-string>
// <arguments-separator>   ::= ","
// <string>                ::= {" "}<name>{" "}
// <quoted-string>         ::= {" "}"""{<printable>}"""{" "}
//
// Examples:
// .numberOfHits()
// .customSeparator(1, fourtyTwo)
// .numberOfBoxes:2{"first":"jumping", "second":["throw", "catch"]}
//
// Note: Only a function that does have a corresponding entry in the registered function table will be recognized as
// a function.
// =====================================================================================================================

import Foundation
import Ascii
import SwifterJSON
import SwiftfireCore


// Constants

fileprivate let LEADING_SIGN = Ascii._DOT
fileprivate let PRIORITY_SEPARATOR = Ascii._COLON
fileprivate let OPEN_ARRAY_ARGUMENTS = Ascii._PARENTHESES_OPEN
fileprivate let CLOSING_ARRAY_ARGUMENTS = Ascii._PARENTHESES_CLOSE
fileprivate let ARRAY_ARGUMENTS_SEPARATOR = Ascii._COMMA
fileprivate let OPEN_JSON_ARGUMENTS = Ascii._CURLY_BRACE_OPEN
fileprivate let CLOSING_JSON_ARGUMENTS = Ascii._CURLY_BRACE_CLOSE

fileprivate let VALID_NAME_CHARACTER: Array<Bool> = [
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false, false,
    false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, true,
    false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
]

fileprivate let VALID_PRIORITY_CHARACTER: Array<Bool> = [
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
]

fileprivate let VALID_NUMBER_CHARACTER: Array<Bool> = [
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, true,  false, true,  true,  false,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false, false,
    false, false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
]

fileprivate let VALID_BOOL_CHARACTER: Array<Bool> = [
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, true,  false, false, false, true,  true,  false, false, false, false, false, true,  false, false, false,
    false, false, true,  true,  true,  true,  false, false, false, false, false, false, false, false, false, false,
    false, true,  false, false, false, true,  true,  false, false, false, false, false, true,  false, false, false,
    false, false, true,  true,  true,  true,  false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
]


fileprivate extension Bool {
    init?(special: String) {
        if special.compare("true", options: [.diacriticInsensitive, .caseInsensitive], range: nil, locale: nil) == ComparisonResult.orderedSame { self = true }
        else if special.compare("false", options: [.diacriticInsensitive, .caseInsensitive]) == ComparisonResult.orderedSame { self = false }
        else if special.compare("yes", options: [.diacriticInsensitive, .caseInsensitive]) == ComparisonResult.orderedSame { self = true }
        else if special.compare("no", options: [.diacriticInsensitive, .caseInsensitive]) == ComparisonResult.orderedSame { self = false }
        else { return nil }
    }
}


extension SFDocument {
    
    
    // The different modi of the parser
    
    fileprivate enum Mode {
        case waitForLeadingSign
        case readName
        case readPriority
        case readJsonArgument
        case readArrayArgument
        case skipJsonBytes(Int)
        case readString
        case readAfterBackslash
    }
    
    
    // Function block data
    
    class FunctionBlockData {
        
        var name: String = ""
        
        var function: Function.Signature?
        
        var string: String = ""

        var priority: Int = 0
        
        var jsonArgument: VJson?
        
        var arrayArguments: Function.ArrayArguments = []
        
        var offset: Int = 0
        
        var characterBlockOffset: Int = 0
        
        var functionBlockOffset: Int = 0
        
        var data: Data
        
        init(data: Data) { self.data = data }
        
        func addNameCharacter(_ char: ASCII) {
            name.append(Character(UnicodeScalar(char)))
        }
        
        func markName() -> Bool {
            function = functions.registered[name]?.function
            return ( function != nil)
        }
        
        func reset() {
            name = ""
            string = ""
            priority = 0
            jsonArgument = nil
            arrayArguments = []
        }
        
        func addPriorityCharacter(_ char: ASCII) {
            string.append(Character(UnicodeScalar(char)))
        }
        
        func setPriority() -> Bool {
            if let num = Int(string) {
                priority = num
                return true
            } else {
                return false
            }
        }
        
        func addStringCharacter(_ char: ASCII) {
            string.append(Character(UnicodeScalar(char)))
        }
        
        func addArrayArgument() {
            if string == "" { return }
            arrayArguments.append(string)
        }
        
        func markFunctionBlockOffset() {
            functionBlockOffset = offset
        }
        
        func markCharacterBlockOffset(adjust: Int = 0) {
            characterBlockOffset = offset + adjust
        }
        
        var asFunctionBlock: DocumentBlock {
            let arguments: Function.Arguments = (jsonArgument != nil) ? .json(jsonArgument!) : .array(arrayArguments)
            let fb = FunctionBlock(function: function, priority: priority, arguments: arguments)
            return .functionBlock(fb)
        }
        
        var asCharacterBlock: DocumentBlock? {
            let length = functionBlockOffset - characterBlockOffset
            if length == 0 { return nil }
            let start = data.startIndex.advanced(by: characterBlockOffset)
            let end = start.advanced(by: length)
            let cb = CharacterBlock(data: data.subdata(in: Range(uncheckedBounds: (lower: start, upper: end))))
            return .characterBlock(cb)
        }
    }

    
    /// Parse a document
    ///
    /// - Parameter doc: The document to parse
    
    func parse() {
        
        
        // Empty previous parsing results
        
        self.blocks = []
        
        
        // Setup start condition for the parsing
        
        var mode: Mode = .waitForLeadingSign

        
        // Function block data
        
        let block: FunctionBlockData = FunctionBlockData(data: filedata)
        
        
        // The main parser loop
        
        filedata.forEach({
            
            char in
        
            switch mode {
                
            case .waitForLeadingSign: mode = waitForLeadingSign(char, block)
            case .readName:           mode = readName(char, block)
            case .readPriority:       mode = readPriority(char, block)
            case .readJsonArgument:   mode = readJsonArgument(char, block)
            case .readArrayArgument:  mode = readArrayArgument(char, block)
            case .readString:         mode = readString(char, block)
            case .readAfterBackslash: mode = readAfterBackslash(char, block)
                
            case .skipJsonBytes(let num):
                if num > 0 {
                    mode = .skipJsonBytes(num - 1)
                } else {
                    mode = .waitForLeadingSign
                    block.markCharacterBlockOffset()
                }
            }
            
            block.offset += 1
        })
        
        block.offset -= 1 // After the last itteration above, offset was incremented for the loo-through, but that did not happen.
        
        if let lastBlock = block.asCharacterBlock { blocks.append(lastBlock) }
    }
    
    fileprivate func waitForLeadingSign(_ char: ASCII, _ block: FunctionBlockData) -> Mode {
        
        if char == LEADING_SIGN {
            
            block.markFunctionBlockOffset()
            return .readName
            
        } else {
            
            return .waitForLeadingSign
        }
    }
    
    fileprivate func readName(_ char: ASCII, _ block: FunctionBlockData) -> Mode {
        
        if VALID_NAME_CHARACTER[Int(char)] {
            
            // Add valid name characters to the name
            
            block.addNameCharacter(char)
            return .readName
            
            
        } else if char == PRIORITY_SEPARATOR {
            
            // Ends the name, starts reading the priority number
            // Check if a function with this name exists, if not, then start over.
            
            if block.markName() {
                return .readPriority
            } else {
                block.reset()
                return .waitForLeadingSign
            }
        
        
        } else if char == OPEN_ARRAY_ARGUMENTS {

            // Ends the name, there is no priority, starts array argument(s)
            // If no function with the found name exists, then start over.
            
            if block.markName() {
                return .readArrayArgument
            } else {
                block.reset()
                return .waitForLeadingSign
            }
            
        
        } else if char == OPEN_JSON_ARGUMENTS {
        
            // Ends the name, there is no priority, starts json argument
            // If no function with the found name exists, then start over.
            
            if block.markName() {
                return .readJsonArgument
            } else {
                return .waitForLeadingSign
            }
            
            
        } else if char == LEADING_SIGN {

            // Throw away what was read, and start again with trying to read a name
            
            block.reset()
            block.markFunctionBlockOffset()
            return .readName
        
        
        } else {
            
            // All other characters invalidate a function block
            
            block.reset()
            return .waitForLeadingSign
        }
    }
    
    fileprivate func readPriority(_ char: ASCII, _ block: FunctionBlockData) -> Mode {
        
        if VALID_PRIORITY_CHARACTER[Int(char)] {
            
            // Add valid priority characters to the name
            
            block.addPriorityCharacter(char)
            return .readPriority

            
        } else if char == OPEN_JSON_ARGUMENTS {
            
            // If the priority could be set continue reading the JSON argument.
            // Otherwise reject the function block and start over.
            
            if block.setPriority() {
                return .readJsonArgument
            } else {
                block.reset()
                return .waitForLeadingSign
            }
            
        
        } else if char == OPEN_ARRAY_ARGUMENTS {
            
            // If the priority could be set continue reading the array argument.
            // Otherwise reject the function block and start over.
            
            if block.setPriority() {
                return .readArrayArgument
            } else {
                block.reset()
                return .waitForLeadingSign
            }

            
        } else if char == LEADING_SIGN {
        
            // Throw away what was read, and start again by trying to read a name
            
            block.reset()
            block.markFunctionBlockOffset()
            return .readName
            
            
        } else {
            
            // All other characters result in an invalid function block
            
            block.reset()
            return .waitForLeadingSign
        }
    }
    
    fileprivate func readJsonArgument(_ char: ASCII, _ block: FunctionBlockData) -> Mode {
        
        var jsonSize: Int = 0
        
        let jsonArgument: VJson? = filedata.withUnsafeBytes({
            
            (ptr: UnsafePointer<UInt8>) -> VJson? in
            
            let startOfJson = UnsafeMutableRawPointer(mutating: ptr).advanced(by: block.offset - 1)
        
            if let bufferPtr = VJson.findPossibleJsonCode(start: startOfJson, count: filedata.count - (block.offset - 1)) {
            
                jsonSize = bufferPtr.count
                return try? VJson.parse(buffer: bufferPtr)
                
            } else {
                
                return nil
            }
        })

        if jsonArgument != nil {
            
            block.jsonArgument = jsonArgument
            if let cb = block.asCharacterBlock { self.blocks.append(cb) }
            self.blocks.append(block.asFunctionBlock)
            block.reset()
            return .skipJsonBytes(jsonSize - 2)
            
        } else {
            
            // Failed to convert to JSON hierarchy, ignore block
                
            block.reset()
            return .waitForLeadingSign
        }
    }

    fileprivate func readArrayArgument(_ char: ASCII, _ block: FunctionBlockData) -> Mode {
        
        if char == Ascii._SPACE {
            
            // Skip spaces
            
            return .readArrayArgument
        
        } else if char == Ascii._DOUBLE_QUOTES {
            
            return .readString
            
        } else if char == CLOSING_ARRAY_ARGUMENTS {
            
            block.addArrayArgument()
            if let cb = block.asCharacterBlock { self.blocks.append(cb) }
            self.blocks.append(block.asFunctionBlock)
            block.markCharacterBlockOffset(adjust: 1)
            block.reset()
            return .waitForLeadingSign
            
        } else if char == LEADING_SIGN {
            
            block.reset()
            block.markFunctionBlockOffset()
            return .readName
            
        } else if char == ARRAY_ARGUMENTS_SEPARATOR {
            
            block.addArrayArgument()
            return .readArrayArgument
            
        } else {
            
            block.addStringCharacter(char)
            return .readArrayArgument
        }
    }
    
    fileprivate func readString(_ char: ASCII, _ block: FunctionBlockData) -> Mode {
    
        if char == Ascii._BACKSLASH {
            
            return .readAfterBackslash
            
            
        } else if char == Ascii._DOUBLE_QUOTES {
            
            block.addArrayArgument()
            return .readArrayArgument
            
            
        } else {
            
            block.addStringCharacter(char)
            return .readString
        }
    }
    
    fileprivate func readAfterBackslash(_ char: ASCII, _ block: FunctionBlockData) -> Mode {
        
        if char == Ascii._DOUBLE_QUOTES {
            
            block.addStringCharacter(char)
            return .readString
            
        } else if char == Ascii._BACKSLASH {
            
            block.addStringCharacter(char)
            return .readString

        } else {
            
            // All other characters result in an invalid function block
            
            block.reset()
            return .waitForLeadingSign
        }
    }
}
