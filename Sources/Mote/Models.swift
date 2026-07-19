import Foundation

struct WeatherDay: Identifiable, Equatable, Sendable {
  let date: Date
  let high: Double
  let low: Double
  let weatherCode: Int

  var id: Date { date }

  var symbolName: String {
    WeatherPresentation.symbol(for: weatherCode)
  }

  var summary: String {
    WeatherPresentation.summary(for: weatherCode)
  }
}

enum WeatherPresentation {
  static func symbol(for code: Int) -> String {
    switch code {
    case 0:
      return "sun.max.fill"
    case 1, 2:
      return "cloud.sun.fill"
    case 3:
      return "cloud.fill"
    case 45, 48:
      return "cloud.fog.fill"
    case 51, 53, 55, 56, 57:
      return "cloud.drizzle.fill"
    case 61, 63, 65, 66, 67, 80, 81, 82:
      return "cloud.rain.fill"
    case 71, 73, 75, 77, 85, 86:
      return "cloud.snow.fill"
    case 95, 96, 99:
      return "cloud.bolt.rain.fill"
    default:
      return "cloud.fill"
    }
  }

  static func summary(for code: Int) -> String {
    switch code {
    case 0:
      return "Clear"
    case 1, 2:
      return "Partly cloudy"
    case 3:
      return "Cloudy"
    case 45, 48:
      return "Fog"
    case 51, 53, 55, 56, 57:
      return "Drizzle"
    case 61, 63, 65, 66, 67, 80, 81, 82:
      return "Rain"
    case 71, 73, 75, 77, 85, 86:
      return "Snow"
    case 95, 96, 99:
      return "Thunderstorms"
    default:
      return "Mixed"
    }
  }
}

struct CalendarEventItem: Identifiable, Equatable, Sendable {
  let id: String
  let title: String
  let location: String?
  let startDate: Date
  let endDate: Date
  let isAllDay: Bool
}

enum PlaybackState: String, Equatable, Sendable {
  case playing
  case paused
  case stopped
  case unavailable
}

struct NowPlaying: Equatable, Sendable {
  var title: String
  var artist: String
  var state: PlaybackState

  static let empty = NowPlaying(
    title: "Nothing playing",
    artist: "Choose a playlist",
    state: .stopped
  )
}

enum ProviderState: Equatable, Sendable {
  case idle
  case loading
  case ready
  case message(String)
}
