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

public enum NodeType: Equatable {
    case Element(ElementData)
    case Text(String)
}



public struct ElementData: Equatable {
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


extension Node: CustomStringConvertible {

    public var description: String {
        switch self.nodeType {
        case .Text(let text):
            return text
        case .Element(let data):
            var b = self.nodeType.description
            for child in self.children {
                b = b + child.description
            }
            return b + data.closingTag
        }
    }

}

extension NodeType: CustomStringConvertible {

    public var description: String {
        switch self {
        case .Text(let text):
            return text
        case .Element(let data):
            return data.description
        }

    }

}

extension ElementData: CustomStringConvertible {

    public var description: String {
        var b = "<" + self.tagName
        if self.attributes.count > 0 {
            b = b + " "
            for (key,value) in self.attributes {
                b = b + "\(key)=\"\(value)\""
            }
        }
        b = b + ">"
        return b
    }

    public var closingTag: String {
        return "</" + self.tagName + ">"
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


public func == (lhs: NodeType, rhs: NodeType) -> Bool {
    switch (lhs, rhs) {
        case (.Element(let ed1), .Element(let ed2)):
            return ed1 == ed2
        case (.Text(let t1), .Text(let t2)):
            return t1 == t2
        default:
            return false
    }
}


public func == (lhs: ElementData, rhs: ElementData) -> Bool {
    return lhs.tagName == rhs.tagName && lhs.attributes == rhs.attributes
}


