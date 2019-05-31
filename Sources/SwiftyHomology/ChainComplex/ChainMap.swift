//
//  GradedModuleMap.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/23.
//

import Foundation
import SwiftyMath

public typealias  ChainMap<A: FreeModuleGenerator, B: FreeModuleGenerator, R: Ring> = ChainMapN<_1, A, B, R>
public typealias ChainMap2<A: FreeModuleGenerator, B: FreeModuleGenerator, R: Ring> = ChainMapN<_2, A, B, R>

public struct ChainMapN<n: StaticSizeType, A: FreeModuleGenerator, B: FreeModuleGenerator, R: Ring> {
    public typealias Hom = ModuleHom<FreeModule<A, R>, FreeModule<B, R>>
    
    public var mDegree: IntList
    internal let f: (IntList) -> Hom
    
    public init(mDegree: IntList, _ f: @escaping (IntList) -> Hom) {
        self.mDegree = mDegree
        self.f = f
    }
    
    public subscript(_ I: IntList) -> Hom {
        return f(I)
    }
    
    public func shifted(_ I0: IntList) -> ChainMapN<n, A, B, R> {
        return ChainMapN(mDegree: mDegree) { I in self[I - I0] }
    }

    public func assertChainMap(from C0: ChainComplexN<n, A, R>, to C1: ChainComplexN<n, B, R>, debug: Bool = false) {
        assert(C0.dDegree == C1.dDegree)
        
        //          d0
        //  C0[I0] -----> C0[I1]
        //     |           |
        //   f |           | f
        //     v           v
        //  C1[I2] -----> C1[I3]
        //          d1
        
        let (f, d0, d1) = (self, C0.d, C1.d)
        
        func print(_ msg: @autoclosure () -> String) {
            Swift.print(msg())
        }
        
        for I0 in C0.indices {
            let (I1, I2, I3) = (I0 + d0.mDegree, I0 + f.mDegree, I0 + d0.mDegree + f.mDegree)
            
            guard let s0 = C0[I0], let s3 = C1[I3] else {
                    print("\(I0): undeterminable.")
                    continue
            }
            
            print("\(I0): \(s0) -> \(s3)")
            
            for x in s0.generators {
                let y0 = d0[I0].applied(to: x)
                let z0 =  f[I1].applied(to: y0)
                print("\t\(x) ->\t\(y0) ->\t\(z0)")
                
                let y1 =  f[I0].applied(to: x)
                let z1 = d1[I2].applied(to: y1)
                print("\t\(x) ->\t\(y1) ->\t\(z1)")
                print("")
                
//                assert(s3.elementsAreEqual(z0, z1))
            }
        }
    }
}

extension ChainMapN where R: EuclideanRing {
    public func matrix(from: ChainComplexN<n, A, R>, to: ChainComplexN<n, B, R>, at I: IntList) -> DMatrix<R>? {
        guard let s0 = from[I], let s1 = to[I + mDegree] else {
            return nil
        }
        
        if s0.isZero || s1.isZero {
            return .zero(rows: s1.generators.count, cols: s0.generators.count) // trivially zero
        }
        
        let map = self[I]
        
        if  s0.isFree, s0.generators.allSatisfy({ $0.isSingle }),
            s1.isFree, s1.generators.allSatisfy({ $0.isSingle }) {
            
            let (from, to) = (s0.generators.map{ $0.generators[0] }, s1.generators.map{ $0.generators[0] })
            let toIndexer = to.indexer()
            
            let components = from.enumerated().flatMap{ (j, x) -> [MatrixComponent<R>] in
                map.applied(to: .wrap(x)).elements.map { (y, a) -> MatrixComponent<R> in
                    guard let i = toIndexer(y) else {
                        fatalError("not an element of the codomain: \(y)")
                    }
                    return MatrixComponent(i, j, a)
                }
            }
            
            return DMatrix(rows: to.count, cols: from.count, components: components)
        }
        
        let grid = s0.generators.flatMap { x -> [R] in
            let y = map.applied(to: x)
            return s1.factorize(y)
        }
        
        return DMatrix(rows: s0.generators.count, cols: s1.generators.count, grid: grid).transposed
    }

    public func dual(from: ChainComplexN<n, A, R>, to: ChainComplexN<n, B, R>) -> ChainMapN<n, Dual<B>, Dual<A>, R> {
        typealias F = ChainMapN<n, Dual<B>, Dual<A>, R>
        return F(mDegree: -mDegree) { I1 in
            ModuleHom.linearlyExtend{ (b: Dual<B>) in
                let I0 = I1 - self.mDegree
                guard let s0 = from[I0],
                    let s1  =  to[I1],
                    let matrix = self.matrix(from: from, to: to, at: I0) else {
                        return .zero
                }
                
                guard s0.isFree, s0.generators.allSatisfy({ $0.isSingle }),
                    s1.isFree, s1.generators.allSatisfy({ $0.isSingle }) else {
                        fatalError("inavailable")
                }
                
                // MEMO: the matrix of the dual-map w.r.t the dual-basis is the transpose of the original.
                
                guard let i = s1.generators.firstIndex(where: { $0.unwrap() == b.base }) else {
                    fatalError()
                }
                
                return matrix.nonZeroComponents(ofRow: i).sum { (c: MatrixComponent<R>) in
                    let (j, r) = (c.col, c.value)
                    return r * s0.generator(j).convertGenerators{ $0.dual }
                }
            }
        }
    }
}

extension ChainMapN where n == _1 {
    public init(degree: Int, _ f: @escaping (Int) -> Hom) {
        self.init(mDegree: IntList(degree)) { I in f(I[0]) }
    }
    
    public subscript(_ i: Int) -> Hom {
        return self[IntList(i)]
    }
    
    public var degree: Int {
        return mDegree[0]
    }
}

extension ChainMapN where R: EuclideanRing, n == _1 {
    public func matrix(from: ChainComplex<A, R>, to: ChainComplex<B, R>, at i: Int) -> DMatrix<R>? {
        return matrix(from: from, to: to, at: IntList(i))
    }
}

extension ChainMapN where n == _2 {
    public init(bidegree: (Int, Int), _ f: @escaping (Int, Int) -> Hom) {
        let (i, j) = bidegree
        self.init(mDegree: IntList(i, j)) { I in f(I[0], I[1]) }
    }
    
    public subscript(_ i: Int, _ j: Int) -> Hom {
        return self[IntList(i, j)]
    }
    
    public var bidegree: (Int, Int) {
        return (mDegree[0], mDegree[1])
    }
}
