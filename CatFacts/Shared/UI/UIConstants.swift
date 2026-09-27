import CoreGraphics

/// The app's spacing scale, in points, plus names for what the values are used for. Layouts use these instead of
/// literal numbers.
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    /// The space between the screen edges and its content.
    static let screenMargin = xl
    /// The space between rows in a list.
    static let rowSpacing = xl
}

/// Fixed sizes of UI elements, in points.
enum ComponentSize {
    static let badge: CGFloat = 28
    static let separatorLine: CGFloat = 1
}
