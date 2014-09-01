// Playground - noun: a place where people can play

import Foundation

var s = "Fnord"
let start = s.startIndex
let test = s[start.successor()]

func test(c: Character) -> String {
    switch c {
    case "0"..."9": return "numeric"
    case "b": return "B"
    case _: return "other"
    }
}

test("3")
test("b")
test("z")

func parseHex(s: String) -> UInt8 {
    var result: CUnsignedInt = 0
    var success = NSScanner(string: s).scanHexInt(&result)
    return UInt8(result)
}

func parseFloat(s: String) -> Float {
    var result: Float = 0.0
    let success = NSScanner(string: s).scanFloat(&result)
    return Float(result)
}

parseHex("ff")
parseFloat("1.234")
parseFloat("1.5")

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

