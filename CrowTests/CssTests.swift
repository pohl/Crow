//
//  CssTests.swift
//  Crow
//
//  Created by Pohl Longsine on 9/6/14.
//  Copyright (c) 2014 the screaming organization. All rights reserved.
//

import Cocoa
import XCTest

class CssTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testConsumeWhitespace() {
        var parser = CssParser(input:"    \n            X")
        parser.consumeWhitespace()
        XCTAssert(parser.nextCharacter() == "X")
    }
    
    func testParseLengthDeclaration() {
        var parser = CssParser(input:"width: 600px;")
        XCTAssert(parser.nextCharacter() == "w")
        let d: Declaration = parser.parseDeclaration()
        XCTAssert(parser.eof())
        XCTAssert(d.name == "width")
        XCTAssert(d.value == Value.Length(600,.Px))
    }

    func testParseKeywordDeclaration() {
        var parser = CssParser(input:"margin: auto;")
        let d: Declaration = parser.parseDeclaration()
        XCTAssert(parser.eof())
        XCTAssert(d.name == "margin")
        XCTAssert(d.value == Value.Keyword("auto"))
    }

    func testParseColorDeclaration() {
        var parser = CssParser(input:"background: #4f5358;")
        let d: Declaration = parser.parseDeclaration()
        XCTAssert(parser.eof())
        XCTAssert(d.name == "background")
        XCTAssert(d.value == Value.Color(79,83,88,255))
    }

    func testParseEmptyDeclarations() {
        var parser = CssParser(input:"{   }")
        let d: [Declaration] = parser.parseDeclarations()
        XCTAssert(d.count == 0)
        XCTAssert(parser.eof())
    }
    
    func testParseDeclarations() {
        var parser = CssParser(input:"{ \n\twidth: 600px; \n margin: auto; \n\t\t background: #4f5358; \n\t}")
        let d: [Declaration] = parser.parseDeclarations()
        XCTAssert(d.count == 3)
        XCTAssert(parser.eof())
        let d1 = d[0]
        XCTAssert(d1.name == "width")
        XCTAssert(d1.value == Value.Length(600,.Px))
        let d2 = d[1]
        XCTAssert(d2.name == "margin")
        XCTAssert(d2.value == Value.Keyword("auto"))
        let d3 = d[2]
        XCTAssert(d3.name == "background")
        XCTAssert(d3.value == Value.Color(79,83,88,255))
    }
    
    func testParseSimpleSelector() {
        var parser = CssParser(input:"span#name {")
        let s: SimpleSelector = parser.parseSimpleSelector()
        let expected = SimpleSelector(tagName: "span", id: "name", classes: [])
        XCTAssert(s == expected)
    }

    func testParseSimpleSelectorWithClasses() {
        var parser = CssParser(input:".inner {")
        let s: SimpleSelector = parser.parseSimpleSelector()
        let expected = SimpleSelector(tagName: .None, id: .None, classes: ["inner"])
        XCTAssert(s == expected)
    }
    
    func testCssParser() {
        let bundle: NSBundle = NSBundle(forClass: CssTests.classForKeyedArchiver())
        let filePath = bundle.pathForResource("test", ofType: "css")
        XCTAssert(filePath != nil, "Found css resource")
        var error: NSError? = nil
        var css: String? = String.stringWithContentsOfFile(filePath!, encoding: NSUTF8StringEncoding, error: &error)
        XCTAssert(css != nil, "read css input")
        let ss: Stylesheet = parseCss(css!)
        //println("dump of CSS: \n\(ss.description)")
        XCTAssert(ss.rules.count == 6)
    }
    
    
    

}
