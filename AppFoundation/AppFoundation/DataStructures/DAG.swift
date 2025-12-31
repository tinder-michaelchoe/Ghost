//
//  DAG.swift
//  AppFoundation
//

import Foundation
import CoreContracts

/// A simple directed acyclic graph using adjacency list representation
/// Generic over node identifiers (must be Hashable)
/// Conforms to DirectedAcyclicGraph protocol from CoreContracts
public struct DAG<Node: Hashable>: DirectedAcyclicGraph {
    /// Adjacency list: node -> [nodes it points to]
    private var edges: [Node: [Node]] = [:]
    
    /// All nodes in the graph
    private var nodes: Set<Node> = []
    
    public init() {}
    
    /// Add a node to the graph
    public mutating func addNode(_ node: Node) {
        nodes.insert(node)
        if edges[node] == nil {
            edges[node] = []
        }
    }
    
    /// Add a directed edge from source to destination
    /// Returns false if the edge would create a cycle
    @discardableResult
    public mutating func addEdge(from source: Node, to destination: Node) -> Bool {
        addNode(source)
        addNode(destination)
        
        // Check if adding this edge would create a cycle
        if wouldCreateCycle(from: source, to: destination) {
            return false
        }
        
        edges[source, default: []].append(destination)
        return true
    }
    
    /// Check if adding an edge would create a cycle
    private func wouldCreateCycle(from source: Node, to destination: Node) -> Bool {
        // If destination can reach source, adding source->destination creates a cycle
        return canReach(from: destination, to: source)
    }
    
    /// Check if there's a path from source to target
    public func canReach(from source: Node, to target: Node) -> Bool {
        var visited: Set<Node> = []
        return dfs(from: source, target: target, visited: &visited)
    }
    
    private func dfs(from current: Node, target: Node, visited: inout Set<Node>) -> Bool {
        if current == target { return true }
        if visited.contains(current) { return false }
        
        visited.insert(current)
        
        for neighbor in edges[current] ?? [] {
            if dfs(from: neighbor, target: target, visited: &visited) {
                return true
            }
        }
        return false
    }
    
    /// Get direct children (nodes this node points to)
    public func children(of node: Node) -> [Node] {
        edges[node] ?? []
    }
    
    /// Get all ancestors of a node in topological order (deepest first)
    /// This is useful for style inheritance where you want to apply base styles first
    public func ancestors(of node: Node) -> [Node] {
        var result: [Node] = []
        var visited: Set<Node> = []
        collectAncestors(of: node, into: &result, visited: &visited)
        return result
    }
    
    private func collectAncestors(of node: Node, into result: inout [Node], visited: inout Set<Node>) {
        guard !visited.contains(node) else { return }
        visited.insert(node)
        
        // First recurse to parents (children in our edge direction represent "inherits from")
        for parent in edges[node] ?? [] {
            collectAncestors(of: parent, into: &result, visited: &visited)
        }
        
        // Then add this node (so parents come before children in the result)
        result.append(node)
    }
    
    /// Topological sort of all nodes
    /// Returns nil if the graph has a cycle
    public func topologicalSort() -> [Node]? {
        var visited: Set<Node> = []
        var result: [Node] = []
        
        for node in nodes {
            if !topologicalDFS(node: node, visited: &visited, result: &result) {
                return nil
            }
        }
        
        return result.reversed()
    }
    
    private func topologicalDFS(node: Node, visited: inout Set<Node>, result: inout [Node]) -> Bool {
        if visited.contains(node) { return true }
        visited.insert(node)
        
        for neighbor in edges[node] ?? [] {
            if !topologicalDFS(node: neighbor, visited: &visited, result: &result) {
                return false
            }
        }
        
        result.append(node)
        return true
    }
}





