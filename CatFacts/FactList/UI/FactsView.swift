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
                        .readableContentWidth()
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

#if DEBUG
#Preview("Loading") { FactsPreview(.neverResponds) }
#Preview("Loaded") { FactsPreview(.facts(PreviewFactsRepository.sampleFacts)) }
#Preview("Search") { FactsPreview(.facts(PreviewFactsRepository.sampleFacts), query: "cats") }
#Preview("No results") { FactsPreview(.facts(PreviewFactsRepository.sampleFacts), query: "dogs") }
#Preview("Empty") { FactsPreview(.facts([])) }
#Preview("No connection") { FactsPreview(.failure(.connection)) }
#Preview("Server error") { FactsPreview(.failure(.server)) }

/// The fact list in the app's navigation stack, so the title and search bar show. The view model loads from a
/// repository that returns `response`, so each state comes from the real `load()`. It's a SwiftUI view because
/// `#Preview` only takes a view controller from iOS 17.
private struct FactsPreview: UIViewControllerRepresentable {
    let response: PreviewFactsRepository.Response
    var query = ""

    init(_ response: PreviewFactsRepository.Response, query: String = "") {
        self.response = response
        self.query = query
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewModel = FactsViewModel(repository: PreviewFactsRepository(response: response))
        viewModel.query = query
        return AppNavigationController(rootViewController: HostingViewController(rootView: FactsUI(viewModel: viewModel)))
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {}
}

private struct PreviewFactsRepository: CatFactsRepository {
    enum Response {
        case facts([CatFact])
        case failure(CatFactsError)
        /// Keeps the list loading.
        case neverResponds
    }

    static let sampleFacts = [
        CatFact(id: "1", text: "Cats can rotate each ear independently.", isVerified: true, createdAt: .now),
        CatFact(id: "2", text: "A group of cats is called a clowder.", isVerified: false, createdAt: .now),
        CatFact(id: "3", text: "Most cats sleep twelve to sixteen hours a day.", isVerified: true, createdAt: .distantPast),
        CatFact(id: "4", text: "A slow blink is a sign of trust.", isVerified: false, createdAt: .distantPast),
    ]

    let response: Response

    func fetchFacts() async throws -> [CatFact] {
        switch response {
        case .facts(let facts):
            return facts
        case .failure(let error):
            throw error
        case .neverResponds:
            try await Task.sleep(nanoseconds: .max)
            return []
        }
    }
}
#endif

