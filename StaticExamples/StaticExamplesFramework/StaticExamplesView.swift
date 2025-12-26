//
//  ContentView.swift
//  StaticExamples
//
//  Created by mexicanpizza on 12/23/25.
//

import SwiftUI

private struct ListRow: Identifiable {
    let id: Int
    let title: String
    let action: () -> Void
}

public struct StaticExamplesView: View {
    
    var viewModel: ViewModel = .init()
    
    public init() {}
    
    public var body: some View {
        List(viewModel.allExamples, rowContent: { row in
            Button(action: row.action) {
                Text(row.title)
                    .foregroundStyle(.black)
            }
        })
        .navigationTitle("All Examples")
        .navigationBarTitleDisplayMode(.large)
    }
}

extension StaticExamplesView {
    
    @Observable
    class ViewModel {
        fileprivate let allExamples: [ListRow] = [
            ListRow(id: 0, title: "Basic", action: {
                print("Did press basic example")
            }),
            ListRow(id: 1, title: "Year End Review", action: {
                print("Did press year end review example")
            }),
            ListRow(id: 2, title: "Simple Navigation", action: {
                print("Did press simple navigation")
            }),
        ]
    }
}

#Preview {
    StaticExamplesView()
}
