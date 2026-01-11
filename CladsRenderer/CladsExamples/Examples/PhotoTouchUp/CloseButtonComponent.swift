//
//  CloseButtonComponent.swift
//  CladsExamples
//
//  Custom close button component with circular gray background.
//

import SwiftUI
import CLADS

/// Custom component for a close button with circular gray background.
///
/// JSON usage:
/// ```json
/// {
///   "type": "closeButton",
///   "actions": { "onTap": "dismiss" }
/// }
/// ```
public struct CloseButtonComponent: CustomComponent {
    public static let typeName = "closeButton"

    @MainActor
    public static func makeView(context: CustomComponentContext) -> AnyView {
        return AnyView(
            CloseButtonView(context: context)
        )
    }
}

// MARK: - Close Button View

struct CloseButtonView: View {
    let context: CustomComponentContext

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.96))
                    .frame(width: 32, height: 32)

                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(white: 0.4))
            }
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        Task {
            await context.executeAction(context.component.actions?.onTap)
        }
    }
}

