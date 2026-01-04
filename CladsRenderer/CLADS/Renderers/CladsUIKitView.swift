//
//  CladsUIKitView.swift
//  CladsRendererFramework
//
//  UIKit integration with delegate pattern for state callbacks and efficient updates.
//

import UIKit
import SwiftUI
import Combine

// MARK: - Delegate Protocol

/// Delegate protocol for CladsUIKitView callbacks
@MainActor
public protocol CladsRendererDelegate: AnyObject {
    /// Called when any state value changes
    func cladsRenderer(_ view: CladsUIKitView, didChangeState path: String, from oldValue: Any?, to newValue: Any?)

    /// Called when an action is about to be executed
    func cladsRenderer(_ view: CladsUIKitView, willExecuteAction actionId: String)

    /// Called when an action has finished executing
    func cladsRenderer(_ view: CladsUIKitView, didExecuteAction actionId: String)

    /// Called when a dismiss action is triggered
    func cladsRendererDidRequestDismiss(_ view: CladsUIKitView)

    /// Called when a navigation action is triggered
    func cladsRenderer(_ view: CladsUIKitView, didRequestNavigation destination: String, presentation: Document.NavigationPresentation)

    /// Called when an alert action is triggered
    func cladsRenderer(_ view: CladsUIKitView, didRequestAlert config: AlertConfiguration)
}

/// Default implementations (all optional)
public extension CladsRendererDelegate {
    func cladsRenderer(_ view: CladsUIKitView, didChangeState path: String, from oldValue: Any?, to newValue: Any?) {}
    func cladsRenderer(_ view: CladsUIKitView, willExecuteAction actionId: String) {}
    func cladsRenderer(_ view: CladsUIKitView, didExecuteAction actionId: String) {}
    func cladsRendererDidRequestDismiss(_ view: CladsUIKitView) {}
    func cladsRenderer(_ view: CladsUIKitView, didRequestNavigation destination: String, presentation: Document.NavigationPresentation) {}
    func cladsRenderer(_ view: CladsUIKitView, didRequestAlert config: AlertConfiguration) {}
}

// MARK: - CladsUIKitView

/// Main UIKit view for rendering CLADS documents with delegate callbacks and efficient updates
public final class CladsUIKitView: UIView {

    // MARK: - Public Properties

    /// Delegate for receiving callbacks
    public weak var delegate: CladsRendererDelegate?

    /// Access to the current state snapshot
    public var stateSnapshot: [String: Any] {
        return stateStore.snapshot()
    }

    /// Access to typed state
    public func getTypedState<T: Decodable>(_ type: T.Type = T.self) -> T? {
        return stateStore.getTyped(type)
    }

    // MARK: - Private Properties

    private let document: Document.Definition
    private let renderTree: RenderTree
    private let stateStore: StateStore
    private let actionContext: ActionContext
    private let rendererRegistry: UIKitNodeRendererRegistry
    private var treeUpdater: ViewTreeUpdater?
    private var viewTreeRoot: ViewNode?

    /// Registry mapping ViewNode IDs to rendered UIViews
    private var viewRegistry: [String: WeakViewRef] = [:]

    /// State change callback ID
    private var stateCallbackId: UUID?

    // MARK: - Initialization

