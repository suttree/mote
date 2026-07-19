import AppKit
import SwiftUI

@main
struct MoteApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let popover = NSPopover()
  private let settings = AppSettings()
  private lazy var dashboard = DashboardViewModel(
    settings: settings,
    musicService: MusicService(),
    weatherService: WeatherService(),
    calendarService: CalendarService()
  )
  private var statusItem: NSStatusItem?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)

    let content = DashboardView(viewModel: dashboard)
      .environmentObject(settings)
    popover.contentSize = NSSize(width: 380, height: 600)
    popover.contentViewController = MoteHostingController(rootView: content)
    popover.behavior = .transient
    popover.animates = true

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = statusItem.button {
      button.image = MenuBarIcon.statusItemImage
      button.imagePosition = .imageOnly
      button.toolTip = "mote"
      button.target = self
      button.action = #selector(togglePopover(_:))
    }
    self.statusItem = statusItem
  }

  @objc private func togglePopover(_ sender: NSStatusBarButton) {
    if popover.isShown {
      popover.close()
      return
    }

    NSApp.activate(ignoringOtherApps: true)
    popover.show(
      relativeTo: sender.bounds,
      of: sender,
      preferredEdge: .minY
    )

    DispatchQueue.main.async { [weak self] in
      guard let window = self?.popover.contentViewController?.view.window else {
        return
      }
      window.makeKey()
      self?.dashboard.requestPlaylistFocus()
    }
  }
}

private final class MoteHostingController<Content: View>: NSViewController {
  private let rootView: Content

  init(rootView: Content) {
    self.rootView = rootView
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  override func loadView() {
    view = FirstMouseHostingView(rootView: rootView)
  }
}

private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }
}
