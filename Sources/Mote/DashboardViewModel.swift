import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
  @Published private(set) var playlists: [String] = []
  @Published private(set) var selectedPlaylist: String
  @Published private(set) var nowPlaying: NowPlaying = .empty
  @Published private(set) var weatherDays: [WeatherDay] = []
  @Published private(set) var calendarEvents: [CalendarEventItem] = []
  @Published private(set) var smallSeasonText: String?

  @Published private(set) var musicState: ProviderState = .idle
  @Published private(set) var weatherState: ProviderState = .idle
  @Published private(set) var calendarState: ProviderState = .idle
  @Published private(set) var isRefreshing = false
  @Published private(set) var isChangingPlaylist = false
  @Published private(set) var playlistFocusRequest = 0
  @Published private(set) var lastUpdated: Date?

  private let settings: AppSettings
  private let musicService: MusicService
  private let weatherService: WeatherService
  private let calendarService: CalendarService
  private let smallSeasonsService: SmallSeasonsService
  private var refreshTask: Task<Void, Never>?
  private var playlistChangeTask: Task<Void, Never>?

  init(
    settings: AppSettings,
    musicService: MusicService,
    weatherService: WeatherService,
    calendarService: CalendarService,
    smallSeasonsService: SmallSeasonsService
  ) {
    self.settings = settings
    self.musicService = musicService
    self.weatherService = weatherService
    self.calendarService = calendarService
    self.smallSeasonsService = smallSeasonsService
    selectedPlaylist = settings.playlistName
  }

  func startLoadingIfNeeded() {
    guard lastUpdated == nil else {
      refreshNowPlaying()
      return
    }
    guard refreshTask == nil else { return }

    refreshTask = Task { [weak self] in
      await self?.refreshAll()
      self?.refreshTask = nil
    }
  }

  func refreshAll() async {
    guard !isRefreshing else { return }
    isRefreshing = true
    defer {
      isRefreshing = false
      lastUpdated = Date()
    }

    smallSeasonText = smallSeasonsService.season(on: Date())?.text
    loadMusic()

    weatherState = .loading
    do {
      weatherDays = try await weatherService.forecast(
        latitude: settings.weatherLatitude,
        longitude: settings.weatherLongitude
      )
      weatherState =
        weatherDays.isEmpty
        ? .message("No forecast was returned.")
        : .ready
    } catch {
      weatherState = .message("Weather unavailable: \(error.localizedDescription)")
    }

    calendarState = .loading
    do {
      calendarEvents = try await calendarService.upcomingEvents()
      calendarState =
        calendarEvents.isEmpty
        ? .message("Nothing scheduled in the next 72 hours.")
        : .ready
    } catch {
      calendarState = .message(error.localizedDescription)
    }
  }

  func selectPlaylist(_ name: String) {
    guard !name.isEmpty else { return }
    selectedPlaylist = name
    settings.playlistName = name
    musicState = .loading
    isChangingPlaylist = true
    playlistChangeTask?.cancel()

    playlistChangeTask = Task { [weak self] in
      guard let self else { return }
      await Task.yield()

      do {
        try musicService.playShuffled(playlist: name)
        try await Task.sleep(for: .milliseconds(300))
        nowPlaying = try await nowPlayingAfterPlaylistChange()
        guard !Task.isCancelled else { return }
        musicState = .ready
      } catch is CancellationError {
        return
      } catch {
        musicState = .message("Music unavailable: \(error.localizedDescription)")
      }

      if selectedPlaylist == name {
        isChangingPlaylist = false
      }
    }
  }

  func requestPlaylistFocus() {
    playlistFocusRequest += 1
  }

  func togglePlayback() {
    do {
      try musicService.togglePlayPause()
      nowPlaying = try musicService.nowPlaying()
      musicState = .ready
    } catch {
      musicState = .message("Music unavailable: \(error.localizedDescription)")
    }
  }

  func nextTrack() {
    do {
      try musicService.nextTrack()
      nowPlaying = try musicService.nowPlaying()
      musicState = .ready
    } catch {
      musicState = .message("Music unavailable: \(error.localizedDescription)")
    }
  }

  func refreshNowPlaying() {
    guard musicState != .loading else { return }
    do {
      nowPlaying = try musicService.nowPlaying()
      if case .message = musicState {
        return
      }
      musicState = .ready
    } catch {
      musicState = .message("Music unavailable: \(error.localizedDescription)")
    }
  }

  private func loadMusic() {
    musicState = .loading
    do {
      playlists = try musicService.playlists()
      if !playlists.contains(selectedPlaylist) {
        selectedPlaylist = playlists.first ?? ""
        settings.playlistName = selectedPlaylist
      }
      nowPlaying = try musicService.nowPlaying()
      musicState =
        playlists.isEmpty
        ? .message("No visible Music playlists were found.")
        : .ready
    } catch {
      musicState = .message("Music unavailable: \(error.localizedDescription)")
    }
  }

  private func nowPlayingAfterPlaylistChange() async throws -> NowPlaying {
    for attempt in 0..<5 {
      do {
        return try musicService.nowPlaying()
      } catch {
        guard attempt < 4 else { throw error }
        try await Task.sleep(for: .milliseconds(250))
      }
    }
    return .empty
  }
}
