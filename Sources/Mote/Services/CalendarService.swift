import EventKit
import Foundation

@MainActor
final class CalendarService {
  private let store = EKEventStore()

  func upcomingEvents(
    from startDate: Date = Date(),
    hours: Int = 72,
    limit: Int = 6
  ) async throws -> [CalendarEventItem] {
    switch Self.authorizationDecision(
      for: EKEventStore.authorizationStatus(for: .event)
    ) {
    case .useExistingAccess:
      break
    case .requestAccess:
      guard try await store.requestFullAccessToEvents() else {
        throw CalendarServiceError.accessDenied
      }
    case .denyAccess:
      throw CalendarServiceError.accessDenied
    }

    let endDate =
      Calendar.current.date(
        byAdding: .hour,
        value: hours,
        to: startDate
      ) ?? startDate.addingTimeInterval(TimeInterval(hours * 3600))

    let predicate = store.predicateForEvents(
      withStart: startDate,
      end: endDate,
      calendars: nil
    )

    return store.events(matching: predicate)
      .sorted { $0.startDate < $1.startDate }
      .prefix(limit)
      .map {
        CalendarEventItem(
          id: $0.eventIdentifier ?? UUID().uuidString,
          title: $0.title ?? "Untitled event",
          location: $0.location,
          startDate: $0.startDate,
          endDate: $0.endDate,
          isAllDay: $0.isAllDay
        )
      }
  }

  nonisolated static func authorizationDecision(
    for status: EKAuthorizationStatus
  ) -> CalendarAuthorizationDecision {
    switch status {
    case .notDetermined:
      return .requestAccess
    case .fullAccess:
      return .useExistingAccess
    case .restricted, .denied, .writeOnly:
      return .denyAccess
    @unknown default:
      return .denyAccess
    }
  }
}

enum CalendarAuthorizationDecision: Equatable {
  case useExistingAccess
  case requestAccess
  case denyAccess
}

enum CalendarServiceError: LocalizedError {
  case accessDenied

  var errorDescription: String? {
    "Calendar access is turned off. Enable it in System Settings."
  }
}
