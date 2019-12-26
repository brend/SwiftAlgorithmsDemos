//
//  Node.swift
//  Astardude
//
//  Created by Philipp Brendel on 21.12.19.
//  Copyright © 2019 Entenwolf Software. All rights reserved.
//

import Foundation
import SwiftAlgorithms

final class SquareNode: AStarNode, Hashable, Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    var debugDescription: String { "\(description)" }
    
    var description: String { "(\(x), \(y))" }
    
    var x: Int
    var y: Int
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    static func == (lhs: SquareNode, rhs: SquareNode) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
    var predecessor: SquareNode?
    
    func successors() -> [SquareNode] {
        var successors: [SquareNode] = []
        
        for successor in [
                SquareNode(x: x - 1, y: y),
                SquareNode(x: x + 1, y: y),
                SquareNode(x: x,     y: y - 1),
                SquareNode(x: x,     y: y + 1),
            ] {
            if successor.x < 0 || successor.x >= width
                || successor.y < 0 || successor.y >= height
                || squares[successor.x + successor.y * width] == 1 {
                continue
            }
            
            successors.append(successor)
        }
        
        return successors
    }
    
    func cost(to successor: SquareNode) -> Float {
        return 1
    }
    
    func getPredecessor() -> SquareNode? {
        predecessor
    }
    
    func setPredecessor(_ predecessor: SquareNode?) {
        self.predecessor = predecessor
    }
    
    func h() -> Float {
        Float(abs(goal.x - x) + abs(goal.y - y))
    }
}


