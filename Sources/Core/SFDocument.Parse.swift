// =====================================================================================================================
//
//  File:       SFDocument.Parse.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
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
// <name>                  ::= <letter>|<digit>|<allowed-signs-in-name>{[<letter>|<digit>|<allowed-signs-in-name>]}
// <letter>                ::= "A" .. "Z" | "a" .. "z"
// <digit>                 ::= "0" .. "9"
// <allowed-signs-in-name> ::= "-"|"_"
// <priority-seperator>    ::= ":"
// <priority>              ::= <digit>{[<digit>]}
//
// <arguments>             ::= "("[<argument>[{<argument-separator><argument>}]]")"|<json-object>
// <json-object>           ::= "{"<json-code>"}"
// <argument>              ::= <string>|<quoted-string>
// <arguments-separator>   ::= ","
// <string>                ::= {[" "]}<name>{[" "]}
// <quoted-string>         ::= {[" "]}"""{<printable>}"""{[" "]}
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
import SwifterLog
import Ascii
import VJson


// Constants

fileprivate let validNameCharacter: CharacterSet = CharacterSet.init(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-_")

fileprivate let validPriorityCharacter: CharacterSet = CharacterSet.init(charactersIn: "0123456789")


extension SFDocument {
    
    
    /// Parse a document
    ///
    /// - Returns True on success, false if not.
    
    func parse() -> Bool {
        
        
        // The different modi of the parser
    
        enum Mode {
            case waitForLeadingSign
            case readName
            case readJsonArgument
            case readArrayArgument
            case readString
            case readAfterBackslash
            case readCommaOrNextOrEnd
            case failed
        }


        // The data manipulated during parsing

        var charBuf: String = "" // Buffers characters that do not belong to a function
        var evalBuf: String = "" // Buffers characters that may belong to a function, except for possible json code
        var jsonBuf: String = "" // Buffers characters that may consist of json code
        var jsonNesting: Int = 0 // A counter that increments for "{" and decrements for "}"

        var name: String = ""     // Characters that may make up the name of a function
        var argument: String = "" // Characters that may make up te argument for an array parameter
        
        var function: Function.Signature? // The function signature, determined after the name is complete
        var array: Array<String> = []     // The array arguments for a function
        var json: VJson?                  // The JSON argument for a function

        func asJsonFunctionBlock() -> DocumentBlock {
            let fb = FunctionBlock(name: name, function: function, arguments: Function.Arguments.json(json!))
            Log.atDebug?.log("Function block: \(fb)", type: "SFDocument")
            return .functionBlock(fb)
        }
        
        func asArrFunctionBlock() -> DocumentBlock {
            let fb = FunctionBlock(name: name, function: function, arguments: Function.Arguments.array(array))
            Log.atDebug?.log("Function block: \(fb)", type: "SFDocument")
            return .functionBlock(fb)
        }
        
        func asCharacterBlock() -> DocumentBlock? {
            guard let data = charBuf.data(using: String.Encoding.utf8) else { return nil }
            let cb = CharacterBlock(data: data)
            Log.atDebug?.log("Character block: \(cb)", type: "SFDocument")
            return .characterBlock(cb)
        }

        
        // Parsing functions
        
        func waitForLeadingSign(_ char: Character) -> Mode {
        
            if char != "." {
                charBuf.append(char)
                return .waitForLeadingSign
                
            } else {
                name = ""
                evalBuf = "."
                return .readName
                
            }
        }

        func readName(_ char: Character, _ unicode: UnicodeScalar) -> Mode {
            
            if validNameCharacter.contains(unicode) {
                evalBuf.append(char)
                name.append(char)
                return .readName
                
            } else if char == "(" {
                evalBuf.append(char)
                function = functions.registered[name]?.function
                if function != nil {
                    array = []
                    argument = ""
                    return .readArrayArgument
                } else {
                    charBuf.append(evalBuf)
                    return .waitForLeadingSign
                }
                
            } else if char == "{" {
                function = functions.registered[name]?.function
                if function != nil  {
                    jsonBuf = "{"
                    jsonNesting = 1
                    return .readJsonArgument
                } else {
                    charBuf.append(evalBuf)
                    return .waitForLeadingSign
                }
                
            } else if char == "." {
                charBuf.append(evalBuf)
                name = ""
                evalBuf = "."
                return .readName
                
            } else {
                evalBuf.append(char)
                charBuf.append(evalBuf)
                return .waitForLeadingSign
            }
        }

        func readJsonArgument(_ char: Character) -> Mode {
            
            if char == "{" {
                jsonBuf.append(char)
                jsonNesting += 1
                return .readJsonArgument
                
            } else if char == "}" {
                jsonBuf.append(char)
                jsonNesting -= 1
                if jsonNesting == 0 {
                    // --
                    if let cblock = asCharacterBlock() {
                        self.blocks.append(cblock)
                    } else {
                        return .failed
                    }
                    charBuf = ""
                    // --
                    do {
                        json = try VJson.parse(string: jsonBuf)
                        if json == nil {
                            charBuf.append(jsonBuf)
                            return .waitForLeadingSign
                        } else {
                            self.blocks.append(asJsonFunctionBlock())
                            return .waitForLeadingSign
                        }
                    } catch _ {
                        charBuf.append(jsonBuf)
                        return .waitForLeadingSign
                    }
                } else {
                    return .readJsonArgument
                }
                
            } else {
                jsonBuf.append(char)
                return .readJsonArgument
            }
        }

        func readArrayArgument(_ char: Character) -> Mode {
            
            if char == " " { // Skip spaces
                evalBuf.append(char)
                return .readArrayArgument
                
            } else if char == "\"" || char == "“" { // Begin of string
                evalBuf.append(char)
                return .readString
                
            } else if char == "," {
                evalBuf.append(char)
                array.append(argument)
                argument = ""
                return .readArrayArgument
                
            } else if char == ")" { // End of arguments
                if !argument.isEmpty { array.append(argument) }
                // --
                if let cblock = asCharacterBlock() {
                    self.blocks.append(cblock)
                } else {
                    return .failed
                }
                charBuf = ""
                // --
                self.blocks.append(asArrFunctionBlock())
                return .waitForLeadingSign
                
            } else if char == "." { // Potential start of a new function block
                charBuf.append(evalBuf)
                name = ""
                evalBuf = "."
                return .readName
                
            } else {
                evalBuf.append(char)
                argument.append(char)
                return .readArrayArgument
            }
        }

        func readString(_ char: Character) -> Mode {
            
            if char == "\\" { // Escape of " and \ characters
                evalBuf.append(char)
                return .readAfterBackslash
                
            } else if char == "\"" || char == "”" { // End of string = end of argument
                evalBuf.append(char)
                array.append(argument)
                argument = ""
                return .readCommaOrNextOrEnd
                
            } else {
                evalBuf.append(char)
                argument.append(char)
                return .readString
            }
        }
        
        func readCommaOrNextOrEnd(_ char: Character) -> Mode {
            
            if char == "," {
                evalBuf.append(char)
                return .readArrayArgument
                
            } else if char == ")" {
                if !argument.isEmpty { array.append(argument) }
                // --
                if let cblock = asCharacterBlock() {
                    self.blocks.append(cblock)
                } else {
                    return .failed
                }
                charBuf = ""
                // --
                self.blocks.append(asArrFunctionBlock())
                return .waitForLeadingSign

            } else if char == " " {
                evalBuf.append(char)
                return .readCommaOrNextOrEnd
                
            } else {
                evalBuf.append(char)
                argument.append(char)
                return .readArrayArgument

            }
        }
        
        func readAfterBackslash(_ char: Character) -> Mode {
            
            if char == "\"" {
                evalBuf.append(char)
                argument.append(char)
                return .readString
                
            } else if char == "\\" {
                evalBuf.append(char)
                argument.append(char)
                return .readString
                
            } else {
                evalBuf.append(char)
                charBuf.append(evalBuf)
                return .waitForLeadingSign
            }
        }

        
        // Empty previous parsing results
        
        self.blocks = []
        
        
        // Setup start condition for the parsing
        
        var mode: Mode = .waitForLeadingSign

        
        // Set to success if parsing succeeds
        
        var success = true
        
        
        // The main parser loop
        
        
        filedata.forEach {
            
            char in
            
            let unicodeScalar = String(char).unicodeScalars.first!
            
            switch mode {
                
            case .waitForLeadingSign:   mode = waitForLeadingSign(char)
            case .readName:             mode = readName(char, unicodeScalar)
            case .readJsonArgument:     mode = readJsonArgument(char)
            case .readArrayArgument:    mode = readArrayArgument(char)
            case .readString:           mode = readString(char)
            case .readAfterBackslash:   mode = readAfterBackslash(char)
            case .readCommaOrNextOrEnd: mode = readCommaOrNextOrEnd(char)
            case .failed:               success = false;
            }
        }
        
        
        // If the charBuf is not empty, then append it
        
        if success && !charBuf.isEmpty {
            if let cb = asCharacterBlock() {
                self.blocks.append(cb)
            } else {
                return false
            }
        }
        
        return success
    }
}