import SwiftUI

struct FactsItemView: View {
  let fact: FactItem
  @ScaledMetric private var badgeSize: CGFloat = 28

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(fact.text)
      if fact.isVerified || fact.isNew {
        HStack(spacing: 8) {
          if fact.isVerified {
            // Black line art, so render it as a template to follow the text colour in dark mode.
            Image("verified")
              .renderingMode(.template)
              .resizable()
              .frame(width: badgeSize, height: badgeSize)
              .accessibilityLabel(String(localized: "Verified"))
          }
          if fact.isNew {
            Image("new")
              .resizable()
              .frame(width: badgeSize, height: badgeSize)
              .accessibilityLabel(String(localized: "New"))
          }
        }
      }
      Divider().background(.black)
    }
    .padding(.horizontal)
    .accessibilityElement(children: .combine)
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
