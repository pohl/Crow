//
//  Dom.swift
//  Basic DOM data structures.
//  Crow
//
//  Created by Pohl Longsine on 8/16/14.
//  Copyright (c) 2014 the screaming organization. All rights reserved.
//

import Foundation



public typealias AttrMap = [String:String]

public struct Node {
    // data common to all nodes:
    public let children: [Node]
    // data specific to each node type:
    public let nodeType: NodeType
}

public enum NodeType {
    case Element(ElementData)
    case Text(String)
}

public struct ElementData {
    public let tagName: String
    public let attributes: AttrMap
}

// Constructor functions for convenience:

extension ElementData {
    public init(tagName: String, attrs: AttrMap) {
        self.tagName = tagName
        self.attributes = attrs
    }
}

extension Node {
    
    public init(data: String) {
        self.children = []
        self.nodeType = .Text(data)
    }
    
    public init(name: String, attrs: AttrMap, children: [Node]) {
        self.children = children
        let data = ElementData(tagName: name, attributes: attrs)
        self.nodeType = .Element(data)
    }
    
}

// Element methods

extension ElementData {
    public func getAttribute(key: String) -> String? {
        return self.attributes[key]
    }
    
    public func id() -> String? {
        return self.getAttribute("id")
    }
    
    public func classes() -> [String] {
        switch self.getAttribute("class") {
        case .Some(let classList):
            return classList.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " "))
        case .None:
            return []
        }
    }
}
