//
//  CrowTests.swift
//  CrowTests
//
//  Created by Pohl Longsine on 8/16/14.
//  Copyright (c) 2014 the screaming organization. All rights reserved.
//

import Cocoa
import XCTest


class HtmlTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testParserFoundation() {
        var parser = HtmlParser(input:"    A    BC")
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
        var parser = HtmlParser(input:"this is a test</p>")
        XCTAssert(parser.nextCharacter() == "t")
        let node: Node = parser.parseText()
        XCTAssert(parser.nextCharacter() == "<")
        XCTAssert(node.nodeType == NodeType.Text("this is a test"))
    }
    
    func testParseTagName() {
        var parser = HtmlParser(input:"div>fnord")
        XCTAssert(parser.nextCharacter() == "d")
        let name = parser.parseTagName()
        XCTAssert(name == "div")
        XCTAssert(parser.nextCharacter() == ">")
    }
    
    func testStartsWith() {
        let parser = HtmlParser(input:"</fnord>")
        XCTAssert(parser.startsWith("<"))
        XCTAssert(parser.startsWith("</"))
        XCTAssert(parser.startsWith("</fno"))
    }
    

    func testParseDivNodeWithText() {
        var parser = HtmlParser(input:"<div>banana hammock</div>")
        XCTAssert(parser.nextCharacter() == "<")
        let node: Node = parser.parseElement()
        XCTAssert(parser.eof())
        XCTAssert(node.nodeType == NodeType.Element(ElementData(tagName: "div", attributes: [:])))
        XCTAssert(node.children.count == 1)
        let child = node.children[0]
        XCTAssert(child.nodeType == NodeType.Text("banana hammock"))
    }
    
    func testHtmlParser() {
        let bundle: NSBundle = NSBundle(forClass: HtmlTests.classForKeyedArchiver()!)
        let filePath = bundle.pathForResource("test", ofType: "html")
        XCTAssert(filePath != nil, "Found html resource")
        do {
        let html: String? = try String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
            XCTAssert(html != nil, "read html input")
            let node: Node = parseHtml(html!)
            print("dump of DOM: \n\(node.description)")
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }

       
    
}