    /// Initialize with a document and optional custom action handlers.
    ///
    /// - Parameters:
    ///   - document: The document definition to render
    ///   - actionRegistry: The action registry for handling actions
    ///   - rendererRegistry: The UIKit node renderer registry
    ///   - customActions: View-specific action closures, keyed by action ID
    ///   - actionDelegate: Delegate for handling custom actions
    ///
    /// Example:
    /// ```swift
    /// let view = CladsUIKitView(
    ///     document: document,
    ///     actionRegistry: actionRegistry,
    ///     componentRegistry: componentRegistry,
    ///     rendererRegistry: rendererRegistry,
    ///     customActions: [
    ///         "submitOrder": { params, context in
    ///             let orderId = context.stateStore.get("order.id") as? String
    ///             await OrderService.submit(orderId)
    ///         }
    ///     ]
    /// )
    /// ```
    public init(
        document: Document.Definition,
        actionRegistry: ActionRegistry,
        componentRegistry: ComponentResolverRegistry,
        rendererRegistry: UIKitNodeRendererRegistry,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil
    ) {
        self.document = document
        self.rendererRegistry = rendererRegistry

        // Resolve with tracking for efficient updates
        let resolver = Resolver(document: document, componentRegistry: componentRegistry)
        do {
            let result = try resolver.resolveWithTracking()
            self.renderTree = result.renderTree
            self.stateStore = result.renderTree.stateStore
            self.treeUpdater = result.treeUpdater
            self.viewTreeRoot = result.viewTreeRoot
        } catch {
            print("CladsUIKitView: Resolution failed - \(error)")
            self.renderTree = RenderTree(root: RootNode(), stateStore: StateStore(), actions: [:])
            self.stateStore = StateStore()
            self.treeUpdater = nil
            self.viewTreeRoot = nil
        }

        self.actionContext = ActionContext(
            stateStore: stateStore,
            actionDefinitions: document.actions ?? [:],
            registry: actionRegistry,
            customActions: customActions,
            actionDelegate: actionDelegate
        )

        super.init(frame: .zero)

        setupView()
        setupCallbacks()
        setupActionHandlers()
    }

