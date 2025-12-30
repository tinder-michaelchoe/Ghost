//
//  ViewTreeUpdater.swift
//  CladsRendererFramework
//
//  Coordinates updates between StateStore and ViewTree for minimal re-renders.
//

import Foundation

// MARK: - View Tree Updater

/// Coordinates state changes with view tree updates for minimal re-rendering
@MainActor
public class ViewTreeUpdater {
    /// The root of the view tree
    public var root: ViewNode?

    /// Dependency index for reverse lookups
    public let dependencyIndex: DependencyIndex

    /// Dependency tracker for collecting dependencies during resolution
    public let dependencyTracker: DependencyTracker

    /// The state store being observed
    private weak var stateStore: StateStore?

    /// Callback ID for state changes
    private var stateCallbackId: UUID?

    /// Nodes that need to be updated
    private var pendingUpdates: Set<ViewNode> = []

    /// Callback invoked when nodes need updating
    public var onNodesNeedUpdate: ((_ nodes: Set<ViewNode>) -> Void)?

    public init() {
        self.dependencyIndex = DependencyIndex()
        self.dependencyTracker = DependencyTracker()
    }

    // MARK: - Setup

    /// Attach to a state store to receive change notifications
    public func attach(to stateStore: StateStore) {
        // Detach from previous store
        detach()

        self.stateStore = stateStore

        // Register for state changes
        stateCallbackId = stateStore.onStateChange { [weak self] path, oldValue, newValue in
            self?.handleStateChange(path: path, oldValue: oldValue, newValue: newValue)
        }
    }

    /// Detach from the state store
    public func detach() {
        if let id = stateCallbackId, let store = stateStore {
            store.removeStateChangeCallback(id)
        }
        stateCallbackId = nil
        stateStore = nil
    }

    // MARK: - Tree Management

    /// Set the root node and register all nodes
    public func setRoot(_ node: ViewNode) {
        // Clear existing registrations
        dependencyIndex.clear()

        self.root = node

        // Register all nodes
        registerSubtree(node)
    }

    /// Register a node and all its descendants
    public func registerSubtree(_ node: ViewNode) {
        dependencyIndex.register(node)
        for child in node.children {
            registerSubtree(child)
        }
    }

    /// Unregister a node and all its descendants
    public func unregisterSubtree(_ node: ViewNode) {
        for child in node.children {
            unregisterSubtree(child)
        }
        dependencyIndex.unregister(node)
    }

    /// Update registration for a node after its dependencies changed
    public func updateNodeDependencies(_ node: ViewNode) {
        dependencyIndex.updateRegistration(node)
    }

    // MARK: - State Change Handling

    private func handleStateChange(path: String, oldValue: Any?, newValue: Any?) {
        // Find all nodes affected by this path change
        let affectedNodes = dependencyIndex.nodesAffectedBy(paths: [path])

        guard !affectedNodes.isEmpty else { return }

        // Mark nodes as needing update
        for node in affectedNodes {
            node.needsUpdate = true
            pendingUpdates.insert(node)
        }

        // Notify listener
        onNodesNeedUpdate?(affectedNodes)
    }

    // MARK: - Update Processing

    /// Process pending updates using dirty paths from state store
    public func processDirtyPaths() {
        guard let store = stateStore else { return }

        let dirtyPaths = store.consumeDirtyPaths()
        guard !dirtyPaths.isEmpty else { return }

        let affectedNodes = dependencyIndex.nodesAffectedBy(paths: dirtyPaths)

        for node in affectedNodes {
            node.needsUpdate = true
            pendingUpdates.insert(node)
        }

        if !affectedNodes.isEmpty {
            onNodesNeedUpdate?(affectedNodes)
        }
    }

    /// Get all nodes that need updating
    public func getNodesNeedingUpdate() -> Set<ViewNode> {
        return pendingUpdates
    }

    /// Clear the pending update flag for a node
    public func markNodeUpdated(_ node: ViewNode) {
        node.needsUpdate = false
        node.lastUpdateTimestamp = Date()
        pendingUpdates.remove(node)
    }

    /// Clear all pending updates
    public func clearPendingUpdates() {
        for node in pendingUpdates {
            node.needsUpdate = false
        }
        pendingUpdates.removeAll()
    }

    /// Check if any updates are pending
    public var hasUpdates: Bool {
        return !pendingUpdates.isEmpty
    }

    // MARK: - Optimized Update Paths

    /// Get the minimal set of nodes to update (excludes children of updated ancestors)
    public func getMinimalUpdateSet() -> Set<ViewNode> {
        var minimal: Set<ViewNode> = []

        for node in pendingUpdates {
            // Check if any ancestor is also pending
            var hasAncestorUpdate = false
            var current = node.parent
            while let parent = current {
                if pendingUpdates.contains(parent) {
                    hasAncestorUpdate = true
                    break
                }
                current = parent.parent
            }

            // Only include if no ancestor is being updated
            if !hasAncestorUpdate {
                minimal.insert(node)
            }
        }

        return minimal
    }

    /// Get nodes grouped by their depth in the tree
    /// Useful for batch updates from root to leaves
    public func getUpdatesByDepth() -> [[ViewNode]] {
        var depthMap: [Int: [ViewNode]] = [:]

        for node in pendingUpdates {
            let depth = node.pathFromRoot().count - 1
            if depthMap[depth] == nil {
                depthMap[depth] = []
            }
            depthMap[depth]?.append(node)
        }

        // Sort by depth and return arrays
        return depthMap.keys.sorted().compactMap { depthMap[$0] }
    }

    // MARK: - Local State Handling

    /// Handle local state change for a node
    public func handleLocalStateChange(node: ViewNode, path: String) {
        // Find nodes that depend on this local path
        let fullPath = "local.\(path)"

        // For local state, we only need to update descendants of the node
        // that declares the state
        var affected: Set<ViewNode> = []

        func checkNode(_ n: ViewNode) {
            if n.readPaths.contains(fullPath) {
                affected.insert(n)
            }
            for child in n.children {
                checkNode(child)
            }
        }

        checkNode(node)

        for affectedNode in affected {
            affectedNode.needsUpdate = true
            pendingUpdates.insert(affectedNode)
        }

        if !affected.isEmpty {
            onNodesNeedUpdate?(affected)
        }
    }

    // MARK: - Debug

    /// Get a debug description of pending updates
    public var debugDescription: String {
        var lines = ["ViewTreeUpdater:"]
        lines.append("  Pending Updates: \(pendingUpdates.count)")

        for node in pendingUpdates.sorted(by: { $0.id < $1.id }) {
            lines.append("    - \(node.id)")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Update Batch

/// Represents a batch of updates to apply
public struct UpdateBatch {
    /// Nodes to update, ordered by depth (root first)
    public let nodes: [ViewNode]

    /// Paths that triggered this update
    public let triggeringPaths: Set<String>

    /// Timestamp when batch was created
    public let timestamp: Date

    public init(nodes: [ViewNode], triggeringPaths: Set<String>) {
        self.nodes = nodes
        self.triggeringPaths = triggeringPaths
        self.timestamp = Date()
    }
}
