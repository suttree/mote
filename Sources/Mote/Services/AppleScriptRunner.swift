import AppKit
import Foundation

enum AppleScriptError: LocalizedError {
  case compilationFailed
  case executionFailed(message: String, number: Int?)

  var errorDescription: String? {
    switch self {
    case .compilationFailed:
      return "The AppleScript could not be compiled."
    case .executionFailed(let message, let number):
      if let number {
        return "\(message) (AppleScript error \(number))"
      }
      return message
    }
  }
}

struct AppleScriptRunner {
  func run(_ source: String) throws -> String {
    try execute(source).stringValue ?? ""
  }

  private func execute(_ source: String) throws -> NSAppleEventDescriptor {
    guard let script = NSAppleScript(source: source) else {
      throw AppleScriptError.compilationFailed
    }

    var errorInfo: NSDictionary?
    let descriptor = script.executeAndReturnError(&errorInfo)

    if let errorInfo {
      let message =
        errorInfo[NSAppleScript.errorMessage] as? String
        ?? "An AppleScript command failed."
      let number = errorInfo[NSAppleScript.errorNumber] as? Int
      throw AppleScriptError.executionFailed(message: message, number: number)
    }

    return descriptor
  }
}

enum AppleScriptText {
  static func quoted(_ value: String) -> String {
    let escaped =
      value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "\r", with: " ")
      .replacingOccurrences(of: "\n", with: " ")
    return "\"\(escaped)\""
  }
}
