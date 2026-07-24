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
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  private let popover = NSPopover()
  private let settings = AppSettings()
  private lazy var dashboard = DashboardViewModel(
    settings: settings,
    musicService: MusicService(),
    weatherService: WeatherService(),
    calendarService: CalendarService(),
    smallSeasonsService: SmallSeasonsService()
  )
  private var statusItem: NSStatusItem?
  private var outsideClickMonitor: Any?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)

    let content = DashboardView(viewModel: dashboard)
      .environmentObject(settings)
    popover.contentSize = NSSize(width: 380, height: 620)
    popover.contentViewController = MoteHostingController(rootView: content)
    popover.behavior = .transient
    popover.animates = true
    popover.delegate = self

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
    startOutsideClickMonitor()

    DispatchQueue.main.async { [weak self] in
      guard let window = self?.popover.contentViewController?.view.window else {
        return
      }
      window.makeKey()
      self?.dashboard.requestPlaylistFocus()
    }
  }

  func popoverDidClose(_ notification: Notification) {
    stopOutsideClickMonitor()
  }

  func applicationWillTerminate(_ notification: Notification) {
    stopOutsideClickMonitor()
  }

  private func startOutsideClickMonitor() {
    stopOutsideClickMonitor()
    outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
    ) { [weak self] _ in
      Task { @MainActor in
        self?.popover.close()
      }
    }
  }

  private func stopOutsideClickMonitor() {
    guard let outsideClickMonitor else { return }
    NSEvent.removeMonitor(outsideClickMonitor)
    self.outsideClickMonitor = nil
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
