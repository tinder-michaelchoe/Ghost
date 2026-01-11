//
//  PhotoComparisonComponent.swift
//  CladsExamples
//
//  Custom component for photo before/after comparison animation.
//

import CLADS
import SwiftUI

/// Custom component that shows a before/after photo comparison with an animated reveal.
///
/// JSON usage:
/// ```json
/// {
///   "type": "photoComparison",
///   "data": {
///     "beforeImage": { "type": "static", "value": "touchUpBefore" },
///     "afterImage": { "type": "static", "value": "touchUpAfter" }
///   }
/// }
/// ```
public struct PhotoComparisonComponent: CustomComponent {
    public static let typeName = "photoComparison"

    @MainActor
    public static func makeView(context: CustomComponentContext) -> AnyView {
        let beforeImage = context.resolveString(forKey: "beforeImage") ?? ""
        let afterImage = context.resolveString(forKey: "afterImage") ?? ""
        
        // Get size from style
        let width = context.style.width ?? 200
        let height = context.style.height ?? 300

        return AnyView(
            PhotoComparisonView(
                beforeImageName: beforeImage,
                afterImageName: afterImage,
                width: width,
                height: height
            )
        )
    }
}

// MARK: - Photo Comparison View

struct PhotoComparisonView: View {
    let beforeImageName: String
    let afterImageName: String
    let width: CGFloat
    let height: CGFloat

    @State private var revealProgress: CGFloat = 0.0

    var body: some View {
        ZStack {
            // Bottom layer - blurry/before image
            imageView(name: beforeImageName)
                .frame(width: width, height: height)
                .clipped()

            // Top layer - sharp/after image with mask
            imageView(name: afterImageName)
                .frame(width: width, height: height)
                .clipped()
                .mask(
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: width * revealProgress)
                        Spacer(minLength: 0)
                    }
                )

            // Vertical divider bar
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: max(0, width * revealProgress - 1))

                // Divider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 0)

                Spacer(minLength: 0)
            }

            // Comparison icon centered on the divider
            ComparisonIcon()
                .offset(x: (width * revealProgress) - (width / 2))
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            // Sparkle icon at top right
            SparkleIcon()
                .offset(x: width / 2 - 20, y: -height / 2 + 20)
        )
        .onAppear {
            startAnimation()
        }
    }

    @ViewBuilder
    private func imageView(name: String) -> some View {
        // Try multiple bundle locations for the image
        if let uiImage = UIImage(named: name, in: Bundle(for: BundleToken.self), compatibleWith: nil)
            ?? UIImage(named: name, in: .main, compatibleWith: nil) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Placeholder for missing image
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text(name)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                )
        }
    }

    private func startAnimation() {
        // Initial delay before starting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                revealProgress = 1.0
            }
        }
    }
}

// MARK: - Comparison Icon

struct ComparisonIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.gray)
        }
    }
}

// MARK: - Sparkle Icon

struct SparkleIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.95))
                .frame(width: 32, height: 32)

            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Bundle Token

/// Token class to identify the CladsExamples bundle for loading assets
private final class BundleToken {}

// MARK: - Preview

#Preview {
    PhotoComparisonView(
        beforeImageName: "touchUpBefore",
        afterImageName: "touchUpAfter",
        width: 260,
        height: 350
    )
    .padding()
}

