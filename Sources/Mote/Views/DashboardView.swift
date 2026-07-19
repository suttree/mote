import AppKit
import SwiftUI

struct DashboardView: View {
  @ObservedObject var viewModel: DashboardViewModel
  @EnvironmentObject private var settings: AppSettings
  @Environment(\.colorScheme) private var colorScheme

  private let nowPlayingTimer = Timer.publish(
    every: 5,
    on: .main,
    in: .common
  ).autoconnect()

  var body: some View {
    ZStack {
      MotePalette.canvas(for: colorScheme)

      ScrollView {
        VStack(spacing: 10) {
          header

          MusicCard(viewModel: viewModel)
          WeatherCard(
            locationName: settings.weatherLocationName,
            days: viewModel.weatherDays,
            state: viewModel.weatherState
          )
          CalendarCard(
            events: viewModel.calendarEvents,
            state: viewModel.calendarState
          )

          footer
        }
        .padding(12)
      }
      .scrollIndicators(.never)
    }
    .frame(width: 380, height: 600)
    .onAppear {
      viewModel.startLoadingIfNeeded()
    }
    .onReceive(nowPlayingTimer) { _ in
      viewModel.refreshNowPlaying()
    }
  }

  private var header: some View {
    HStack(spacing: 10) {
      Image(nsImage: MenuBarIcon.image)
        .resizable()
        .scaledToFit()
        .foregroundStyle(MotePalette.ink)
        .frame(width: 22, height: 22)
        .frame(width: 34, height: 34)
        .background(
          MotePalette.cyan,
          in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )

      VStack(alignment: .leading, spacing: 2) {
        Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
          .font(MoteTypography.headline)
        Text(lastUpdatedText)
          .font(MoteTypography.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 2)
  }

  private var footer: some View {
    HStack {
      Button {
        Task { await viewModel.refreshAll() }
      } label: {
        Label("Refresh", systemImage: "arrow.clockwise")
      }
      .buttonStyle(.plain)
      .disabled(viewModel.isRefreshing)

      Spacer()

      Button("Quit") {
        NSApp.terminate(nil)
      }
      .buttonStyle(.plain)
    }
    .font(MoteTypography.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 4)
    .padding(.vertical, 2)
  }

  private var lastUpdatedText: String {
    guard let date = viewModel.lastUpdated else {
      return "Next three days"
    }
    return "Next three days · updated \(date.formatted(date: .omitted, time: .shortened))"
  }
}
