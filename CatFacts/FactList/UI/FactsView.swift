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
                        LazyVStack(spacing: 24) {
                            ForEach(facts, id: \.id) { fact in
                                FactsItemView(fact: fact, highlight: viewModel.query)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                    }
                    .id(viewModel.query)
                    .navigationSearchBar(text: $viewModel.query, placeholder: "Search facts")
                }
            case .empty:
                StatusView(content: StatusView.Content.empty) {
                    Task { await viewModel.load() }
                }
            case .failed(let error):
                StatusView(content: StatusView.Content.failure(error)) {
                    Task { await viewModel.load() }
                }
            }
        }
        .background(.background)
        .navigationItemTitle("Cat Facts")
        .task {
            await viewModel.load()
        }
    }
}

