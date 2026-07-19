import Foundation

@MainActor
final class MusicService {
  private let runner: AppleScriptRunner

  init(runner: AppleScriptRunner = AppleScriptRunner()) {
    self.runner = runner
  }

  func playlists() throws -> [String] {
    let source = """
      tell application "Music"
          set playlistNames to name of every user playlist whose visible is true
          set AppleScript's text item delimiters to linefeed
          return playlistNames as text
      end tell
      """

    return try runner.run(source)
      .split(whereSeparator: \.isNewline)
      .map(String.init)
      .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      .uniqued()
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
  }

  func nowPlaying() throws -> NowPlaying {
    let source = """
      tell application "Music"
          set stateText to player state as text
          if stateText is "stopped" then
              return stateText & tab & "" & tab & ""
          end if
          return stateText & tab & (name of current track) & tab & (artist of current track)
      end tell
      """

    let parts = try runner.run(source)
      .split(separator: "\t", omittingEmptySubsequences: false)
      .map(String.init)

    guard parts.count >= 3 else {
      return .empty
    }

    let state = PlaybackState(rawValue: parts[0]) ?? .unavailable
    let title = parts[1].isEmpty ? "Nothing playing" : parts[1]
    let artist = parts[2].isEmpty ? "Choose a playlist" : parts[2]
    return NowPlaying(title: title, artist: artist, state: state)
  }

  func playShuffled(playlist name: String) throws {
    let playlistName = AppleScriptText.quoted(name)
    let source = """
      tell application "Music"
          set targetPlaylist to first user playlist whose name is \(playlistName)
          set shuffle mode to songs
          set shuffle enabled to true
          play targetPlaylist
      end tell
      """
    _ = try runner.run(source)
  }

  func togglePlayPause() throws {
    _ = try runner.run(
      """
      tell application "Music"
          playpause
      end tell
      """
    )
  }

  func nextTrack() throws {
    _ = try runner.run(
      """
      tell application "Music"
          next track
      end tell
      """
    )
  }
}

extension Sequence where Element: Hashable {
  fileprivate func uniqued() -> [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}
