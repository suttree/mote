import Foundation

struct WeatherService {
  private struct Response: Decodable {
    let daily: Daily
  }

  private struct Daily: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperatureMax: [Double]
    let temperatureMin: [Double]

    enum CodingKeys: String, CodingKey {
      case time
      case weatherCode = "weather_code"
      case temperatureMax = "temperature_2m_max"
      case temperatureMin = "temperature_2m_min"
    }
  }

  func forecast(latitude: Double, longitude: Double) async throws -> [WeatherDay] {
    var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
    components?.queryItems = [
      URLQueryItem(name: "latitude", value: String(latitude)),
      URLQueryItem(name: "longitude", value: String(longitude)),
      URLQueryItem(
        name: "daily",
        value: "weather_code,temperature_2m_max,temperature_2m_min"
      ),
      URLQueryItem(name: "timezone", value: "auto"),
      URLQueryItem(name: "forecast_days", value: "3"),
    ]

    guard let url = components?.url else {
      throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
      (200..<300).contains(httpResponse.statusCode)
    else {
      throw URLError(.badServerResponse)
    }

    let decoded = try JSONDecoder().decode(Response.self, from: data)
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"

    let count = min(
      decoded.daily.time.count,
      decoded.daily.weatherCode.count,
      decoded.daily.temperatureMax.count,
      decoded.daily.temperatureMin.count
    )

    return (0..<count).compactMap { index in
      guard let date = formatter.date(from: decoded.daily.time[index]) else {
        return nil
      }
      return WeatherDay(
        date: date,
        high: decoded.daily.temperatureMax[index],
        low: decoded.daily.temperatureMin[index],
        weatherCode: decoded.daily.weatherCode[index]
      )
    }
  }
}
