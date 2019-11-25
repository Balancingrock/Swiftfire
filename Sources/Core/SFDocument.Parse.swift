// =====================================================================================================================
//
//  File:       SFDocument.Parse.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
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
// 1.3.0 - Added control functions: 'if', 'for', 'cached'
//       - Removed priority parameter since from here on functions will be sequence dependent
//       - Removed JSON argument option because of possible clashes with CSS and since it has not proven its need
// 1.2.0 - Allowed the dot in the string of an argument to support the $<source>.<property> notation
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================
//
// Extended-BNF notation of a function call:
//
// Note: {} = sequence, [] = optional, | = or, .. = any in range
//
// <function> ::= <leading-sign><name><arguments>
//
// <leading-sign>          ::= "."
// <name>                  ::= <letter>|<digit>|<allowed-signs-in-name>{[<letter>|<digit>|<allowed-signs-in-name>]}
// <letter>                ::= "A" .. "Z" | "a" .. "z"
// <digit>                 ::= "0" .. "9"
// <allowed-signs-in-name> ::= "-"|"_"
//
// <arguments>             ::= "("[<argument>[{<argument-separator><argument>}]]")"
// <argument>              ::= <string>|<quoted-string>
// <arguments-separator>   ::= ","
// <string>                ::= {[" "]}<name>{[" "]}
// <quoted-string>         ::= {[" "]}"""{<printable>}"""{[" "]}
//
// Examples:
// .numberOfHits()
// .customSeparator(1, fourtyTwo)
// .numberOfBoxes{"first":"jumping", "second":["throw", "catch"]}
//
// Note: Only a function that does have a corresponding entry in the registered function table will be recognized as
// a function, with the exception of the build in control functions.
// =====================================================================================================================

import Foundation

import SwifterLog
import Ascii


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
            case readArrayArgument
            case readString
            case readAfterBackslash
            case readCommaOrNextOrEnd
            case failed
        }


        // The data manipulated during parsing

        var charBuf: String = "" // Buffers characters that do not belong to a function
        var evalBuf: String = "" // Buffers characters that may belong to a function, except for possible json code

        var name: String = ""     // Characters that may make up the name of a function
        var argument: String = "" // Characters that may make up te argument for an array parameter
        
        var function: Functions.Signature? // The function signature, determined after the name is complete
        var array: Array<String> = []      // The array arguments for a function
        
        var parentBlocks: Array<ControlBlock> = []
                
        func appendArrFunctionBlock() -> Bool {
            
            switch name {
                
            case "for":
                
                let cb = ControlBlock(name: name, function: function, arguments: Functions.Arguments.arrayOfString(array))
                parentBlocks.last!.blocks.append(cb)
                parentBlocks.append(cb)

            case "if":
                
                let cb = ControlBlock(name: name, function: function, arguments: Functions.Arguments.arrayOfString(array))
                parentBlocks.last!.blocks.append(cb)
                parentBlocks.append(cb)
                
                // Create an additional 'then' block that contains the "then" case blocks.
                let tb = ControlBlock(name: "then", function: function, arguments: Functions.Arguments.arrayOfString([]))
                parentBlocks.last!.blocks.append(tb)
                parentBlocks.append(tb)


            case "else":
                
                // Remove the 'then' block from the parent stack
                if parentBlocks.count >= 2 {
                    let pb = parentBlocks.removeLast()
                    if pb.name != "then" {
                        Log.atError?.log("Syntax error, 'else' not preceded by 'if'")
                        return false
                    }
                } else {
                    Log.atError?.log("Syntaxt error, missing 'end'")
                    return false
                }
                
                let eb = ControlBlock(name: name, function: function, arguments: Functions.Arguments.arrayOfString([]))
                parentBlocks.last!.blocks.append(eb)
                parentBlocks.append(eb)


            case "cached":
                
                let cb = ControlBlock(name: name, function: function, arguments: Functions.Arguments.arrayOfString(array))
                parentBlocks.last!.blocks.append(cb)
                parentBlocks.append(cb)

                
            case "comment":
                
                let cb = ControlBlock(name: name, function: function, arguments: Functions.Arguments.arrayOfString(array))
                parentBlocks.last!.blocks.append(cb)
                parentBlocks.append(cb)

                
            case "end":
                
                if parentBlocks.count >= 2 {
                    let pb = parentBlocks.removeLast()
                    if pb.name == "else" || pb.name == "then" { // In case of an 'else' or 'then' block, also remove the 'if' block
                        if parentBlocks.count >= 2 {
                            let pb = parentBlocks.removeLast()
                            // catch syntax errors
                            if pb.name != "if" {
                                Log.atError?.log("Syntax error, missing 'if'")
                                return false
                            }
                        } else {
                            Log.atError?.log("Syntaxt error, missing 'end'")
                            return false
                        }
                    }
                } else {
                    Log.atError?.log("Syntaxt error, missing 'end'")
                    return false
                }
                
            default:
            
                let fb = FunctionBlock(name: name, function: function, arguments: Functions.Arguments.arrayOfString(array))
                parentBlocks.last!.blocks.append(fb)
            }
            
            return true
        }
        
        func appendCharacterBlock() -> Bool {
            guard let data = charBuf.data(using: String.Encoding.utf8) else { return false }
            let cb = CharacterBlock(data: data)
            parentBlocks.last!.blocks.append(cb)
            return true
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
                if !appendCharacterBlock() { return .failed }
                charBuf = ""
                // --
                if !appendArrFunctionBlock() { return .failed }
                return .waitForLeadingSign
                
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
                if !appendCharacterBlock() { return .failed }
                charBuf = ""
                // --
                if !appendArrFunctionBlock() { return .failed }
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
        
        self.blocks = ControlBlock(name: "root", function: nil, arguments: .arrayOfString([]))
        
        parentBlocks = [self.blocks]
        
        
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
            case .readArrayArgument:    mode = readArrayArgument(char)
            case .readString:           mode = readString(char)
            case .readAfterBackslash:   mode = readAfterBackslash(char)
            case .readCommaOrNextOrEnd: mode = readCommaOrNextOrEnd(char)
            case .failed:               success = false;
            }
        }
        
        
        // If the charBuf is not empty, then append it
        
        if success && !charBuf.isEmpty {
            if !appendCharacterBlock() { return false }
        }
        
        return success
    }
}
