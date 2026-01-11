//
//  PhotoTouchUpExampleView.swift
//  CladsExamples
//
//  Example view demonstrating the Photo Touch Up bottom sheet with custom components.
//
//  This example demonstrates:
//  - Using the CustomComponent protocol to inject custom views
//  - PhotoComparisonComponent: Before/after image reveal animation
//  - CloseButtonComponent: Circular close button
//  - Standard CLADS JSON for layout, styles, and actions
//
//  Required Assets:
//  - "touchUpBefore": The blurry/before version of the photo
//  - "touchUpAfter": The sharp/after version of the photo
//
//  Usage:
//  ```swift
//  // Present as a sheet
//  .sheet(isPresented: $showPhotoTouchUp) {
//      PhotoTouchUpExampleView()
//          .presentationDetents([.medium])
//  }
//  ```
//

import SwiftUI
import CLADS
import CladsModules

public struct PhotoTouchUpExampleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingLearnMore = false

    public init() {}

    public var body: some View {
        if let rendererView = CladsRendererView(
            jsonString: PhotoTouchUpJSON.bottomSheet,
            customActions: [
                "learnMore": { _, _ in
                    await MainActor.run {
                        showingLearnMore = true
                    }
                },
                "review": { [dismiss] _, _ in
                    await MainActor.run {
                        dismiss()
                    }
                }
            ],
            customComponents: [
                PhotoComparisonComponent.self,
                CloseButtonComponent.self
            ]
        ) {
            rendererView
                .alert("Learn More", isPresented: $showingLearnMore) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("This would open the learn more page about photo touch ups.")
                }
        } else {
            Text("Failed to load view")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Bottom Sheet Presentation Helper

public struct PhotoTouchUpBottomSheet: View {
    @Binding var isPresented: Bool

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                PhotoTouchUpExampleView()
                    .presentationDetents([.height(660)])
                    .presentationDragIndicator(.hidden)
            }
    }
}

// MARK: - Preview

#Preview {
    PhotoTouchUpExampleView()
}

