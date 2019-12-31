//
//  GameScene.swift
//  TreeDrawer
//
//  Created by Philipp Brendel on 30.12.19.
//  Copyright © 2019 Entenwolf Software. All rights reserved.
//

import SpriteKit
import GameplayKit
import SwiftAlgorithms

class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    
    var nodeProto: SKShapeNode!
    
    var graph: AdjacencyListGraph<String, Int>!
        
    var tree: SimpleTree<String, Int>!
    
    func setup() {
        var graph = AdjacencyListGraph<String, Int>()
        let d = graph.addNode(labelled: "D")
        let a = graph.addNode(labelled: "A")
        let b = graph.addNode(labelled: "B")
        let c = graph.addNode(labelled: "C")
        let e = graph.addNode(labelled: "E")
        let f = graph.addNode(labelled: "F")
        let g = graph.addNode(labelled: "G")
        
        graph.addEdge(between: a, and: b, labelled: 7)
        graph.addEdge(between: a, and: d, labelled: 5)
        graph.addEdge(between: b, and: c, labelled: 8)
        graph.addEdge(between: b, and: d, labelled: 9)
        graph.addEdge(between: b, and: e, labelled: 7)
        graph.addEdge(between: c, and: e, labelled: 5)
        graph.addEdge(between: d, and: e, labelled: 15)
        graph.addEdge(between: d, and: f, labelled: 6)
        graph.addEdge(between: e, and: f, labelled: 8)
        graph.addEdge(between: e, and: g, labelled: 9)
        graph.addEdge(between: f, and: g, labelled: 11)
        
        self.graph = graph
        
        let tree = minimumSpanningTree(graph: graph)
        
        self.tree = tree
    }
    
    override func sceneDidLoad() {
        
        setup()
        
        self.lastUpdateTime = 0
        
        setupNodeProto()
        
        drawGraph()
        
        run(.sequence([
            .wait(forDuration: 3),
            .run({ self.colorizeEdges() }),
            .wait(forDuration: 3),
            .run({ self.fadeEdges() }),
            .wait(forDuration: 0.5),
            .run({ self.drawTree() })
        ]))
    }
    
    var edges: [SKNode] {
        children.filter {$0.name?.hasPrefix("edge_") ?? false}
    }
    
    var treeEdges: [SKNode] {
        edges.filter {treeNodes(connectedBy: $0) != nil}
    }
    
    var edgesNotInTree: [SKNode] {
        let intree = treeEdges
        
        return edges.filter {!intree.contains($0)}
    }
    
    func colorizeEdges() {
        let duration = 0.3
        
        for e in edgesNotInTree {
            if let n = e as? LineNode {
                n.strokeColor = .darkGray
                
                n.run(.customAction(withDuration: duration) {
                    node, elapsed in
                    
                    let gray = 1 - 2 * elapsed
                    let color = NSColor(deviceRed: gray, green: gray, blue: gray, alpha: 1)
                    
                    n.strokeColor = color
                    n.edgeLabelNode.fontColor = color
                })
            }
        }
        
        // colorize root node
        let root = childNode(withName: tree.root!)! as! SKShapeNode
        
        root.fillColor = .init(deviceRed: 0, green: 0, blue: 0.8, alpha: 1)
    }
    
    func fadeEdges() {
        for e in edgesNotInTree {
            e.run(.fadeAlpha(to: 0, duration: 0.3)) {
                print("removing child \(e.name!)")
                e.removeFromParent()
            }
        }
    }
        
    func treeNodes(connectedBy edge: SKNode) -> (label1: String, label2: String)? {
        let components = edge.name!.split(separator: "_")
        
        guard components.count == 3 else { return nil }
        
        let (label1, label2) = (String(components[1]), String(components[2]))
        
        if tree.adjacent(label1, label2) {
            return (label1, label2)
        } else {
            return nil
        }
    }
    
    func setupNodeProto() {
        self.nodeProto = self.childNode(withName: "nodeProto") as? SKShapeNode
        
        self.nodeProto.path = CGPath(ellipseIn: CGRect(origin: .init(x: -nodeProto.frame.size.width/2, y: -nodeProto.frame.size.height/2), size: nodeProto.frame.size), transform: nil)
        
        nodeProto.isHidden = true
        
        setLabel(on: nodeProto, to: "PROTO")
    }
    
    func addTreeNode(label: String) -> SKNode {
        let n = nodeProto.copy() as! SKNode
        
        addChild(n)

        n.name = label
        n.isHidden = false
        n.position = CGPoint(x: n.position.x + 100, y: n.position.y - 100)
        setLabel(on: n, to: label)
        
        return n
    }
    
    func drawTree() {
        let yOffset = CGFloat(100)
        var y = CGFloat(200)
        
        
        removeChildren(in: edges)
        for n in graph.nodes {
            let label = graph.label(of: n)
            
            if let p = tree.parent(of: label) {
                let line = drawLine(from: childNode(withName: label)!, to: childNode(withName: p)!)
                let parentNode = graph.node(labelled: p)!
                
                line.edgeLabel = "\(graph.label(from: n, to: parentNode)!)"
            }
        }
        
        for level in tree.levels() {
            for (i, (label, _)) in level.enumerated() {
                let n = childNode(withName: label)!
                let lc = CGFloat(level.count)
                let w = self.size.width
                let fi = CGFloat(i)
                let p = CGPoint(x: fi * w / lc - (lc - 1) * w / 2 / lc, y: y)
                
                n.run(.move(to: p, duration: 1))
                
                n.run(.group([
                    .move(to: p, duration: 1),
                    .customAction(withDuration: 1) {
                        node, elapsed in
                        
                        if let m = self.treeParent(of: node) {
                            if let e = self.edge(from: node, to: m) {
                                e.p1 = node.position
                                e.p2 = m.position
                            }
                        }
                    }
                ]))
            }
            
            y -= yOffset
        }
    }
    
    func edge(from n: SKNode, to m: SKNode) -> LineNode? {
        let edgeName = "edge_\(n.name!)_\(m.name!)"
        
        return childNode(withName: edgeName) as? LineNode
    }
    
    func removeEdge(from n: SKNode, to m: SKNode) {
        edge(from: n, to: m)?.removeFromParent()
    }
    
    func treeParent(of node: SKNode) -> SKNode? {
        if let parentLabel = tree.parent(of: node.name!) {
            return childNode(withName: parentLabel)
        } else {
            return nil
        }
    }
    
    func drawGraph() {
        let grect = self.frame.insetBy(dx: 300, dy: 300)
        var i = CGFloat(0)
        let r = min(grect.size.width, grect.size.height)
        
        for n in graph.nodes {
            let node = addTreeNode(label: graph.label(of: n))
            let a = CGFloat.pi * 2 * i / CGFloat(graph.nodes.count)
            let position = CGPoint(x: r * cos(a),
                                   y: r * -sin(a))
            
            setLabel(on: node, to: graph.label(of: n))
            
            // node.position = CGPoint(x: CGFloat.random(in: grect.minX..<grect.maxX), y: CGFloat.random(in: grect.minY..<grect.maxY))
            node.position = position
            
            i += 1
        }
        
        for n in graph.nodes {
            for m in graph.neighbors(of: n) {
                let line =
                    drawLine(from: childNode(withName: graph.label(of: n))!,
                             to: childNode(withName: graph.label(of: m))!)
                
                line.edgeLabel = "\(graph.label(from: n, to: m)!)"
            }
        }
    }
    
    func setLabel(on node: SKNode, to text: String) {
        if let labelNode = node.childNode(withName: "label") as? SKLabelNode {
            labelNode.text = text
        }
    }
    
    @discardableResult func drawLine(from n: SKNode, to m: SKNode) -> LineNode {
        let line = LineNode(label1: n.name!, label2: m.name!)
        
        line.p1 = n.position
        line.p2 = m.position
                
        print("adding child \(line.name!)")
        
        addChild(line)
        
        return line
    }
    
    func touchDown(atPoint pos : CGPoint) {
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
}
