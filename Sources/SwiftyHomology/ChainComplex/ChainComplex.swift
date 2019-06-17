//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import Foundation
import SwiftyMath

public typealias ChainComplex1<M: Module> = ChainComplex<_1, M>
public typealias ChainComplex2<M: Module> = ChainComplex<_2, M>

public struct ChainComplex<GridDim: StaticSizeType, BaseModule: Module> {
    public typealias R = BaseModule.CoeffRing
    public typealias Differential = ChainMap<GridDim, BaseModule, BaseModule>
    
    public var grid: ModuleGrid<GridDim, BaseModule>
    public let differential: Differential

    public init(grid: ModuleGrid<GridDim, BaseModule>, differential: Differential) {
        self.grid = grid
        self.differential = differential
    }
    
    public subscript(I: IntList) -> ModuleObject<BaseModule> {
        return grid[I]
    }
    
    public subscript(I: Int...) -> ModuleObject<BaseModule> {
        return self[IntList(I)]
    }
    
    public var gridDim: Int {
        return GridDim.intValue
    }
    
    public func shifted(_ shift: IntList) -> ChainComplex<GridDim, BaseModule> {
        assert(shift.length == gridDim)
        return ChainComplex(grid: grid.shifted(shift), differential: differential.shifted(shift))
    }
    
    public func shifted(_ shift: Int...) -> ChainComplex<GridDim, BaseModule> {
        return shifted(IntList(shift))
    }
    
    public func isFreeToFree(_ I: IntList) -> Bool {
        return grid[I].isFree && grid[I + differential.multiDegree].isFree
    }
    
    public func differntialMatrix(_ I: IntList) -> DMatrix<R> {
        return differential.asMatrix(at: I, from: self, to: self)
    }
    
    public func assertChainComplex(at I0: IntList, debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            if debug { Swift.print(msg()) }
        }
        
        let deg = differential.multiDegree
        let (I1, I2) = (I0 + deg, I0 + deg + deg)
        let (s0, s1, s2) = (self[I0], self[I1], self[I2])
        
        print("\(I0): \(s0) -> \(s1) -> \(s2)")
        
        for x in s0.generators {
            let y = differential[I0].applied(to: x)
            
            let z = differential[I1].applied(to: y)
            print("\t\(x) ->\t\(y) ->\t\(z)")
            
            assert(self[I2].factorize(z).isZero)
        }
    }
}

extension ChainComplex where GridDim == _1 {
    // chain complex (degree: -1)
    public init(descendingSequence sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) {
        self.init(sequence: sequence, ascending: false, differential: d)
    }
    
    // cochain complex (degree: +1)
    public init(ascendingSequence sequence: @escaping (Int) -> ModuleObject<BaseModule>, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) {
        self.init(sequence: sequence, ascending: true, differential: d)
    }
    
    private init(sequence: @escaping (Int) -> ModuleObject<BaseModule>, ascending: Bool, differential d: @escaping (Int) -> ModuleHom<BaseModule, BaseModule>) {
        self.init(grid: ModuleGrid1(sequence: sequence), differential: Differential(degree: ascending ? 1 : -1, maps: d))
    }
    
    public func printSequence(indices: [Int]) {
        grid.printSequence(indices: indices)
    }
    
    public func printSequence(range: ClosedRange<Int>) {
        grid.printSequence(range: range)
    }
}

extension ChainComplex where GridDim == _2 {
    public func printTable(indices1: [Int], indices2: [Int]) {
        grid.printTable(indices1: indices1, indices2: indices2)
    }
    
    public func printTable(range1: ClosedRange<Int>, range2: ClosedRange<Int>) {
        grid.printTable(range1: range1, range2: range2)
    }
}

extension ChainComplex {
    public var dual: ChainComplex<GridDim, Dual<BaseModule>> {
        return ChainComplex<GridDim, Dual<BaseModule>>(grid: grid.dual, differential: differential.dual)
    }
}
