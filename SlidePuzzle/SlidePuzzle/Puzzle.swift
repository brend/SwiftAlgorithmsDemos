//
//  Puzzle.swift
//  SlidePuzzle
//
//  Created by Philipp Brendel on 31.01.20.
//  Copyright © 2020 Entenwolf Software. All rights reserved.
//

import Foundation
import SwiftAlgorithms

final class Puzzle<Piece> where Piece: Comparable & Equatable & Hashable {
    enum Stone: Comparable & Equatable & Hashable {
        case blank, piece(Piece)

        static func < (lhs: Puzzle<Piece>.Stone, rhs: Puzzle<Piece>.Stone) -> Bool {
            switch (lhs, rhs) {
            case (.piece(let p1), .piece(let p2)):
                return p1 < p2
            case (.blank, .piece):
                return false
            case (.piece, .blank):
                return true
            case (.blank, .blank):
                fatalError()
            }
        }
    }
    
    let stones: [Stone]
    let n: Int
    
    var predecessor: Puzzle?
    
    init(n: Int, pieces: [Piece], blank: Int? = nil) {
        assert(pieces.count == n * n - 1)
        
        let blank = blank ?? (n * n - 1)
        var stones = pieces.map {Stone.piece($0)}
        
        stones.insert(.blank, at: blank)
        
        self.n = n
        self.stones = stones
        
        assert(stones.count == n * n)
    }
    
    required init(n: Int, stones: [Stone], moveBlankBy offset: Int? = nil) {
        var stones = stones
        
        if let offset = offset {
            let blankIndex = stones.firstIndex(of: .blank)!
            
            stones.swapAt(blankIndex, blankIndex + offset)
        }
        
        self.stones = stones
        self.n = n
    }
    
    var blankIndex: Int {
        stones.firstIndex(of: .blank)!
    }
    
    var canMoveLeft: Bool {
        blankIndex % n != 0
    }
    
    var canMoveRight: Bool {
        (blankIndex + 1) % n != 0
    }
    
    var canMoveUp: Bool {
        blankIndex >= n
    }
    
    var canMoveDown: Bool {
        (blankIndex + n) < n * n
    }
    
    func moveUp() -> Self? {
        guard canMoveUp else { return nil }
        
        return .init(n: n, stones: stones, moveBlankBy: -n)
    }
    
    func moveDown() -> Self? {
        guard canMoveDown else { return nil }
        
        return .init(n: n, stones: stones, moveBlankBy: n)
    }
    
    func moveLeft() -> Self? {
        guard canMoveLeft else { return nil }
        
        return .init(n: n, stones: stones, moveBlankBy: -1)
    }
    
    func moveRight() -> Self? {
        guard canMoveRight else { return nil }
        
        return .init(n: n, stones: stones, moveBlankBy: 1)
    }
    
    func solvedForm() -> Puzzle {
        Puzzle(n: n, stones: stones.sorted())
    }
    
    func step(to successor: Puzzle) -> Int {
        successor.blankIndex
    }
}

extension Puzzle: AStarNode {
    
    func getPredecessor() -> Puzzle? {
        predecessor
    }
    
    func setPredecessor(_ predecessor: Puzzle?) {
        self.predecessor = predecessor
    }
    
    func successors() -> [Puzzle] {
        var succs: [Puzzle] = []
        
        if predecessor?.blankIndex != up(blankIndex),
            let up = moveUp() {
            succs.append(up)
        }
        
        if predecessor?.blankIndex != down(blankIndex),
            let down = moveDown() {
            succs.append(down)
        }
        
        if predecessor?.blankIndex != left(blankIndex),
            let left = moveLeft() {
            succs.append(left)
        }
        
        if predecessor?.blankIndex != right(blankIndex),
            let right = moveRight() {
            succs.append(right)
        }
        
        return succs
    }
    
    func up(_ index: Int) -> Int {
        index - n
    }
    
    func down(_ index: Int) -> Int {
        index + n
    }
    
    func left(_ index: Int) -> Int {
        index - 1
    }
    
    func right(_ index: Int) -> Int {
        index + 1
    }
    
    func cost(to successor: Puzzle) -> Float {
        1
    }
    
    func h() -> Float {
        let h = Float(manhattanDistanceToSolution())
        
        print("h = \(h)")
        
        return h
    }
    
    var pieces: [Piece] {
        var pcs: [Piece] = []
        
        for stone in stones {
            switch stone {
            case .piece(let p):
                pcs.append(p)
            default:
                break
            }
        }
        
        return pcs
    }
    
//    func numberOfSwapsToSolve() -> Int {
//        let solution = stones.sorted()
//
//        return stones
//            .enumerated()
//            .reduce(0) { (result, e) in result + (e.element == solution[e.offset] ? 0 : 1) }
//    }
    
    func manhattanDistanceToSolution() -> Int {
        let solution = stones.sorted()
        var distance = 0
        
        for (i, s) in stones.enumerated() {
            let j = solution.firstIndex(of: s)!
            
            distance += abs(j / n - i / n) + abs(j % n - i % n)
        }
        
        return distance
    }
}

extension Puzzle: Equatable where Piece: Equatable {
    static func == (lhs: Puzzle<Piece>, rhs: Puzzle<Piece>) -> Bool {
        lhs.stones == rhs.stones
    }
}

extension Puzzle: Hashable where Piece: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(stones)
    }
}
