//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/18.
//

import SwiftyMath

public struct MultiIndex<n: StaticSizeType>: AdditiveGroup, ExpressibleByArrayLiteral, Comparable, Hashable {
    public typealias ArrayLiteralElement = Int
    
    public let indices: [Int]
    
    public init(_ indices: [Int]) {
        assert(indices.count == n.intValue)
        self.indices = indices
    }
    
    public init(_ indices: Int...) {
        self.init(indices)
    }
    
    public init(arrayLiteral elements: Int...) {
        self.init(elements)
    }
    
    public subscript(_ i: Int) -> Int {
        indices[i]
    }
    
    public static var zero: MultiIndex<n> {
        .init(.init(repeating: 0, count: n.intValue))
    }
    
    public static func +(c1: Self, c2: Self) -> Self {
        .init( c1.indices.merging(c2.indices, filledWith: 0, mergedBy: +) )
    }
    
    public static prefix func -(_ c: Self) -> Self {
        .init( c.indices.map{ -$0 } )
    }

    public static func -(c1: Self, c2: Self) -> Self {
        .init( c1.indices.merging(c2.indices, filledWith: 0, mergedBy: -) )
    }
    
    public static func < (c1: Self, c2: Self) -> Bool {
        (c1.indices != c2.indices) && zip(c1.indices, c2.indices).allSatisfy{ $0 <= $1 }
    }
    
    public var description: String {
        "(\( indices.map{ $0.description }.joined(separator: ", ") ))"
    }
}

extension MultiIndex where n == _2 {
    public var tuple: (Int, Int) {
        (self[0], self[1])
    }
}

extension MultiIndex where n == _3 {
    public var triple: (Int, Int, Int) {
        (self[0], self[1], self[2])
    }
}
