//
//  Node.swift
//  Astardude
//
//  Created by Philipp Brendel on 21.12.19.
//  Copyright © 2019 Entenwolf Software. All rights reserved.
//

import Foundation
import SwiftAlgorithms

final class HexNode: AStarNode, Hashable, Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    
    var debugDescription: String { "\(description)" }
    
    var description: String { "(\(x), \(y))" }
    
    var x: Int
    var y: Int
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    static func == (lhs: HexNode, rhs: HexNode) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
    var predecessor: HexNode?
    
    func successors() -> [HexNode] {
        var successors: [HexNode] =
            [
                HexNode(x: x, y: y + 1),
                HexNode(x: x, y: y - 1),
                
                HexNode(x: x + 1, y: y),
                HexNode(x: x - 1, y: y)
            ]
        
        if !x.isMultiple(of: 2) {
            successors.append(HexNode(x: x - 1, y: y + 1))
            successors.append(HexNode(x: x + 1, y: y + 1))
        } else {
            successors.append(HexNode(x: x - 1, y: y - 1))
            successors.append(HexNode(x: x + 1, y: y - 1))
        }
    
        successors.removeAll { coordsInvalid(x: $0.x, y: $0.y) || hexes[$0.x + $0.y * width] != 0 }
        
        return successors
    }
        
    func cost(to successor: HexNode) -> Float {
        return 1
    }
    
    func getPredecessor() -> HexNode? {
        predecessor
    }
    
    func setPredecessor(_ predecessor: HexNode?) {
        self.predecessor = predecessor
    }
    
    func h() -> Float {
        Float(abs(goal.x - x) + abs(goal.y - y))
    }
}
