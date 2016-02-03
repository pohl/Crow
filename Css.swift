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
    public var classes: [String]
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
            let b = simple.classes.count
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
            return "t:\(t), \(classes)"
        case (.None, .Some(let i)):
            return "i:\(i), \(classes)"
        case (.Some(let t), .Some(let i)):
            return "t: \(t), i:\(i), \(classes)"
        case (.None, .None):
            return "\(classes)"
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
    
    init(input: String) {
        self.input = input
        self.pos = self.input.startIndex
    }
    
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
        outerLoop: while true {
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
        selectors.sortInPlace {
            $0 > $1
        }
        return selectors
    }
    
    // Parse one simple selector, e.g.: `type#id.class1.class2.class3`
    mutating func parseSimpleSelector() -> SimpleSelector {
        var selector = SimpleSelector(tagName: nil, id: nil, classes: [])
        outerLoop: while !self.eof() {
            switch self.nextCharacter() {
            case "#":
                self.consumeCharacter()
                selector.id = self.parseIdentifier()
            case ".":
                self.consumeCharacter()
                selector.classes.append(self.parseIdentifier())
            case "*":
                // universal selector
                self.consumeCharacter()
            case let c where validIdentifierChar(c):
                selector.tagName = self.parseIdentifier()
            case _:
                break outerLoop
            }
        }
        return selector;
    }
    
    // Parse a list of declarations enclosed in `{ ... }`.
    mutating func parseDeclarations() -> [Declaration] {
        let leftCurly = self.consumeCharacter();
        assert(leftCurly == "{")
        var declarations: [Declaration] = []
        while true  {
            self.consumeWhitespace()
            if self.nextCharacter() == "}" {
                self.consumeCharacter()
                break
            }
            declarations.append(self.parseDeclaration())
        }
        return declarations;
    }


    // Parse one `<property>: <value>;` declaration.
    mutating func parseDeclaration() -> Declaration {
        let propertyName = self.parseIdentifier()
        self.consumeWhitespace()
        let colon = self.consumeCharacter()
        assert(colon == ":")
        self.consumeWhitespace()
        let value = self.parseValue()
        self.consumeWhitespace()
        let semicolon = self.consumeCharacter()
        assert(semicolon == ";")
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
        let hash = self.consumeCharacter();
        assert(hash == "#")
        return .Color(self.parseHexPair(), self.parseHexPair(), self.parseHexPair(), 255)
    }
    
    // Parse two hexadecimal digits.
    mutating func parseHexPair() -> UInt8 {
        let plusTwo = self.pos.successor().successor()
        let hexPairRange = Range(start: self.pos, end: plusTwo)
        let s = self.input.substringWithRange(hexPairRange)
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
        self.consumeWhile( {$0.isMemberOf(NSCharacterSet.whitespaceAndNewlineCharacterSet()) })
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

func validIdentifierChar(c: Character) -> Bool {
    switch c {
    case "a"..."z", "A"..."Z", "0"..."9", "-", "_": return true // TODO: Include U+00A0 and higher.
    case _: return false
    }
}

func > (lhs:Specificity, rhs:Specificity) -> Bool {
    if lhs.0 == rhs.0 {
        if lhs.1 == rhs.1 {
            return lhs.2 > rhs.2
        } else {
            return lhs.1 > rhs.1
        }
    } else {
        return lhs.0 > rhs.0
    }
}

func > (lhs: Selector, rhs: Selector) -> Bool {
    return lhs.specificity > rhs.specificity
}

public func == (lhs: Value, rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.Keyword(let k1), .Keyword(let k2)):
        return k1 == k2
    case (.Length(let f1, let u1), .Length(let f2, let u2)):
        return f1 == f2 && u1 == u2
    case (.Color(let r1, let g1, let b1, let a1), .Color(let r2, let g2, let b2, let a2)):
        return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2
    default:
        return false
    }
}

public func == (lhs: SimpleSelector, rhs: SimpleSelector) -> Bool {
    return lhs.tagName == rhs.tagName && lhs.id == rhs.id && lhs.classes == rhs.classes
}


