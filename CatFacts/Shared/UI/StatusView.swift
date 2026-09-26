import SwiftUI

struct StatusView: View {
    struct Content: Equatable {
        let symbolName: String
        let title: String
        let message: String
        let actionTitle: String?
    }

    let content: Content
    var onAction: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: content.symbolName)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(content.title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(content.message)
                .foregroundStyle(.secondary)
            if let actionTitle = content.actionTitle {
                Button(actionTitle, action: onAction)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .padding(.top, 12)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
