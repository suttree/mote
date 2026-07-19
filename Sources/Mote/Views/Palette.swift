import AppKit
import SwiftUI

enum MotePalette {
  static let dots = Color(red: 0.612, green: 0.573, blue: 0.675)
  static let peach = Color(red: 1.000, green: 0.855, blue: 0.757)
  static let cyan = Color(red: 0.796, green: 1.000, blue: 0.980)
  static let yellow = Color(red: 1.000, green: 0.976, blue: 0.753)
  static let ink = Color(red: 0.047, green: 0.212, blue: 0.376)

  static func canvas(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color(red: 0.075, green: 0.082, blue: 0.094)
      : Color(nsColor: .windowBackgroundColor)
  }
}

enum MoteTypography {
  static let headline = Font.system(size: 14, weight: .semibold)
  static let body = Font.system(size: 14)
  static let subheadline = Font.system(size: 12)
  static let subheadlineSemibold = Font.system(size: 12, weight: .semibold)
  static let caption = Font.system(size: 11)
  static let control = Font.system(size: 12, weight: .medium)
}

struct DotPattern: View {
  let background: Color

  var body: some View {
    Canvas { context, size in
      context.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .color(background)
      )

      let spacing: CGFloat = 6
      for y in stride(from: CGFloat(2), to: size.height, by: spacing) {
        for x in stride(from: CGFloat(2), to: size.width, by: spacing) {
          let offset = Int(y / spacing).isMultiple(of: 2) ? 0 : spacing / 2
          let rect = CGRect(x: x + offset, y: y, width: 1, height: 1)
          context.fill(
            Path(rect),
            with: .color(MotePalette.dots.opacity(0.18))
          )
        }
      }
    }
    .accessibilityHidden(true)
  }
}

struct PastelCard<Content: View>: View {
  let color: Color
  @ViewBuilder let content: Content

  var body: some View {
    content
      .foregroundStyle(MotePalette.ink)
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        DotPattern(background: color)
          .clipShape(shape)
          .overlay {
            shape.stroke(.white.opacity(0.45), lineWidth: 1)
          }
      }
  }
}
