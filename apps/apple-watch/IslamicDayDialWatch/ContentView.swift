import SwiftUI

struct ContentView: View {
    @State private var snapshot: ComputedIslamicDay?
    @State private var now = Date()
    @State private var location: Location = .mecca

    var body: some View {
        Group {
            if let snap = snapshot {
                ZStack {
                    RingView(snapshot: snap)
                    VStack(spacing: 2) {
                        currentPeriodView(snapshot: snap, now: now)
                        let parts = formatHijriDateParts(snap.hijriDate)
                        Text(parts.dayMonth)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : .primary)
                            .offset(y: 2)
                        Text(parts.year)
                            .font(.system(size: 10))
                            .foregroundColor(Colors.ivory)
                            .offset(y: 2)
                        Text(formatCountdown(countdownMs(snapshot: snap)))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Colors.ivory)
                            .padding(.top, 14)
                    }
                    .padding(.vertical, 18)
                    .offset(y: -6)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            Task {
                location = await resolveLocation()
                snapshot = computeIslamicDaySnapshot(location: location)
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            snapshot = computeIslamicDaySnapshot(location: location)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            now = Date()
        }
    }

    private func countdownMs(snapshot snap: ComputedIslamicDay) -> Int64 {
        let target = getCountdownTarget(now: now, timeline: snap.timeline)
        return Int64(max(0, target.timeIntervalSince(now) * 1000))
    }
    
    @ViewBuilder
    private func currentPeriodView(snapshot snap: ComputedIslamicDay, now: Date) -> some View {
        let baseFont = Font.system(size: 9)

        if snap.currentPhase == .sunrise_to_dhuhr {
            let t = now.timeIntervalSince1970
            let start = snap.timeline.sunrise.timeIntervalSince1970
            let end = snap.timeline.dhuhr.timeIntervalSince1970
            let hideFirst: TimeInterval = 20 * 60
            let hideLast: TimeInterval = 5 * 60
            if t < start + hideFirst || t > end - hideLast {
                Text(" ")
                    .font(baseFont)
                    .foregroundColor(Colors.ivory)
            } else {
                Text("Duha")
                    .font(baseFont.weight(.light))
                    .foregroundColor(Colors.ivory)
            }
        } else {
            switch snap.currentPhase {
            case .last_third_to_fajr:
                Text("Isha")
                    .font(baseFont)
                    .foregroundColor(Color(red: 0.22, green: 0.74, blue: 0.97))
                    .shadow(color: Color(red: 0.22, green: 0.74, blue: 0.97).opacity(0.7), radius: 4)
            default:
                Text(formatCurrentPeriod(snap.currentPhase))
                    .font(baseFont)
                    .foregroundColor(Colors.ivory)
            }
        }
    }
}

#Preview {
    ContentView()
}
