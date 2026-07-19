import AppKit

enum MenuBarIcon {
  static let image: NSImage = {
    let image =
      Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png")
      .flatMap(NSImage.init(contentsOf:))
      ?? NSImage(systemSymbolName: "sparkles", accessibilityDescription: "mote")
      ?? NSImage()

    image.isTemplate = true
    return image
  }()

  static let statusItemImage: NSImage = {
    let image = (MenuBarIcon.image.copy() as? NSImage) ?? MenuBarIcon.image
    let aspectRatio = image.size.width / image.size.height
    image.size = NSSize(width: 21 * aspectRatio, height: 21)
    image.isTemplate = true
    return image
  }()
}
