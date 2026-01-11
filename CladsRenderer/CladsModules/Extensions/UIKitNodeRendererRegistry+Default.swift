//
//  UIKitNodeRendererRegistry+Default.swift
//  CladsModules
//
//  Provides the default UIKitNodeRendererRegistry with all built-in renderers registered.
//

import CLADS

extension UIKitNodeRendererRegistry {
    /// A registry with all built-in UIKit renderers registered
    public static var `default`: UIKitNodeRendererRegistry {
        let registry = UIKitNodeRendererRegistry()
        registry.registerBuiltInRenderers()
        return registry
    }

    /// Register all built-in UIKit node renderers
    public func registerBuiltInRenderers() {
        register(TextNodeRenderer())
        register(ButtonNodeRenderer())
        register(TextFieldNodeRenderer())
        register(ImageNodeRenderer())
        register(GradientNodeRenderer())
        register(SpacerNodeRenderer())
        register(DividerNodeRenderer())
        register(ContainerNodeRenderer())
        register(SectionLayoutNodeRenderer())
    }
}
