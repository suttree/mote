import Foundation

struct SmallSeason: Equatable, Sendable {
  let month: Int
  let day: Int
  let text: String

  fileprivate var monthDayKey: Int {
    month * 100 + day
  }
}

struct SmallSeasonsService: Sendable {
  private let seasons: [SmallSeason]

  init(bundle: Bundle = .main) {
    let contents = bundle.url(
      forResource: "smallseasons",
      withExtension: "ics"
    ).flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
    self.init(ics: contents)
  }

  init(ics: String) {
    seasons = Self.parse(ics).sorted {
      $0.monthDayKey < $1.monthDayKey
    }
  }

  func season(
    on date: Date,
    calendar: Calendar = .current
  ) -> SmallSeason? {
    guard !seasons.isEmpty else { return nil }
    let components = calendar.dateComponents([.month, .day], from: date)
    guard let month = components.month, let day = components.day else {
      return nil
    }

    let key = month * 100 + day
    return seasons.last(where: { $0.monthDayKey <= key }) ?? seasons.last
  }

  private static func parse(_ ics: String) -> [SmallSeason] {
    var seasons: [SmallSeason] = []
    var startDate: String?
    var description: String?
    var isInsideEvent = false

    for line in unfoldedLines(in: ics) {
      switch line {
      case "BEGIN:VEVENT":
        isInsideEvent = true
        startDate = nil
        description = nil
      case "END:VEVENT":
        if isInsideEvent,
          let startDate,
          let description,
          let season = makeSeason(
            startDate: startDate,
            description: description
          )
        {
          seasons.append(season)
        }
        isInsideEvent = false
      default:
        guard isInsideEvent else { continue }
        if line.hasPrefix("DTSTART"),
          let separator = line.firstIndex(of: ":")
        {
          startDate = String(line[line.index(after: separator)...])
        } else if line.hasPrefix("DESCRIPTION:") {
          description = String(line.dropFirst("DESCRIPTION:".count))
        }
      }
    }

    return seasons
  }

  private static func unfoldedLines(in ics: String) -> [String] {
    let normalized = ics
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
    var lines: [String] = []

    for rawLine in normalized.split(
      separator: "\n",
      omittingEmptySubsequences: false
    ) {
      let line = String(rawLine)
      if (line.hasPrefix(" ") || line.hasPrefix("\t")), !lines.isEmpty {
        lines[lines.count - 1] += line.dropFirst()
      } else {
        lines.append(line)
      }
    }

    return lines
  }

  private static func makeSeason(
    startDate: String,
    description: String
  ) -> SmallSeason? {
    guard startDate.count >= 8,
      let month = Int(startDate.dropFirst(4).prefix(2)),
      let day = Int(startDate.dropFirst(6).prefix(2))
    else {
      return nil
    }

    let firstParagraph = description
      .components(separatedBy: "<br><br>")
      .first ?? description
    let text = firstParagraph
      .replacingOccurrences(of: "\\,", with: ",")
      .replacingOccurrences(of: "\\;", with: ";")
      .replacingOccurrences(of: "\\n", with: " ")
      .replacingOccurrences(of: "\\\\", with: "\\")

    guard !text.isEmpty else { return nil }
    return SmallSeason(month: month, day: day, text: text)
  }
}
