import SwiftUI

struct FactsItemView: View {
  let fact: FactItem
  /// Words to highlight in the fact's text, matched like the search: each word, ignoring case and diacritics.
  /// nil or blank highlights nothing.
  var highlight: String? = nil
  @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 28

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // The badges are part of the text, so they lead the first line and the text wraps under them.
      (badges + Text(highlightedText))
        .frame(maxWidth: .infinity, alignment: .leading)
      Divider().background(.black)
    }
  }

  private var highlightedText: AttributedString {
    var text = AttributedString(fact.text)
    guard let highlight else { return text }
    for term in highlight.split(whereSeparator: \.isWhitespace) {
      var searchStart = text.startIndex
      while let range = text[searchStart...].range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) {
        text[range].foregroundColor = Color.blue
        searchStart = range.upperBound
      }
    }
    return text
  }

  private var badges: Text {
    var badges = Text(verbatim: "")
    if fact.isNew {
      badges = badges + badge("new", renderingMode: .original, tint: .red)
    }
    if fact.isVerified {
      badges = badges + badge("verified", renderingMode: .template, tint: .blue)
    }
    return badges
  }

  private func badge(_ name: String, renderingMode: Image.TemplateRenderingMode, tint: Color? = nil) -> Text {
    guard let image = UIImage(named: name)?.resized(to: badgeSize) else { return Text(verbatim: "") }
    var text = Text(Image(uiImage: image).renderingMode(renderingMode))
    if let tint = tint {
      if #available(iOS 17.0, *) {
        text = text.foregroundStyle(tint)
      } else {
        text = text.foregroundColor(tint)
      }
    }
    return text + Text(verbatim: " ")
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
    FactsItemView(fact: .init(id: "4", text: "Cats sleep, and cats purr.", isVerified: false, isNew: false), highlight: "CAT purr")
  }
}
