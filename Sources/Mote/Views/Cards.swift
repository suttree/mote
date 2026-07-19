import SwiftUI

struct MusicCard: View {
  @ObservedObject var viewModel: DashboardViewModel
  @FocusState private var isPlaylistPickerFocused: Bool

  var body: some View {
    PastelCard(color: MotePalette.peach) {
      VStack(alignment: .leading, spacing: 11) {
        cardHeader(
          title: "Music",
          systemImage: "music.note",
          trailing: "Shuffle"
        )

        if viewModel.playlists.isEmpty {
          statusView(viewModel.musicState)
        } else {
          ZStack(alignment: .trailing) {
            Picker(
              "Playlist",
              selection: Binding(
                get: { viewModel.selectedPlaylist },
                set: { viewModel.selectPlaylist($0) }
              )
            ) {
              ForEach(viewModel.playlists, id: \.self) { playlist in
                Text(playlist).tag(playlist)
              }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .font(MoteTypography.body)
            .frame(maxWidth: .infinity)
            .disabled(viewModel.isChangingPlaylist)
            .focused($isPlaylistPickerFocused)

            if viewModel.isChangingPlaylist {
              ProgressView()
                .controlSize(.small)
                .padding(.trailing, 36)
                .allowsHitTesting(false)
                .accessibilityLabel("Changing playlist")
            }
          }
          .onAppear {
            isPlaylistPickerFocused = true
          }
          .onChange(of: viewModel.playlistFocusRequest) {
            isPlaylistPickerFocused = true
          }

          VStack(alignment: .leading, spacing: 3) {
            Text(viewModel.nowPlaying.title)
              .font(MoteTypography.headline)
              .lineLimit(1)
            Text(viewModel.nowPlaying.artist)
              .font(MoteTypography.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)

            HStack(spacing: 7) {
              Button {
                viewModel.togglePlayback()
              } label: {
                Label(
                  viewModel.nowPlaying.state == .playing ? "Pause" : "Play",
                  systemImage: viewModel.nowPlaying.state == .playing
                    ? "pause.fill"
                    : "play.fill"
                )
              }
              .buttonStyle(.borderedProminent)
              .controlSize(.small)
              .font(MoteTypography.control)
              .tint(MotePalette.ink)

              Button {
                viewModel.nextTrack()
              } label: {
                Label("Next", systemImage: "forward.fill")
              }
              .buttonStyle(.bordered)
              .controlSize(.small)
              .font(MoteTypography.control)
            }
            .padding(.top, 4)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        if case .message(let message) = viewModel.musicState,
          !viewModel.playlists.isEmpty
        {
          Text(message)
            .font(MoteTypography.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

}

struct WeatherCard: View {
  let locationName: String
  let days: [WeatherDay]
  let state: ProviderState

  var body: some View {
    PastelCard(color: MotePalette.cyan) {
      VStack(alignment: .leading, spacing: 11) {
        cardHeader(
          title: "Weather",
          systemImage: "cloud.sun.fill",
          trailing: locationName
        )

        if days.isEmpty {
          statusView(state)
        } else {
          HStack(alignment: .top, spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
              VStack(alignment: .leading, spacing: 5) {
                Text(dayLabel(day.date, index: index))
                  .font(MoteTypography.subheadlineSemibold)
                Label(
                  "\(day.high.roundedInt)°",
                  systemImage: day.symbolName
                )
                .font(MoteTypography.headline)
                Text("\(day.summary) · \(day.low.roundedInt)°")
                  .font(MoteTypography.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                  .minimumScaleFactor(0.8)
              }
              .frame(maxWidth: .infinity, alignment: .leading)

              if index < days.count - 1 {
                Divider()
                  .padding(.horizontal, 8)
              }
            }
          }
        }
      }
    }
  }

  private func dayLabel(_ date: Date, index: Int) -> String {
    if index == 0 {
      return "Today"
    }
    return date.formatted(.dateTime.weekday(.abbreviated))
  }
}

struct CalendarCard: View {
  let events: [CalendarEventItem]
  let state: ProviderState

  var body: some View {
    PastelCard(color: MotePalette.yellow) {
      VStack(alignment: .leading, spacing: 11) {
        cardHeader(
          title: "Coming up",
          systemImage: "calendar",
          trailing: "72 hours"
        )

        if events.isEmpty {
          statusView(state)
        } else {
          VStack(spacing: 10) {
            ForEach(events) { event in
              HStack(alignment: .top, spacing: 9) {
                Text(eventTime(event))
                  .font(MoteTypography.caption.monospacedDigit())
                  .foregroundStyle(.secondary)
                  .frame(width: 52, alignment: .leading)

                Circle()
                  .fill(MotePalette.dots)
                  .frame(width: 7, height: 7)
                  .padding(.top, 4)

                VStack(alignment: .leading, spacing: 2) {
                  Text(event.title)
                    .font(MoteTypography.subheadlineSemibold)
                    .lineLimit(1)
                  if let location = event.location,
                    !location.isEmpty
                  {
                    Text(location)
                      .font(MoteTypography.caption)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                  }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
        }
      }
    }
  }

  private func eventTime(_ event: CalendarEventItem) -> String {
    if event.isAllDay {
      return event.startDate.formatted(.dateTime.weekday(.abbreviated)) + "\nAll day"
    }
    if Calendar.current.isDateInToday(event.startDate) {
      return event.startDate.formatted(date: .omitted, time: .shortened)
    }
    return event.startDate.formatted(.dateTime.weekday(.abbreviated))
      + "\n"
      + event.startDate.formatted(date: .omitted, time: .shortened)
  }
}

@ViewBuilder
private func cardHeader(
  title: String,
  systemImage: String,
  trailing: String
) -> some View {
  HStack {
    Label(title, systemImage: systemImage)
      .font(MoteTypography.headline)
    Spacer()
    Text(trailing)
      .font(MoteTypography.caption)
      .foregroundStyle(.secondary)
  }
}

@ViewBuilder
private func statusView(_ state: ProviderState) -> some View {
  switch state {
  case .idle:
    Text("Waiting to refresh…")
      .font(MoteTypography.caption)
      .foregroundStyle(.secondary)
  case .loading:
    HStack(spacing: 7) {
      ProgressView()
        .controlSize(.small)
      Text("Loading…")
        .font(MoteTypography.caption)
        .foregroundStyle(.secondary)
    }
  case .ready:
    EmptyView()
  case .message(let message):
    Text(message)
      .font(MoteTypography.caption)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
  }
}

extension Double {
  fileprivate var roundedInt: Int {
    Int(rounded())
  }
}
