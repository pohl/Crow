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

    func testCssParser() {
        let bundle: NSBundle = NSBundle(forClass: CssTests.classForKeyedArchiver())
        let filePath = bundle.pathForResource("test", ofType: "css")
        XCTAssert(filePath != nil, "Found css resource")
        var error: NSError? = nil
        var css: String? = String.stringWithContentsOfFile(filePath!, encoding: NSUTF8StringEncoding, error: &error)
        XCTAssert(css != nil, "read css input")
        let stylesheet: Stylesheet = parseCss(css!)
        println("dump of CSS: \n\(stylesheet.description)")
    }
    

}
