//
//  DirectedAcyclicGraph.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/25/25.
//

public protocol DirectedAcyclicGraph {
    associatedtype Node: Hashable
    
    /// Initialize an empty graph
    init()
    
    /// Add a node to the graph
    mutating func addNode(_ node: Node)
    
    /// Add a directed edge from source to destination
    /// Returns false if the edge would create a cycle
    @discardableResult
    mutating func addEdge(from source: Node, to destination: Node) -> Bool
    
    /// Check if there's a path from source to target
    func canReach(from source: Node, to target: Node) -> Bool
    
    /// Get direct children (nodes this node points to)
    func children(of node: Node) -> [Node]
    
    /// Get all ancestors of a node in topological order (deepest first)
    /// This is useful for style inheritance where you want to apply base styles first
    func ancestors(of node: Node) -> [Node]
    
    /// Topological sort of all nodes
    /// Returns nil if the graph has a cycle
    func topologicalSort() -> [Node]?
}
