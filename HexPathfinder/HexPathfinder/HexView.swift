//
//  HexView.swift
//  HexPathfinder
//
//  Created by Philipp Brendel on 23.12.19.
//  Copyright © 2019 Entenwolf Software. All rights reserved.
//

import Cocoa
import SwiftAlgorithms

let width = 8
let height = 8
var hexes: [Int] = Array(repeating: 0, count: width * height)
let widthf = CGFloat(width)
let heightf = CGFloat(height)

var origin = HexNode(x: 0, y: 0)
var goal = HexNode(x: 3, y: 3)

func coordsInvalid(x: Int, y: Int) -> Bool {
    x < 0 || x >= width || y < 0 || y >= height
}

class HexView: NSView {
        
    let radius = CGFloat(30)
    
    let search = AStar<HexNode>()
    
    func center(x: Int, y: Int) -> CGPoint {
        let xcoord = CGFloat(x) * 1.5 * radius
        let ycoord = x.isMultiple(of: 2)
            ? CGFloat(y) * 1.75 * radius
            : CGFloat(y) * 1.75 * radius + 1 * radius
        let gridOffset = self.gridOffset
        let center = CGPoint(x: radius + xcoord + gridOffset.width,
                             y: radius + ycoord + gridOffset.height)
        
        return center
    }
    
    var gridOffset: CGSize {
        CGSize(width: (self.frame.width - CGFloat(width) * 1.5 * radius) / 2,
               height: (self.frame.height - (CGFloat(height) * 1.75 * radius + 1 * radius)) / 2)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        NSBezierPath.fill(dirtyRect)
                        
        for x in 0..<width {
            for y in 0..<height {
                let center = self.center(x: x, y: y)
                let fillColor = hexes[x + y * width] == 0 ? NSColor.black : NSColor.red
                
                drawHex(center: center, radius: radius, fillColor: fillColor, strokeColor: .white)
                
                if origin.x == x && origin.y == y {
                    drawIndicator(center, radius, .yellow)
                }
                
                if goal.x == x && goal.y == y {
                    drawIndicator(center, radius, .green)
                }
            }
        }
        
        if let path = computePath() {
            NSColor.white.setStroke()
            path.lineWidth = 3
            path.stroke()
            NSColor.blue.setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }
    
    func computePath() -> NSBezierPath? {
        let path = search.searchPath(from: origin, to: goal)
        
        if path.isEmpty {
            return nil
        }
        
        let bp = NSBezierPath()
        bp.move(to: center(x: path[0].x, y: path[0].y))
        
        print("path:")
        
        for node in path {
            print("(\(node.x), \(node.y))")
            bp.line(to: center(x: node.x, y: node.y))
        }
        
        return bp
    }
    
    func drawHex(center: CGPoint, radius: CGFloat, fillColor: NSColor, strokeColor: NSColor) {
        let path = NSBezierPath()
        
        for i in 0...6 {
            let angle = CGFloat(i) * 2 * CGFloat.pi / 6
            let x = cos(angle) * radius + center.x
            let y = -sin(angle) * radius + center.y
            
            if i == 0 {
                path.move(to: NSPoint(x: x, y: y))
            } else {
                path.line(to: NSPoint(x: x, y: y))
            }
        }
        
        fillColor.setFill()
        path.fill()
        
        strokeColor.setStroke()
        path.stroke()
    }
    
    func drawIndicator(_ center: CGPoint, _ radius: CGFloat, _ color: NSColor) {
        color.setFill()
        
        NSBezierPath(ovalIn:
            NSRect(origin: CGPoint(x: center.x - radius * 0.3/2, y: center.y - radius * 0.3/2),
                   size: .init(width: radius * 0.3, height: radius * 0.3)))
        .fill()
    }
    
    var dragNum = 0
    var dragHex: (Int, Int)?
    
    override func mouseDown(with event: NSEvent) {
        let location = event.locationInWindow
        let (x, y) = coordinates(of: location)
        
        if event.modifierFlags.contains(.control) {
            origin = HexNode(x: x, y: y)
        } else if event.modifierFlags.contains(.command) {
            goal = HexNode(x: x, y: y)
        } else {
            dragNum = hexes[x + y * width] == 0 ? 1 : 0
            hexes[x + y * width] = dragNum
            dragHex = (x, y)
        }
        
        setNeedsDisplay(self.frame)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let point = event.locationInWindow
        let (x, y) = coordinates(of: point)
        
        if (x, y) != (dragHex ?? (-1, -1))
            && !coordsInvalid(x: x, y: y) {
            hexes[x + y * width] = dragNum
            dragHex = (x, y)
        }
        
        setNeedsDisplay(self.frame)
    }
    
    func coordinates(of location: NSPoint) -> (Int, Int) {
        for x in 0..<width {
            for y in 0..<height {
                let center = self.center(x: x, y: y)
                
                if distance(location, center) < radius {
                    return (x, y)
                }
            }
        }
        
        return (-1, -1)
    }
    
    func distance(_ p: NSPoint, _ q: NSPoint) -> CGFloat {
        let dx = q.x - p.x
        let dy = q.y - p.y
        
        return sqrt(dx * dx + dy * dy)
    }
}
