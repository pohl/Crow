//
//  CrowTests.swift
//  CrowTests
//
//  Created by Pohl Longsine on 8/16/14.
//  Copyright (c) 2014 the screaming organization. All rights reserved.
//

import Cocoa
import XCTest
import Crow


class CrowTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testParserFoundation() {
        var parser = Parser(input:"    A    BC")
        XCTAssert(parser.nextCharacter() == " ")
        parser.consumeWhitespace()
        XCTAssert(parser.nextCharacter() == "A")
        XCTAssert(parser.consumeCharacter() == "A")
        XCTAssert(parser.nextCharacter() == " ")
        parser.consumeWhitespace()
        XCTAssert(parser.nextCharacter() == "B")
        XCTAssert(parser.consumeCharacter() == "B")
        XCTAssert(parser.nextCharacter() == "C")
        parser.consumeWhitespace()
        XCTAssert(parser.nextCharacter() == "C")
        XCTAssert(!parser.eof())
        XCTAssert(parser.consumeCharacter() == "C")
        XCTAssert(parser.eof())
    }
    
    func testParseTextNode() {
        var parser = Parser(input:"this is a test</p>")
        XCTAssert(parser.nextCharacter() == "t")
        let node: Node = parser.parseText()
        XCTAssert(parser.nextCharacter() == "<")
        XCTAssert(node.nodeType == NodeType.Text("this is a test"))
    }
    
    func testParseTagName() {
        var parser = Parser(input:"div>fnord")
        XCTAssert(parser.nextCharacter() == "d")
        let name = parser.parseTagName()
        XCTAssert(name == "div")
        XCTAssert(parser.nextCharacter() == ">")
    }
    
    func testStartsWith() {
        var parser = Parser(input:"</fnord>")
        XCTAssert(parser.startsWith("<"))
        XCTAssert(parser.startsWith("</"))
        XCTAssert(parser.startsWith("</fno"))
    }
    

    func testParseDivNodeWithText() {
        var parser = Parser(input:"<div>banana hammock</div>")
        XCTAssert(parser.nextCharacter() == "<")
        let node: Node = parser.parseElement()
        XCTAssert(parser.eof())
        XCTAssert(node.nodeType == NodeType.Element(ElementData(tagName: "div", attributes: [:])))
        XCTAssert(node.children.count == 1)
        let child = node.children[0]
        XCTAssert(child.nodeType == NodeType.Text("banana hammock"))
    }
    
    func testExample() {
        let bundle: NSBundle = NSBundle(forClass: CrowTests.classForKeyedArchiver())
        let filePath = bundle.pathForResource("test", ofType: "html")
        XCTAssert(filePath != nil, "Found html resource")
        var error: NSError? = nil
        var html: String? = String.stringWithContentsOfFile(filePath!, encoding: NSUTF8StringEncoding, error: &error)
        XCTAssert(html != nil, "read html input")
        let node: Node = parse(html!)
        println("dump of DOM: \n\(node.description)")
    }

       
    
}
