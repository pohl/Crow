//
//  Css.swift
//  Crow
//
//  A simple parser for a tiny subset of CSS.
//
//  To support more CSS syntax, it would probably be easiest to replace this
//  hand-rolled parser with one based on a library or parser generator.
//
//  Created by Pohl Longsine on 8/27/14.
//  Copyright (c) 2014 the screaming organization. All rights reserved.
//

import Foundation

public struct Stylesheet {
    public let rules: [Rule]
    
    public var description: String {
        return "stylesheet"
    }
}

public struct Rule {
    public let selectors: [Selector]
    public let declarations: [Declaration]
}

public enum Selector {
    case Simple(SimpleSelector)
}

public struct SimpleSelector {
    public var tagName: String?
    public var id: String?
    public var clazz: [String]
}

public struct Declaration {
    public let name: String
    public let value: Value
}

public enum Value {
    case Keyword(String)
    case Length(Float, Unit)
    case Color(UInt8, UInt8, UInt8, UInt8) // RGBA
}

public enum Unit {
    case Px
}

public typealias Specificity = (Int, Int, Int)

extension Selector {
    
    public var specificity: Specificity {
        switch self {
        case .Simple(let simple):
            let a = simple.id == nil ? 0 : 1
            let b = simple.clazz.count
            let c = simple.tagName == nil ? 0 : 1
            return Specificity(a, b, c)
        }
    }
    
    public var description: String {
        switch self {
        case .Simple(let simple):
            return simple.description
        }
    }

}

extension SimpleSelector {
    public var description: String {
        switch (self.tagName, self.id) {
        case (.Some(let t), .None):
            return "t:\(t), \(clazz)"
        case (.None, .Some(let i)):
            return "i:\(i), \(clazz)"
        case (.Some(let t), .Some(let i)):
            return "t: \(t), i:\(i), \(clazz)"
        case (.None, .None):
            return "\(clazz)"
            }
    }
}


extension Value {
    // Return the size of a length in px, or zero for non-lengths.
    public func toPx() -> Float {
        switch self {
            case Length(let f, .Px): return f
            case _: return 0.0
        }
    }
}

// Parse a whole CSS stylesheet.
public func parseCss(source: String) -> Stylesheet {
    var parser = CssParser(pos: source.startIndex, input: source )
    return Stylesheet(rules: parser.parseRules())
}

struct CssParser {
    var pos: String.Index
    let input: String
}

extension CssParser {
    // Parse a list of rule sets, separated by optional whitespace.
    mutating func parseRules() -> [Rule] {
        var rules: [Rule] = []
        while (true) {
            self.consumeWhitespace()
            if self.eof() {
                break
            }
            rules.append(self.parseRule())
        }
        return rules;
    }
    
    // Parse a rule set: `<selectors> { <declarations> }`.
    mutating func parseRule() -> Rule {
        return Rule(selectors: self.parseSelectors(), declarations: self.parseDeclarations())
    }
    
    // Parse a comma-separated list of selectors.
    mutating func parseSelectors() -> [Selector] {
        var selectors: [Selector] = []
        outerLoop: while (true)  {
            selectors.append(.Simple(self.parseSimpleSelector()))
            self.consumeWhitespace()
            let c = self.nextCharacter()
            switch c {
                case ",":
                    self.consumeCharacter()
                    self.consumeWhitespace()
                case "{":
                    break outerLoop
                case _:
                    assert(false, "Unexpected character \(c) in selector list")
            }
        }
        // Return selectors with highest specificity first, for use in matching.
        selectors.sort {
            $0 > $1
        }
        return selectors
    }
    
    // Parse one simple selector, e.g.: `type#id.class1.class2.class3`
    mutating func parseSimpleSelector() -> SimpleSelector {
        var selector = SimpleSelector(tagName: nil, id: nil, clazz: [])
        while !self.eof() {
            switch self.nextCharacter() {
            case "#":
                self.consumeCharacter()
                selector.id = self.parseIdentifier()
            case ".":
                self.consumeCharacter()
                selector.clazz.append(self.parseIdentifier())
            case "*":
                // universal selector
                self.consumeCharacter()
            case let c where validIdentifierChar(c):
                selector.tagName = self.parseIdentifier()
            case _:
                break
            }
        }
        return selector;
    }
    