    /// Initialize from a JSON string with optional custom action handlers.
    public convenience init?(
        jsonString: String,
        actionRegistry: ActionRegistry,
        componentRegistry: ComponentResolverRegistry,
        rendererRegistry: UIKitNodeRendererRegistry,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil
    ) {
        guard let document = try? Document.Definition(jsonString: jsonString) else {
            return nil
        }
        self.init(
            document: document,
            actionRegistry: actionRegistry,
            componentRegistry: componentRegistry,
            rendererRegistry: rendererRegistry,
            customActions: customActions,
            actionDelegate: actionDelegate
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Capture values before self is deallocated
        if let id = stateCallbackId {
            let store = stateStore
            Task { @MainActor in
                store.removeStateChangeCallback(id)
            }
        }
    }

    // MARK: - Public API

    /// Set a state value programmatically
    public func setState(_ path: String, value: Any?) {
        stateStore.set(path, value: value)
    }

    /// Set typed state programmatically
    public func setTypedState<T: Encodable>(_ value: T) {
        stateStore.setTyped(value)
    }

    /// Set typed state at a specific path
    public func setTypedState<T: Encodable>(_ path: String, value: T) {
        stateStore.setTyped(path, value: value)
    }

    /// Get a state value
    public func getState(_ path: String) -> Any? {
        return stateStore.get(path)
    }

    /// Get a typed state value
    public func getState<T>(_ path: String, as type: T.Type = T.self) -> T? {
        return stateStore.get(path, as: type)
    }

    /// Execute an action by ID
    public func executeAction(_ actionId: String) {
        Task { @MainActor in
            delegate?.cladsRenderer(self, willExecuteAction: actionId)
            await actionContext.executeAction(id: actionId)
            delegate?.cladsRenderer(self, didExecuteAction: actionId)
        }
    }

    /// Execute an action binding (reference or inline)
    public func executeAction(_ binding: Document.Component.ActionBinding) {
        Task { @MainActor in
            switch binding {
            case .reference(let actionId):
                delegate?.cladsRenderer(self, willExecuteAction: actionId)
                await actionContext.executeAction(id: actionId)
                delegate?.cladsRenderer(self, didExecuteAction: actionId)
            case .inline(let action):
                delegate?.cladsRenderer(self, willExecuteAction: "inline")
                await actionContext.executeAction(action)
                delegate?.cladsRenderer(self, didExecuteAction: "inline")
            }
        }
    }

    /// Force a full re-render of the view tree
    public func rerender() {
        subviews.forEach { $0.removeFromSuperview() }
        viewRegistry.removeAll()
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        // Background color
        if let bg = renderTree.root.backgroundColor {
            backgroundColor = UIColor(bg)
        } else {
            backgroundColor = .systemBackground
        }

        // Content container
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        // Apply edge insets
        let insets = resolveEdgeInsets(renderTree.root.edgeInsets)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: insets.top),
            contentStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -insets.bottom),
            contentStack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: insets.leading),
            contentStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -insets.trailing)
        ])

        // Add children with registry tracking
        for (index, child) in renderTree.root.children.enumerated() {
            let viewNodeId = viewTreeRoot?.children[safe: index]?.id
            let childView = renderNode(child, viewNodeId: viewNodeId)
            contentStack.addArrangedSubview(childView)
        }
    }

    private func setupCallbacks() {
        // Register for state changes
        stateCallbackId = stateStore.onStateChange { [weak self] path, oldValue, newValue in
            guard let self = self else { return }
            self.delegate?.cladsRenderer(self, didChangeState: path, from: oldValue, to: newValue)
        }

        // Set up tree updater callback for efficient updates
        treeUpdater?.onNodesNeedUpdate = { [weak self] nodes in
            self?.handleNodesNeedUpdate(nodes)
        }
    }

    private func setupActionHandlers() {
        actionContext.dismissHandler = { [weak self] in
            guard let self = self else { return }
            self.delegate?.cladsRendererDidRequestDismiss(self)
        }

        actionContext.alertHandler = { [weak self] config in
            guard let self = self else { return }
            self.delegate?.cladsRenderer(self, didRequestAlert: config)
        }

        actionContext.navigationHandler = { [weak self] destination, presentation in
            guard let self = self else { return }
            self.delegate?.cladsRenderer(self, didRequestNavigation: destination, presentation: presentation ?? .push)
        }
    }

    // MARK: - Efficient Updates

    private func handleNodesNeedUpdate(_ nodes: Set<ViewNode>) {
        // Get minimal update set to avoid redundant work
        guard let updater = treeUpdater else { return }
        let minimalSet = updater.getMinimalUpdateSet()

        for node in minimalSet {
            updateNodeView(node)
            updater.markNodeUpdated(node)
        }
    }

    private func updateNodeView(_ node: ViewNode) {
        guard let view = viewRegistry[node.id]?.view else { return }

        // Update the view based on its type
        switch node.nodeType {
        case .text(let data):
            if let label = view as? UILabel {
                // Re-resolve content with current state
                let content = resolveTextContent(for: node)
                label.text = content
            }

        case .button(let data):
            if let button = view as? UIButton {
                let content = resolveTextContent(for: node)
                button.setTitle(content.isEmpty ? data.label : content, for: .normal)
            }

        case .textField(let data):
            if let textField = view as? BoundTextField {
                // TextField handles its own binding, but we might need to refresh
                if let path = data.bindingPath, !path.hasPrefix("local.") {
                    textField.text = stateStore.get(path) as? String ?? ""
                }
            }

        default:
            break
        }
    }

    private func resolveTextContent(for node: ViewNode) -> String {
        // Check read paths for the node and resolve from state
        for path in node.readPaths {
            if path.hasPrefix("local.") {
                // Local state
                let localPath = String(path.dropFirst(6))
                if let value = node.getLocalState(localPath) {
                    return String(describing: value)
                }
            } else {
                // Global state
                if let value = stateStore.get(path) {
                    return String(describing: value)
                }
            }
        }
        return ""
    }

    // MARK: - Node Rendering (with registry)

    private func renderNode(_ node: RenderNode, viewNodeId: String?) -> UIView {
        let view: UIView

        switch node {
        case .container(let container):
            view = renderContainer(container)
        case .sectionLayout(let sectionLayout):
            view = renderSectionLayout(sectionLayout)
        case .text(let text):
            view = renderText(text)
        case .button(let button):
            view = renderButton(button)
        case .textField(let textField):
            view = renderTextField(textField)
        case .toggle(let toggle):
            view = renderToggle(toggle)
        case .slider(let slider):
            view = renderSlider(slider)
        case .image(let image):
            view = renderImage(image)
        case .gradient(let gradient):
            view = renderGradient(gradient)
        case .spacer:
            view = renderSpacer()
        case .custom(let kind, _):
            // Use the UIKit renderer registry for custom nodes
            let context = UIKitRenderContext(actionContext: actionContext, stateStore: renderTree.stateStore, colorScheme: renderTree.root.colorScheme, registry: rendererRegistry)
            if rendererRegistry.hasRenderer(for: kind) {
                view = rendererRegistry.render(node, context: context)
            } else {
                view = UIView() // No renderer registered
            }
        }

        // Register view for efficient updates
        if let nodeId = viewNodeId {
            viewRegistry[nodeId] = WeakViewRef(view)
        }

        return view
    }

    // MARK: - Rendering Methods (same as before but with registry tracking)

    private func renderContainer(_ container: ContainerNode) -> UIView {
        let contentView: UIView

        switch container.layoutType {
        case .vstack, .hstack:
            let stackView = UIStackView()
            stackView.axis = container.layoutType == .vstack ? .vertical : .horizontal
            stackView.spacing = container.spacing
            stackView.alignment = container.alignment.toUIKit(for: container.layoutType)
            stackView.distribution = .fill
            stackView.translatesAutoresizingMaskIntoConstraints = false

            for child in container.children {
                let childView = renderNode(child, viewNodeId: nil)
                stackView.addArrangedSubview(childView)
            }
            contentView = stackView

        case .zstack:
            let zstackView = UIView()
            zstackView.translatesAutoresizingMaskIntoConstraints = false

            for child in container.children {
                let childView = renderNode(child, viewNodeId: nil)
                childView.translatesAutoresizingMaskIntoConstraints = false
                zstackView.addSubview(childView)
                applyZStackAlignment(childView, in: zstackView, alignment: container.alignment)
            }
            contentView = zstackView
        }

        // Wrap in container for padding if needed
        if !container.padding.isEmpty {
            let wrapper = UIView()
            wrapper.translatesAutoresizingMaskIntoConstraints = false
            wrapper.addSubview(contentView)
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: container.padding.top),
                contentView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -container.padding.bottom),
                contentView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: container.padding.leading),
                contentView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -container.padding.trailing)
            ])
            return wrapper
        }

        return contentView
    }

    private func applyZStackAlignment(_ child: UIView, in parent: UIView, alignment: SwiftUI.Alignment) {
        // Horizontal
        if alignment.horizontal == .leading {
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor).isActive = true
        } else if alignment.horizontal == .trailing {
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor).isActive = true
        } else {
            child.centerXAnchor.constraint(equalTo: parent.centerXAnchor).isActive = true
        }

        // Vertical
        if alignment.vertical == .top {
            child.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        } else if alignment.vertical == .bottom {
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor).isActive = true
        } else {
            child.centerYAnchor.constraint(equalTo: parent.centerYAnchor).isActive = true
        }
    }

    private func renderText(_ text: TextNode) -> UIView {
        let label = UILabel()
        label.text = text.content
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.applyStyle(text.style)
        return label
    }

    private func renderButton(_ button: ButtonNode) -> UIView {
        let uiButton = DelegateActionButton(
            actionBinding: button.onTap,
            cladsView: self
        )
        uiButton.setTitle(button.label, for: .normal)
        uiButton.translatesAutoresizingMaskIntoConstraints = false
        uiButton.applyStyle(button.style)

        if button.fillWidth {
            uiButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }

        if let height = button.style.height {
            uiButton.heightAnchor.constraint(equalToConstant: height).isActive = true
        }

        return uiButton
    }

    private func renderTextField(_ textField: TextFieldNode) -> UIView {
        let field = BoundTextField(
            bindingPath: textField.bindingPath,
            stateStore: stateStore
        )
        field.placeholder = textField.placeholder
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.applyStyle(textField.style)
        return field
    }

    private func renderToggle(_ toggle: ToggleNode) -> UIView {
        let uiSwitch = BoundSwitch(
            bindingPath: toggle.bindingPath,
            stateStore: stateStore
        )
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        if let tintColor = toggle.style.tintColor {
            uiSwitch.onTintColor = UIColor(tintColor)
        }
        return uiSwitch
    }

    private func renderSlider(_ slider: SliderNode) -> UIView {
        let uiSlider = BoundSlider(
            bindingPath: slider.bindingPath,
            minValue: slider.minValue,
            maxValue: slider.maxValue,
            stateStore: stateStore
        )
        uiSlider.translatesAutoresizingMaskIntoConstraints = false
        if let tintColor = slider.style.tintColor {
            uiSlider.minimumTrackTintColor = UIColor(tintColor)
        }
        return uiSlider
    }

    private func renderImage(_ image: ImageNode) -> UIView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        switch image.source {
        case .system(let name):
            imageView.image = UIImage(systemName: name)
        case .asset(let name):
            imageView.image = UIImage(named: name)
        case .url(let url):
            loadImageAsync(from: url, into: imageView)
        }

        if let width = image.style.width {
            imageView.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let height = image.style.height {
            imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }

        return imageView
    }

    private func loadImageAsync(from url: URL, into imageView: UIImageView) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        imageView.image = image
                    }
                }
            } catch {
                print("Failed to load image from \(url): \(error)")
            }
        }
    }

    private func renderSpacer() -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return spacer
    }

    private func renderGradient(_ gradient: GradientNode) -> UIView {
        let gradientView = GradientView(
            node: gradient,
            colorScheme: renderTree.root.colorScheme
        )
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        if let width = gradient.style.width {
            gradientView.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let height = gradient.style.height {
            gradientView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }

        return gradientView
    }

    private func renderSectionLayout(_ sectionLayout: SectionLayoutNode) -> UIView {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = sectionLayout.sectionSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        for section in sectionLayout.sections {
            let sectionView = renderSection(section)
            stackView.addArrangedSubview(sectionView)
        }

        return scrollView
    }

    private func renderSection(_ section: IR.Section) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 0
        container.translatesAutoresizingMaskIntoConstraints = false

        if let header = section.header {
            let headerView = renderNode(header, viewNodeId: nil)
            container.addArrangedSubview(headerView)
        }

        let contentView = renderSectionContent(section)
        container.addArrangedSubview(contentView)

        if let footer = section.footer {
            let footerView = renderNode(footer, viewNodeId: nil)
            container.addArrangedSubview(footerView)
        }

        if !section.config.contentInsets.isEmpty {
            let wrapper = UIView()
            wrapper.translatesAutoresizingMaskIntoConstraints = false
            wrapper.addSubview(container)
            let insets = section.config.contentInsets
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: insets.top),
                container.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -insets.bottom),
                container.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: insets.leading),
                container.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -insets.trailing)
            ])
            return wrapper
        }

        return container
    }

    private func renderSectionContent(_ section: IR.Section) -> UIView {
        switch section.layoutType {
        case .horizontal:
            return renderHorizontalSection(section)
        case .list:
            return renderListSection(section)
        case .grid(let columns):
            return renderGridSection(section, columns: columns)
        case .flow:
            return renderGridSection(section, columns: .adaptive(minWidth: 80))
        }
    }

    private func renderHorizontalSection(_ section: IR.Section) -> UIView {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = section.config.showsIndicators
        scrollView.isPagingEnabled = section.config.isPagingEnabled

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = section.config.itemSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        for child in section.children {
            let childView = renderNode(child, viewNodeId: nil)
            stackView.addArrangedSubview(childView)
        }

        return scrollView
    }

    private func renderListSection(_ section: IR.Section) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = section.config.itemSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        for (index, child) in section.children.enumerated() {
            let childView = renderNode(child, viewNodeId: nil)
            stackView.addArrangedSubview(childView)

            if section.config.showsDividers && index < section.children.count - 1 {
                let divider = UIView()
                divider.backgroundColor = .separator
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
                stackView.addArrangedSubview(divider)
            }
        }

        return stackView
    }

    private func renderGridSection(_ section: IR.Section, columns: IR.ColumnConfig) -> UIView {
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = section.config.lineSpacing
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        let columnCount: Int
        switch columns {
        case .fixed(let count):
            columnCount = count
        case .adaptive:
            columnCount = 2
        }

        var currentRow: UIStackView?
        var itemsInRow = 0

        for child in section.children {
            if currentRow == nil || itemsInRow >= columnCount {
                currentRow = UIStackView()
                currentRow?.axis = .horizontal
                currentRow?.spacing = section.config.itemSpacing
                currentRow?.distribution = .fillEqually
                currentRow?.translatesAutoresizingMaskIntoConstraints = false
                containerStack.addArrangedSubview(currentRow!)
                itemsInRow = 0
            }

            let childView = renderNode(child, viewNodeId: nil)
            currentRow?.addArrangedSubview(childView)
            itemsInRow += 1
        }

        if let lastRow = currentRow, itemsInRow < columnCount {
            for _ in 0..<(columnCount - itemsInRow) {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                lastRow.addArrangedSubview(spacer)
            }
        }

        return containerStack
    }

    // MARK: - Helpers

    private func resolveEdgeInsets(_ insets: IR.EdgeInsets?) -> (top: CGFloat, bottom: CGFloat, leading: CGFloat, trailing: CGFloat) {
        guard let insets = insets else {
            return (0, 0, 0, 0)
        }
        return (
            top: insets.top?.value ?? 0,
            bottom: insets.bottom?.value ?? 0,
            leading: insets.leading?.value ?? 0,
            trailing: insets.trailing?.value ?? 0
        )
    }
}

