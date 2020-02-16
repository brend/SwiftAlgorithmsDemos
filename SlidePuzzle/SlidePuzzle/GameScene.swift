//
//  GameScene.swift
//  SlidePuzzle
//
//  Created by Philipp Brendel on 31.01.20.
//  Copyright © 2020 Entenwolf Software. All rights reserved.
//

import SpriteKit
import GameplayKit
import SwiftAlgorithms

class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    
    var tiles: [SKSpriteNode] = []
    var blank: SKSpriteNode!
    
    var n = 3
    
    var swapCountLabel: SKLabelNode!
    var solutionSwapLabel: SKLabelNode!
    var solvingIndicator: SKNode!
    var scramblingIndicator: SKNode!

    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        
        for i in 0..<8 {
            let name = "\(i + 1)"
            
            tiles.append(childNode(withName: name) as! SKSpriteNode)
        }
        
        blank = childNode(withName: "Blank") as? SKSpriteNode
        blank.isHidden = true
        tiles.append(blank)
        
        swapCountLabel = childNode(withName: "swapCountLabel") as? SKLabelNode
        solutionSwapLabel = childNode(withName: "solutionSwapLabel") as? SKLabelNode
        solvingIndicator = childNode(withName: "solvingIndicator")
        scramblingIndicator = childNode(withName: "scramblingIndicator")
    }
    
    var blankIndex: Int { tiles.firstIndex(of: blank)! }
    
    func swapBlankWithTile(at tileIndex: Int) {
        tiles.swapAt(blankIndex, tileIndex)
    }
    
    func swapBlankAndAnimate(with tileIndex: Int) {
        let tile = tiles[tileIndex]
        
        swapBlankWithTile(at: tileIndex)
        animateSwapping(blank, and: tile)
    }
    
    func animateSwapping(_ tile1: SKNode, and tile2: SKNode) {
        let tilePosition = tile2.position

        tile2.run(.move(to: tile1.position, duration: 0.2))
        tile1.run(.move(to: tilePosition, duration: 0.2))
    }
    
    func animateSwapping(_ tile: SKNode, _ duration: TimeInterval = 0.1) -> SKAction {
        return .sequence([
            .run {
                let tilePosition = tile.position

                tile.run(.move(to: self.blank.position, duration: duration / 2))
                self.blank.run(.move(to: tilePosition, duration: duration / 2))
            },
            .wait(forDuration: duration)
        ])
    }
    
    var canMoveUp: Bool { blankIndex >= n }
    
    var canMoveDown: Bool { blankIndex + n < tiles.count }
    
    var canMoveLeft: Bool { blankIndex % n != 0 }
    
    var canMoveRight: Bool { (blankIndex + 1) % n != 0 }
    
    var animationIsRunning: Bool { tiles.first {$0.hasActions()} != nil }
    
    func moveUp() {
        guard canMoveUp && !animationIsRunning else { return }
        
        swapBlankAndAnimate(with: blankIndex - n)
        increaseSwapCounter()
    }
    
    func moveDown() {
        guard canMoveDown && !animationIsRunning else { return }
        
        swapBlankAndAnimate(with: blankIndex + n)
        increaseSwapCounter()
    }
    
    func moveLeft() {
        guard canMoveLeft && !animationIsRunning else { return }
        
        swapBlankAndAnimate(with: blankIndex - 1)
        increaseSwapCounter()
    }
    
    func moveRight() {
        guard canMoveRight && !animationIsRunning else { return }
        
        swapBlankAndAnimate(with: blankIndex + 1)
        increaseSwapCounter()
    }
    
    func touchDown(atPoint pos : CGPoint) {
        moveUp()
    }
    
    let rand = GKARC4RandomSource()
    
    func scramble() {
        var actions: [SKAction] = [.run {self.scramblingIndicator.isHidden = false}]
        var iterations = 100
        var lastMove = -1
        
        while iterations > 0 {
            let r = rand.nextInt(upperBound: 4)
                        
            if r == 0 && lastMove == 1
            || r == 1 && lastMove == 0
            || r == 2 && lastMove == 3
            || r == 3 && lastMove == 2
            || r == 0 && !canMoveUp
            || r == 1 && !canMoveDown
            || r == 2 && !canMoveLeft
            || r == 3 && !canMoveRight
            {
                continue
            }
            
            let tileIndex: Int
            
            switch r {
            case 0:
                tileIndex = blankIndex - n
            case 1:
                tileIndex = blankIndex + n
            case 2:
                tileIndex = blankIndex - 1
            case 3:
                tileIndex = blankIndex + 1
            default:
                continue
            }
            
            let tile = tiles[tileIndex]
            
            actions.append(animateSwapping(tile))
            swapBlankWithTile(at: tileIndex)
            
            increaseSwapCounter()
            
            lastMove = r
            
            iterations -= 1
        }
        
        actions.append(.run {self.scramblingIndicator.isHidden = true})
        
        self.run(.sequence(actions))
    }
    
    var swapCount = 0
    
    func increaseSwapCounter() {
        swapCount += 1
        
        swapCountLabel.text = "Number of swaps: \(swapCount)"
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {
    }
    
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.touchMoved(toPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        self.touchUp(atPoint: event.location(in: self))
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123:
            moveLeft()
        case 124:
            moveRight()
        case 125:
            moveDown()
        case 126:
            moveUp()
        case 36:
            scramble()
        case 49:
            solve()
        default:
            print(event.keyCode)
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
    
    func puzzle() -> Puzzle<String> {
        let pieces = tiles.map {$0.name!}.filter {$0 != "Blank"}
        let n = Int(sqrt(Double(tiles.count)))
        let blankIndex = tiles.firstIndex {$0.name == "Blank"}!
        
        return Puzzle<String>(n: n, pieces: pieces, blank: blankIndex)
    }
    
    func solve() {
        solvingIndicator.isHidden = false
        
        let puzzle = self.puzzle()
        let solvedPuzzle = puzzle.solvedForm()
        let path = AStar().searchPath(from: puzzle, to: solvedPuzzle)
        
        solutionSwapLabel.text = "Solution swaps: \(path.count)"
        
        animate(path)
    }
    
    func animate(_ path: [Puzzle<String>]) {
        var actions: [SKAction] = [.run {self.solvingIndicator.isHidden = false}]
        
        for puzzle in path {
            if let predecessor = puzzle.predecessor {
                let swapIndex = predecessor.step(to: puzzle)
                let tile = tiles[swapIndex]
                
                swapBlankWithTile(at: swapIndex)
                actions.append(animateSwapping(tile, 0.5))
            }
        }
        
        actions.append(.run {self.solvingIndicator.isHidden = true})
        
        run(.sequence(actions))
    }
}
