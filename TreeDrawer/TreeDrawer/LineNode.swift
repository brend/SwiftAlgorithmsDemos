//
//  LineNode.swift
//  TreeDrawer
//
//  Created by Philipp Brendel on 31.12.19.
//  Copyright © 2019 Entenwolf Software. All rights reserved.
//

import SpriteKit

class LineNode: SKShapeNode {
    
    init(label1: String, label2: String) {
        self.label1 = label1
        self.label2 = label2
        super.init()
        name = "edge_\(label1)_\(label2)"
        
        self.edgeLabelNode = SKLabelNode(text: nil)
        
        addChild(edgeLabelNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.label1 = ""
        self.label2 = ""
        fatalError("init(coder:) has not been implemented")
    }
    
    var p1 = CGPoint.zero {
        didSet {
            constructPath()
        }
    }
    
    var p2 = CGPoint.zero {
        didSet {
            constructPath()
        }
    }
    
    var edgeLabelNode: SKLabelNode!
    
    var label1: String
    
    var label2: String
    
    var edgeLabel = "" {
        didSet {
            edgeLabelNode?.text = edgeLabel
        }
    }
    
    func constructPath() {
        let pathToDraw = CGMutablePath()
        
        pathToDraw.move(to: p1)
        pathToDraw.addLine(to: p2)
        
        path = pathToDraw
        lineWidth = 2
        strokeColor = SKColor.white
        zPosition = -1
        
        edgeLabelNode.position = CGPoint(x: p1.x + (p2.x - p1.x) / 2,
                                         y: p1.y + (p2.y - p1.y) / 2)
    }
}
