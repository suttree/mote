import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
  private enum Key {
    static let playlistName = "playlistName"
  }

  private let defaults: UserDefaults

  let weatherLocationName = "SE18 6RU"
  let weatherLatitude = 51.494871
  let weatherLongitude = 0.073265

  @Published var playlistName: String {
    didSet { defaults.set(playlistName, forKey: Key.playlistName) }
  }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    playlistName = defaults.string(forKey: Key.playlistName) ?? ""
  }
}
