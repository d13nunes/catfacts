import SwiftUI

struct FactsItemView: View {
  let fact: FactItem
  @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 18
  // Inline images sit on the baseline. Raising the text, rather than lowering the badges, centres the badges on the
  // capitals and adds the same height to every line; lowering the badges would make only the first line taller.
  @ScaledMetric(relativeTo: .body) private var textRaise: CGFloat = -3

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // The badges are part of the text, so they lead the first line and the text wraps under them.
      (badges + Text(fact.text))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(accessibilityLabel)
      Divider().background(.black)
    }
    .accessibilityElement(children: .combine)
  }

  private var badges: Text {
    var badges = Text(verbatim: "")
    if fact.isVerified {
      // Black line art, so render it as a template to follow the text colour in dark mode.
      badges = badges + badge("verified", renderingMode: .template)
    }
    if fact.isNew {
      badges = badges + badge("new", renderingMode: .original)
    }
    return badges
  }

  private func badge(_ name: String, renderingMode: Image.TemplateRenderingMode) -> Text {
    guard let image = UIImage(named: name) else { return Text(verbatim: "") }
    return Text(Image(uiImage: image).renderingMode(renderingMode)).font(.system(size: badgeSize)) + Text(verbatim: " ")
  }

  private var accessibilityLabel: String {
    var parts: [String] = []
    if fact.isVerified { parts.append(String(localized: "Verified")) }
    if fact.isNew { parts.append(String(localized: "New")) }
    parts.append(fact.text)
    return parts.joined(separator: ", ")
  }
}

#Preview {
  VStack {
    FactsItemView(fact: .init(
      id: "1",
      text: "Some random fact about a cat that does cat things and people love specially in the internet",
      isVerified: true,
      isNew: true)
    )
    FactsItemView(fact: .init(id: "2", text: "A verified fact.", isVerified: true, isNew: false))
    FactsItemView(fact: .init(id: "3", text: "A plain fact.", isVerified: false, isNew: false))
  }
}
