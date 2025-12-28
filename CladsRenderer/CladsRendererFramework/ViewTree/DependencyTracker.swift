//
//  DependencyTracker.swift
//  CladsRendererFramework
//
//  Tracks dependencies between view nodes and state paths.
//

import Foundation

// MARK: - Dependency Tracker

/// Collects state path dependencies during view tree resolution
@MainActor
public class DependencyTracker {
    /// The current node being tracked (set during resolution)
    private var currentNode: ViewNode?

    /// Paths accessed during current node's resolution
    private var accessedPaths: Set<String> = []

    /// Paths written by current node (e.g., textfield bindings)
    private var writtenPaths: Set<String> = []

    /// Whether we're currently tracking
    private var isTracking: Bool = false

    public init() {}

    // MARK: - Tracking API

    /// Begin tracking dependencies for a node
    public func beginTracking(for node: ViewNode) {
        currentNode = node
        accessedPaths = []
        writtenPaths = []
        isTracking = true
    }

    /// End tracking and apply collected dependencies to the node
    public func endTracking() {
        guard let node = currentNode, isTracking else { return }

        node.readPaths = accessedPaths
        node.writePaths = writtenPaths

        currentNode = nil
        accessedPaths = []
        writtenPaths = []
        isTracking = false
    }

    /// Record a state path read
    public func recordRead(_ path: String) {
        guard isTracking else { return }
        accessedPaths.insert(path)
    }

    /// Record a state path write (for bindings)
    public func recordWrite(_ path: String) {
        guard isTracking else { return }
        writtenPaths.insert(path)
        // Writes also imply reads
        accessedPaths.insert(path)
    }

    /// Record a local state read
    public func recordLocalRead(_ path: String) {
        guard isTracking else { return }
        accessedPaths.insert("local.\(path)")
    }

    /// Record a local state write
    public func recordLocalWrite(_ path: String) {
        guard isTracking else { return }
        let fullPath = "local.\(path)"
        writtenPaths.insert(fullPath)
        accessedPaths.insert(fullPath)
    }

    // MARK: - Convenience

    /// Track a block of work for a node
    public func track(for node: ViewNode, _ block: () -> Void) {
        beginTracking(for: node)
        block()
        endTracking()
    }
}

// MARK: - Dependency Index

/// Reverse lookup from state paths to dependent nodes
@MainActor
public class DependencyIndex {
    /// Maps state paths to nodes that depend on them
    private var readDependencies: [String: Set<ObjectIdentifier>] = [:]

    /// Maps state paths to nodes that write to them
    private var writeDependencies: [String: Set<ObjectIdentifier>] = [:]

    /// Maps ObjectIdentifier back to ViewNode (weak references)
    private var nodeRegistry: [ObjectIdentifier: WeakNode] = [:]

    public init() {}

    // MARK: - Registration

    /// Register a node and its dependencies
    public func register(_ node: ViewNode) {
        let id = ObjectIdentifier(node)
        nodeRegistry[id] = WeakNode(node)

        // Register read dependencies
        for path in node.readPaths {
            if readDependencies[path] == nil {
                readDependencies[path] = []
            }
            readDependencies[path]?.insert(id)
        }

        // Register write dependencies
        for path in node.writePaths {
            if writeDependencies[path] == nil {
                writeDependencies[path] = []
            }
            writeDependencies[path]?.insert(id)
        }
    }

    /// Unregister a node
    public func unregister(_ node: ViewNode) {
        let id = ObjectIdentifier(node)
        nodeRegistry.removeValue(forKey: id)

        // Remove from all dependency sets
        for path in node.readPaths {
            readDependencies[path]?.remove(id)
        }
        for path in node.writePaths {
            writeDependencies[path]?.remove(id)
        }
    }

    /// Re-register a node after its dependencies changed
    public func updateRegistration(_ node: ViewNode) {
        unregister(node)
        register(node)
    }

    // MARK: - Lookup

    /// Find all nodes that read from a given path
    public func nodesReading(_ path: String) -> [ViewNode] {
        guard let ids = readDependencies[path] else { return [] }
        return ids.compactMap { nodeRegistry[$0]?.node }
    }

    /// Find all nodes that write to a given path
    public func nodesWriting(_ path: String) -> [ViewNode] {
        guard let ids = writeDependencies[path] else { return [] }
        return ids.compactMap { nodeRegistry[$0]?.node }
    }

    /// Find all nodes affected by changes to the given paths
    public func nodesAffectedBy(paths: Set<String>) -> Set<ViewNode> {
        var affected: Set<ViewNode> = []

        for path in paths {
            // Direct matches
            for node in nodesReading(path) {
                affected.insert(node)
            }

            // Also check for parent path matches
            // e.g., if "user.name" changed, nodes reading "user" are also affected
            let components = path.split(separator: ".")
            var parentPath = ""
            for component in components.dropLast() {
                if !parentPath.isEmpty {
                    parentPath += "."
                }
                parentPath += component
                for node in nodesReading(parentPath) {
                    affected.insert(node)
                }
            }

            // Check for child path matches
            // e.g., if "user" changed, nodes reading "user.name" are also affected
            for (registeredPath, ids) in readDependencies {
                if registeredPath.hasPrefix(path + ".") {
                    for id in ids {
                        if let node = nodeRegistry[id]?.node {
                            affected.insert(node)
                        }
                    }
                }
            }
        }

        return affected
    }

    // MARK: - Maintenance

    /// Remove stale entries (nodes that have been deallocated)
    public func pruneStaleEntries() {
        let staleIds = nodeRegistry.filter { $0.value.node == nil }.map { $0.key }

        for id in staleIds {
            nodeRegistry.removeValue(forKey: id)

            for (path, _) in readDependencies {
                readDependencies[path]?.remove(id)
            }
            for (path, _) in writeDependencies {
                writeDependencies[path]?.remove(id)
            }
        }
    }

    /// Clear all registrations
    public func clear() {
        readDependencies.removeAll()
        writeDependencies.removeAll()
        nodeRegistry.removeAll()
    }

    // MARK: - Debug

    /// Get a debug description of the index
    public var debugDescription: String {
        var lines: [String] = ["DependencyIndex:"]

        lines.append("  Read Dependencies:")
        for (path, ids) in readDependencies.sorted(by: { $0.key < $1.key }) {
            let nodeIds = ids.compactMap { nodeRegistry[$0]?.node?.id }
            lines.append("    \(path) → [\(nodeIds.joined(separator: ", "))]")
        }

        lines.append("  Write Dependencies:")
        for (path, ids) in writeDependencies.sorted(by: { $0.key < $1.key }) {
            let nodeIds = ids.compactMap { nodeRegistry[$0]?.node?.id }
            lines.append("    \(path) → [\(nodeIds.joined(separator: ", "))]")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Weak Node Wrapper

/// Weak reference wrapper for ViewNode
private class WeakNode {
    weak var node: ViewNode?

    init(_ node: ViewNode) {
        self.node = node
    }
}

// MARK: - ViewNode Hashable

extension ViewNode: Hashable {
    public static func == (lhs: ViewNode, rhs: ViewNode) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
