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

  func testSmallSeasonsTrackRecurringDatesAndWrapTheYear() throws {
    let service = SmallSeasonsService(
      ics: """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20181222
        DESCRIPTION:冬至・Tōji・Winter Solstice<br><br>Shortest days.
        END:VEVENT
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20190106
        DESCRIPTION:小寒・Shōkan・Small Cold<br><br>The cold deepens.
        END:VEVENT
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20190723
        DESCRIPTION:大暑・Taisho・Big
          Heat<br><br>The hottest days.
        END:VEVENT
        END:VCALENDAR
        """
    )
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

    let januaryThird = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 1, day: 3))
    )
    let januarySixth = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 1, day: 6))
    )
    let julyTwentyFourth = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 7, day: 24))
    )

    XCTAssertEqual(
      service.season(on: januaryThird, calendar: calendar)?.text,
      "冬至・Tōji・Winter Solstice"
    )
    XCTAssertEqual(
      service.season(on: januarySixth, calendar: calendar)?.text,
      "小寒・Shōkan・Small Cold"
    )
    XCTAssertEqual(
      service.season(on: julyTwentyFourth, calendar: calendar)?.text,
      "大暑・Taisho・Big Heat"
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
