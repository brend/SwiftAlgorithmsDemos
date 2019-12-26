//
//  SquareView.swift
//  SquarePathfinder
//
//  Created by Philipp Brendel on 22.12.19.
//  Copyright © 2019 Entenwolf Software. All rights reserved.
//

import Cocoa
import SwiftAlgorithms

let width = 20
let height = 20
var squares: [Int] = Array(repeating: 0, count: width * height)

var origin = SquareNode(x: 0, y: 0)
var goal = SquareNode(x: width - 1, y: height - 1)

let search = AStar<SquareNode>()

class SquareView: NSView {
    
    var squareWidth: CGFloat { self.frame.size.width / CGFloat(width) }
    var squareHeight: CGFloat { self.frame.size.height / CGFloat(height) }
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        NSBezierPath.fill(dirtyRect)
        paintBackground()
        paintGrid()
        
        if let path = computePath() {
            NSColor.white.setStroke()
            path.lineWidth = 3
            path.stroke()
            NSColor.blue.setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }
    
    func paintBackground() {
        for x in 0..<width {
            for y in 0..<height {
                var color: NSColor? = nil
                
                if SquareNode(x: x, y: y) == origin {
                    color = .green
                }
                
                if SquareNode(x: x, y: y) == goal {
                    color = .yellow
                }
                
                switch squares[y * width + x] {
                case 1:
                    color = .red
                default:
                    break
                }
                
                if let color = color {
                    let square = NSRect(x: CGFloat(x) * squareWidth,
                                        y: CGFloat(y) * squareHeight,
                                        width: squareWidth,
                                        height: squareHeight)
                    
                    color.setFill()
                    NSBezierPath.fill(square)
                }
            }
        }
    }
    
    func paintGrid() {
        NSColor.white.setStroke()
        
        let squareWidth = self.squareWidth
        let squareHeight = self.squareHeight
        
        for x in 1..<width {
            NSBezierPath.strokeLine(from: NSPoint(x: CGFloat(x) * squareWidth, y: 0),
                                    to: NSPoint(x: CGFloat(x) * squareWidth, y: self.frame.height))
        }
        
        for y in 1..<height {
            NSBezierPath.strokeLine(from: NSPoint(x: 0, y: CGFloat(y) * squareHeight),
                                    to: NSPoint(x: self.frame.width, y: CGFloat(y) * squareHeight))
        }
    }
    
    func computePath() -> NSBezierPath? {
        let path = search.searchPath(from: origin, to: goal)
        
        if path.isEmpty {
            return nil
        }
        
        let bp = NSBezierPath()
        
        bp.move(to: center(of: path[0]))
        
        for node in path {
            bp.line(to: center(of: node))
        }
        
        return bp
    }
    
    func center(of node: SquareNode) -> CGPoint {
        CGPoint(x: (CGFloat(node.x) + 0.5) * self.frame.size.width / CGFloat(width),
                y: (CGFloat(node.y) + 0.5) * self.frame.size.height / CGFloat(height))
    }
    
    func coordinates(of point: CGPoint) -> (Int, Int) {
        (Int(point.x / self.frame.size.width * CGFloat(width)),
         (Int(point.y / self.frame.size.height * CGFloat(height))))
    }
    
    var dragNum = 0
    var dragSquare: (Int, Int)? = nil
    
    override func mouseDown(with event: NSEvent) {
        let point = event.locationInWindow
        let (x, y) = coordinates(of: point)
        
        if event.modifierFlags.contains(.control) {
            origin = SquareNode(x: x, y: y)
        } else if event.modifierFlags.contains(.command) {
            goal = SquareNode(x: x, y: y)
        } else {
            dragNum = squares[x + y * width] == 0 ? 1 : 0
            squares[x + y * width] = dragNum
            dragSquare = (x, y)
        }
        
        setNeedsDisplay(self.frame)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let point = event.locationInWindow
        let (x, y) = coordinates(of: point)
        
        if (x, y) != (dragSquare ?? (-1, -1)) {
            squares[x + y * width] = dragNum
            dragSquare = (x, y)
        }
        
        setNeedsDisplay(self.frame)
    }
}
