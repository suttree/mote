import EventKit
import XCTest

@testable import Mote

final class MoteTests: XCTestCase {
  func testAppleScriptQuotingEscapesUnsafeCharacters() {
    XCTAssertEqual(
      AppleScriptText.quoted("A \"quoted\" path\\name\nnext"),
      "\"A \\\"quoted\\\" path\\\\name next\""
    )
  }

  func testWeatherPresentationMapsRepresentativeCodes() {
    XCTAssertEqual(WeatherPresentation.summary(for: 0), "Clear")
    XCTAssertEqual(WeatherPresentation.symbol(for: 63), "cloud.rain.fill")
    XCTAssertEqual(WeatherPresentation.summary(for: 95), "Thunderstorms")
    XCTAssertEqual(WeatherPresentation.symbol(for: -1), "cloud.fill")
  }

  func testCalendarPermissionIsOnlyRequestedWhenUndetermined() {
    XCTAssertEqual(
      CalendarService.authorizationDecision(for: .notDetermined),
      .requestAccess
    )
    XCTAssertEqual(
      CalendarService.authorizationDecision(for: .fullAccess),
      .useExistingAccess
    )
    XCTAssertEqual(
      CalendarService.authorizationDecision(for: .denied),
      .denyAccess
    )
  }

  @MainActor
  func testSettingsUsePersonalDefaults() {
    let suiteName = "MoteTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettings(defaults: defaults)

    XCTAssertEqual(settings.weatherLocationName, "SE18 6RU")
    XCTAssertEqual(settings.weatherLatitude, 51.494871, accuracy: 0.0001)
    XCTAssertEqual(settings.weatherLongitude, 0.073265, accuracy: 0.0001)
  }
}
