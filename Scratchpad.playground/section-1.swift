// Playground - noun: a place where people can play

import Foundation

enum Foo {
    case Bar(Int)
    case Baz(Int)
}

extension Foo {
    
    func test() -> Bool {
        switch self {
            case .Bar(let x):
                return x == 3
            case .Baz(let y):
                return y == 7
        }
    }
}

let e: Foo = .Bar(3)

e.test()


public enum Selector {
    case Simple(SimpleSelector)
}

public struct SimpleSelector {
    public var tagName: String?
    public var id: String?
    public var clazz: [String]
    
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


public typealias Specificity = (Int, Int, Int)

extension Selector {
    
    public var specificity: Specificity {
        // http://www.w3.org/TR/selectors/#specificity
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



let fooBar: [String] = ["foo","bar"]
let ss1 = SimpleSelector(tagName: .None, id: .None, clazz: fooBar)
let ss2 = SimpleSelector(tagName: "div", id: .None, clazz: [])
let ss3 = SimpleSelector(tagName: .None, id: "menu", clazz: [])

let s1: Selector = .Simple(ss1)
let s2 = Selector.Simple(ss2)
let s3 = Selector.Simple(ss3)
s1.specificity
s2.specificity

func < (left:Specificity, right:Specificity) -> Bool {
    if left.0 == right.0 {
        if left.1 == right.1 {
            return left.2 < right.2
        } else {
            return left.1 < right.1
        }
    } else {
        return left.0 < right.0
    }
}

func < (left: Selector, right: Selector) -> Bool {
    return left.specificity < right.specificity
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

s1.specificity < s2.specificity
s2.specificity < s1.specificity

Specificity(0,0,1) < Specificity(0,0,2) // expect true
Specificity(0,0,2) < Specificity(0,1,2) // expect true
Specificity(0,0,2) < Specificity(1,0,2) // expect true
Specificity(1,0,2) < Specificity(1,1,2) // expect true
Specificity(1,0,0) < Specificity(1,1,2) // expect true
Specificity(1,1,1) < Specificity(1,1,2) // expect true
Specificity(1,1,0) < Specificity(1,1,1) // expect true


Specificity(0,0,0) < Specificity(0,0,0) // expect false
Specificity(0,0,1) < Specificity(0,0,0) // expect false
Specificity(0,0,1) < Specificity(0,0,1) // expect false
Specificity(0,0,1) < Specificity(0,0,1) // expect false
Specificity(0,1,1) < Specificity(0,0,1) // expect false
Specificity(1,1,0) < Specificity(1,1,0) // expect false
Specificity(1,1,1) < Specificity(1,1,1) // expect false
Specificity(1,1,2) < Specificity(1,1,1) // expect false

var selectors: [Selector] = [s1,s2, s3]

selectors.sort { $0 > $1 }



let descriptions = selectors.map { $0.description }

descriptions

extension Character {
    
    func isMemberOf(set: NSCharacterSet) -> Bool {
        let bridgedCharacter = (String(self) as NSString).characterAtIndex(0)
        return set.characterIsMember(bridgedCharacter)
    }
    
}


for c in "   \n  \t   " {
    println("\(c.isMemberOf(NSCharacterSet.whitespaceAndNewlineCharacterSet()))")
}

