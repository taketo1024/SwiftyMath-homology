//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import Foundation
import SwiftyMath

// TODO substitute for old ChainComplex.

public typealias  ChainComplex<A: FreeModuleGenerator, R: Ring> = ChainComplexN<_1, A, R>
public typealias ChainComplex2<A: FreeModuleGenerator, R: Ring> = ChainComplexN<_2, A, R>

public struct ChainComplexN<n: StaticSizeType, A: FreeModuleGenerator, R: Ring>: CustomStringConvertible {
    public typealias Base = ModuleGridN<n, A, R>
    public typealias Differential = ChainMapN<n, A, A, R>
    public typealias Object = ModuleObject<A, R>
    
    public var base: Base
    public let d: Differential
    
    internal let dMatrices: [IntList : Cache<DMatrix<R>>]
    internal let _freePart = Cache<ChainComplexN<n, A, R>>()
    internal let  _torPart = Cache<ChainComplexN<n, A, R>>()

    public init(base: ModuleGridN<n, A, R>, differential d: Differential) {
        self.base = base
        self.d = d
        
        let degs = base.indices.flatMap{ I in [I, I - d.mDegree] }.unique()
        self.dMatrices = Dictionary(pairs: degs.map{ I in (I, .empty) })
    }
    
    public subscript(I: IntList) -> Object? {
        get {
            return base[I]
        } set {
            base[I] = newValue
        }
    }
    
    internal var dDegree: IntList {
        return d.mDegree
    }
    
    public var indices: [IntList] {
        return base.indices
    }
    
    public var name: String {
        return base.name
    }
    
    public func named(_ name: String) -> ChainComplexN<n, A, R> {
        return ChainComplexN(base: base.named(name), differential: d)
    }
    
    public func shifted(_ I: IntList) -> ChainComplexN<n, A, R> {
        return ChainComplexN(base: base.shifted(I), differential: d.shifted(I))
    }
    
    public var freePart: ChainComplexN<n, A, R> {
        return _freePart.useCacheOrSet {
            ChainComplexN<n, A, R>(base: base.freePart, differential: d)
        }
    }
    
    public var torsionPart: ChainComplexN<n, A, R> {
        return _torPart.useCacheOrSet {
            ChainComplexN(base: base.torsionPart, differential: d)
        }
    }
    
    public func assertChainComplex(debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            if debug { Swift.print(msg()) }
        }
        
        for I0 in indices {
            let I1 = I0 + dDegree
            let I2 = I1 + dDegree
            
            guard let s0 = self[I0],
                  let s1 = self[I1],
                  let s2 = self[I2] else {
                    print("\(I0): undeterminable.")
                    continue
            }
            
            print("\(I0): \(s0) -> \(s1) -> \(s2)")
            
            for x in s0.generators {
                let y = d[I0].applied(to: x)
                
                let z = d[I1].applied(to: y)
                print("\t\(x) ->\t\(y) ->\t\(z)")
                
//                assert(s1.contains(y))
//                assert(s2.contains(z))
//                assert(s2.elementIsZero(z))
            }
        }
    }
    
    public func describeAll() {
        base.describeAll()
    }
    
    public func describe(_ I: IntList) {
        base.describe(I)
    }
    
    public var description: String {
        return base.description
    }
}

extension ChainComplexN where R: EuclideanRing {
    // MEMO works only when each generator is a single basis-element.
    
    public func dual(name: String? = nil) -> ChainComplexN<n, Dual<A>, R> {
        typealias D = ChainComplexN<n, Dual<A>, R>
        
        let dName = name ?? "\(base.name)^*"
        let dGens = Dictionary(pairs:
            indices.map { I -> (IntList, [Dual<A>]) in
                guard let o = self[I], o.isFree, o.generators.allSatisfy({ $0.isSingle }) else {
                    fatalError("unavailable")
                }
                return (I, o.generators.map{ $0.unwrap().dual })
            }
        )
        let dBase = D.Base(name: dName, generators: dGens)
        let dDiff = d.dual(from: self, to: self)
        
        return D(base: dBase, differential: dDiff)
    }
}

extension ChainComplexN where n == _1 {
    public subscript(i: Int) -> Object? {
        get {
            return base[i]
        } set {
            base[i] = newValue
        }
    }
    
    public var bottomDegree: Int {
        return base.bottomDegree
    }
    
    public var topDegree: Int {
        return base.topDegree
    }
    
    public func shifted(_ i: Int) -> ChainComplex<A, R> {
        return shifted(IntList(i))
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
}

extension ChainComplexN where n == _2 {
    public subscript(i: Int, j: Int) -> Object? {
        get {
            return base[i, j]
        } set {
            base[i, j] = newValue
        }
    }
    
    public func shifted(_ i: Int, _ j: Int) -> ChainComplex2<A, R> {
        return shifted(IntList(i, j))
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
    
    public func printTable() {
        base.printTable()
    }
}