    // Parse a list of declarations enclosed in `{ ... }`.
    mutating func parseDeclarations() -> [Declaration] {
        assert(self.consumeCharacter() == "{")
        var declarations: [Declaration] = []
        while (true)  {
            self.consumeWhitespace()
            if self.nextCharacter() == "}" {
                self.consumeCharacter()
                break;
            }
            declarations.append(self.parseDeclaration())
        }
        return declarations;
    }


    // Parse one `<property>: <value>;` declaration.
    mutating func parseDeclaration() -> Declaration {
        let propertyName = self.parseIdentifier()
        self.consumeWhitespace()
        assert(self.consumeCharacter() == ":")
        self.consumeWhitespace()
        let value = self.parseValue()
        self.consumeWhitespace()
        assert(self.consumeCharacter() == ";")
        
        return Declaration (name: propertyName, value: value)
    }


    // Methods for parsing values:

    mutating func parseValue() -> Value {
        switch self.nextCharacter() {
        case "0"..."9": return self.parseLength()
        case "#": return self.parseColor()
        case _: return .Keyword(self.parseIdentifier())
        }
    }

    mutating func parseLength() -> Value {
        return .Length(self.parseFloat(), self.parseUnit())
    }

    mutating func parseFloat() -> Float {
        let s = self.consumeWhile() {
            switch $0 {
            case "0"..."9", ".": return true
            case _: return false
            }
        }
        var result: Float = 0.0
        let success = NSScanner(string: s).scanFloat(&result)
        return Float(result)
    }

    mutating func parseUnit() -> Unit {
        switch self.parseIdentifier().lowercaseString {
        case "px": return .Px
        case _: assert(false, "unrecognized unit")
        }
    }

    mutating func parseColor() -> Value {
        assert(self.consumeCharacter() == "#")
        return .Color(self.parseHexPair(), self.parseHexPair(), self.parseHexPair(), 255)
    }
    
    // Parse two hexadecimal digits.
    mutating func parseHexPair() -> UInt8 {
        let plusTwo = self.pos.successor().successor()
        let s = self.input.substringFromIndex(self.pos).substringWithRange(Range(start: self.pos, end: plusTwo))
        self.pos = plusTwo
        var result: CUnsignedInt = 0
        let success = NSScanner(string: s).scanHexInt(&result)
        return UInt8(result)
    }
    
    // Parse a property name or keyword.
    mutating func parseIdentifier() -> String {
        return self.consumeWhile(validIdentifierChar)
    }

    // Consume and discard zero or more whitespace Character.
    mutating func consumeWhitespace() {
        self.consumeWhile( {$0.isMemberOf(NSCharacterSet.whitespaceCharacterSet()) })
    }
    
    // Consume Character until `test` returns false.
    mutating func consumeWhile(test: Character -> Bool) -> String {
        var result = ""
        while !self.eof() && test(self.nextCharacter()) {
            result.append(consumeCharacter())
        }
        return result
    }

    // Return the current Character, and advance self.pos to the next Character.
    mutating func consumeCharacter() -> Character {
        let result = input[self.pos]
        self.pos = self.pos.successor()
        return result
    }
    
    // Read the current Character without consuming it.
    func nextCharacter() -> Character {
        return input[self.pos]
    }
    
    // Return true if all input is consumed.
    func eof() -> Bool {
        return self.pos >= self.input.endIndex
    }
    
}

func > (left:Specificity, right:Specificity) -> Bool {
    if left.0 == right.0 {
        if left.1 == right.1 {
            return left.2 > right.2
        } else {
            return left.1 > right.1
        }
    } else {
        return left.0 > right.0
    }
}

func > (left: Selector, right: Selector) -> Bool {
    return left.specificity > right.specificity
}

func validIdentifierChar(c: Character) -> Bool {
    switch c {
        case "a"..."z", "A"..."Z", "0"..."9", "-", "_": return true // TODO: Include U+00A0 and higher.
        case _: return false
    }
}

