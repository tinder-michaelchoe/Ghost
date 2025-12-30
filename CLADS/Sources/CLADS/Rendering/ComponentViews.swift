//
//  ComponentViews.swift
//  CladsRendererFramework
//

import SwiftUI

// MARK: - Label Component

struct LabelView: View {
    let component: Document.Component
    let style: IR.Style
    let text: String

    var body: some View {
        Text(text)
            .applyTextStyle(style)
    }
}

// MARK: - Button Component

struct ButtonView: View {
    let component: Document.Component
    let style: IR.Style
    @EnvironmentObject var context: ActionContext

    var body: some View {
        Button(action: {
            if let binding = component.actions?.onTap {
                context.execute(binding)
            }
        }) {
            Text(component.text ?? "")
                .applyTextStyle(style)
                .frame(maxWidth: component.fillWidth == true ? .infinity : nil)
                .frame(height: style.height)
                .background(style.backgroundColor ?? Color.clear)
                .cornerRadius(style.cornerRadius ?? 0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TextField Component

struct TextFieldView: View {
    let component: Document.Component
    let style: IR.Style
    @EnvironmentObject var stateStore: StateStore

    var body: some View {
        let binding = stateStore.binding(for: component.bind ?? "")

        TextField(component.placeholder ?? "", text: binding)
            .applyTextStyle(style)
            .padding(.horizontal, style.paddingLeading ?? 12)
            .padding(.vertical, style.paddingTop ?? 8)
            .background(style.backgroundColor ?? Color(.systemGray6))
            .cornerRadius(style.cornerRadius ?? 8)
    }
}

// MARK: - Style Modifiers

extension View {
    func applyTextStyle(_ style: IR.Style) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.textColor)
            .multilineTextAlignment(style.textAlignment ?? .leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }

    func applyContainerStyle(_ style: IR.Style) -> some View {
        self
            .padding(.top, style.paddingTop ?? 0)
            .padding(.bottom, style.paddingBottom ?? 0)
            .padding(.leading, style.paddingLeading ?? 0)
            .padding(.trailing, style.paddingTrailing ?? 0)
            .frame(width: style.width, height: style.height)
            .frame(minWidth: style.minWidth, minHeight: style.minHeight)
            .frame(maxWidth: style.maxWidth, maxHeight: style.maxHeight)
            .background(style.backgroundColor ?? Color.clear)
            .cornerRadius(style.cornerRadius ?? 0)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius ?? 0)
                    .stroke(style.borderColor ?? Color.clear, lineWidth: style.borderWidth ?? 0)
            )
    }
}