// MARK: - Weak View Reference

private class WeakViewRef {
    weak var view: UIView?

    init(_ view: UIView) {
        self.view = view
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Delegate Action Button

/// Button that notifies the CladsUIKitView delegate
private final class DelegateActionButton: UIButton {
    private let actionBinding: Document.Component.ActionBinding?
    private weak var cladsView: CladsUIKitView?

    init(actionBinding: Document.Component.ActionBinding?, cladsView: CladsUIKitView) {
        self.actionBinding = actionBinding
        self.cladsView = cladsView
        super.init(frame: .zero)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        guard let binding = actionBinding, let cladsView = cladsView else { return }
        cladsView.executeAction(binding)
    }
}

// MARK: - View Controller Convenience

/// A view controller that wraps CladsUIKitView
open class CladsViewController: UIViewController, CladsRendererDelegate {

    /// The underlying CladsUIKitView
    public private(set) var cladsView: CladsUIKitView!

    /// Access to the current state snapshot
    public var stateSnapshot: [String: Any] {
        return cladsView.stateSnapshot
    }

    public init(
        document: Document.Definition,
        actionRegistry: ActionRegistry,
        componentRegistry: ComponentResolverRegistry,
        rendererRegistry: UIKitNodeRendererRegistry
    ) {
        super.init(nibName: nil, bundle: nil)
        cladsView = CladsUIKitView(
            document: document,
            actionRegistry: actionRegistry,
            componentRegistry: componentRegistry,
            rendererRegistry: rendererRegistry
        )
        cladsView.delegate = self
    }

    public convenience init?(
        jsonString: String,
        actionRegistry: ActionRegistry,
        componentRegistry: ComponentResolverRegistry,
        rendererRegistry: UIKitNodeRendererRegistry
    ) {
        guard let document = try? Document.Definition(jsonString: jsonString) else {
            return nil
        }
        self.init(document: document, actionRegistry: actionRegistry, componentRegistry: componentRegistry, rendererRegistry: rendererRegistry)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(cladsView)
        cladsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cladsView.topAnchor.constraint(equalTo: view.topAnchor),
            cladsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cladsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cladsView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - CladsRendererDelegate (Override in subclass)

    open func cladsRenderer(_ view: CladsUIKitView, didChangeState path: String, from oldValue: Any?, to newValue: Any?) {
        // Override in subclass
    }

    open func cladsRenderer(_ view: CladsUIKitView, willExecuteAction actionId: String) {
        // Override in subclass
    }

    open func cladsRenderer(_ view: CladsUIKitView, didExecuteAction actionId: String) {
        // Override in subclass
    }

    open func cladsRendererDidRequestDismiss(_ view: CladsUIKitView) {
        dismiss(animated: true)
    }

    open func cladsRenderer(_ view: CladsUIKitView, didRequestNavigation destination: String, presentation: Document.NavigationPresentation) {
        // Override in subclass for navigation
    }

    open func cladsRenderer(_ view: CladsUIKitView, didRequestAlert config: AlertConfiguration) {
        AlertPresenter.present(config)
    }
}
