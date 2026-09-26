//
//  FactsUI.swift
//  CatFacts
//
//  Created by Diogo Nunes on 26/09/2026.
//

import SwiftUI

struct FactsUI: View {
    @ObservedObject var viewModel: FactsViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded:
                let facts = viewModel.searchResults
                if facts.isEmpty {
                    StatusView(content: .noResults(for: viewModel.query))
                } else {
                    ScrollView {
                        LazyVStack {
                          ForEach(facts, id: \.id) { fact in
                                FactsItemView(fact: fact)
                            }
                        }
                    }
                    // A new identity per query starts the results at the top, instead of keeping an offset
                    // that can sit past the end of a shorter list.
                    .id(viewModel.query)
                }
            case .empty:
                StatusView(content: StatusView.Content.empty) {
                    Task { await viewModel.load() }
                }
            case .failed(_):
                StatusView(content: StatusView.Content.empty) {
                    Task { await viewModel.load() }
                }
            }
        }
        .background(.background)
        .task {
            await viewModel.load()
        }
    }
}

