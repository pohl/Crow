//
//  Html.swift
//  Crow
//
//  Created by Pohl Longsine on 8/17/14.
//  Copyright (c) 2014 the screaming organization. All rights reserved.
//

import Foundation

// A simple parser for a tiny subset of HTML.
//
// Can parse basic opening and closing tags, and text nodes.
//
// Not yet supported:
//
// * Comments
// * Doctypes and processing instructions
// * Self-closing tags
// * Non-well-formed markup
// * Characteracter entities


struct Parser {
    var pos: String.UnicodeScalarView.Index
    let input: String.UnicodeScalarView

    init(input: String) {
        self.input = input.unicodeScalars
        self.pos = self.input.startIndex
    }
}

/// Parse an HTML document and return the root element.
public func parse(source: String) -> Node {
    var parser = Parser(input: source)
    let nodes = parser.parseNodes()
    // If the document contains a root element, just return it. Otherwise, create one.
    if nodes.count == 1 {
        return nodes[0]
    } else {
        return Node(name: "html", attrs: [:], children: nodes)
    }
}

extension Character {

    func isMemberOf(set: NSCharacterSet) -> Bool {
        let bridgedCharacter = (String(self) as NSString).characterAtIndex(0)
        return set.characterIsMember(bridgedCharacter)
    }

}

extension Parser {
    /// Parse a sequence of sibling nodes.
    mutating func parseNodes() -> [Node] {
        var nodes: [Node] = []
        while (true) {
            self.consumeWhitespace()
            if self.eof() || self.startsWith("</") {
                break
            }
            nodes.append(self.parse_node())
        }
        return nodes
    }
    
    /// Parse a single node.
    mutating func parse_node() -> Node {
        switch self.nextCharacter() {
            case "<": return self.parseElement()
            case _: return self.parseText()
        }
    }
    
    /// Parse a single element, including its open tag, contents, and closing tag.
    mutating func parseElement() -> Node {
        // Opening tag.
        assert(self.consumeCharacter() == "<")
        let tag_name = self.parseTagName()
        let attrs = self.parseAttributes()
        assert(self.consumeCharacter() == ">")
        
        // Contents.
        let children = self.parseNodes()
        
        // Closing tag.
        assert(self.consumeCharacter() == "<")
        assert(self.consumeCharacter() == "/")
        assert(self.parseTagName() == tag_name)
        assert(self.consumeCharacter() == ">")
        
        return Node(name: tag_name, attrs: attrs, children: children)
    }
    
    /// Parse a tag or attribute name.
    mutating func parseTagName() -> String {
        return self.consumeWhile( {c in c.isMemberOf(NSCharacterSet.alphanumericCharacterSet()) })
    }
    
    /// Parse a list of name="value" pairs, separated by whitespace.
    mutating func parseAttributes() -> AttrMap {
        var attributes: AttrMap = [:]
        while (true) {
            self.consumeWhitespace()
            if self.nextCharacter() == ">" {
                break
            }
            let (name, value) = self.parseAttr()
            attributes[name] = value
        }
        return attributes
    }
    
    /// Parse a single name="value" pair.
    mutating func parseAttr() -> (String, String) {
        let name = self.parseTagName()
        assert(self.consumeCharacter() == "=")
        let value = self.parseAttrValue()
        return (name, value)
    }
    
    /// Parse a quoted value.
    mutating func parseAttrValue() -> String {
        let open_quote = self.consumeCharacter()
        assert(open_quote == "\"" || open_quote == "'")
        let value = self.consumeWhile( {c in c != open_quote} )
        assert(self.consumeCharacter() == open_quote)
        return value
    }
    
    /// Parse a text node.
    mutating func parseText() -> Node {
        return Node(data: self.consumeWhile({c in c != "<" }))
    }
    
    /// Consume and discard zero or more whitespace Character.
    mutating func consumeWhitespace() {
        self.consumeWhile( {c in c.isMemberOf(NSCharacterSet.whitespaceCharacterSet()) })
    }
    
    /// Consume Character until `test` returns false.
    mutating func consumeWhile(test: Character -> Bool) -> String {
        var result = ""
        while !self.eof() && test(self.nextCharacter()) {
            result.append(consumeCharacter())
        }
        return result
    }
    
    /// Return the current Character, and advance self.pos to the next Character.
    mutating func consumeCharacter() -> Character {
        let result = input[self.pos]
        self.pos = self.pos.successor()
        return Character(result)
    }
    
    /// Read the current Character without consuming it.
    func nextCharacter() -> Character{
        return Character(input[self.pos])
    }
    
    /// Does the current input start with the given string?
    func startsWith(s: String) -> Bool {
        var index = self.pos
        for character in s {
            if character != Character(self.input[index]) {
                return false
            }
        }
        return true
    }
    
    /// Return true if all input is consumed.
    func eof() -> Bool {
        return self.pos >= self.input.endIndex
    }
}