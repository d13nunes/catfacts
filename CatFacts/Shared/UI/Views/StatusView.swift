import SwiftUI

struct StatusView: View {
    struct Content {
        let symbolName: String
        let title: String
        let message: String
        let actionTitle: String?
    }

    let content: Content
    var onAction: () -> Void = {}

    var body: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: content.symbolName)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(content.title)
                .font(.headline)
            Text(content.message)
                .foregroundStyle(.secondary)
            if let actionTitle = content.actionTitle {
                Button(actionTitle, action: onAction)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .padding(.top, Spacing.m)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
