import SwiftUI

struct ContentView: View {
    @State private var snapshot: ComputedIslamicDay?
    
    var body: some View {
        Group {
            if let snap = snapshot {
                ZStack {
                    RingView(snapshot: snap)
                    VStack(spacing: 2) {
                        let parts = formatHijriDateParts(snap.hijriDate)
                        Text(parts.dayMonth)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(parts.isEid ? Color(red: 0.06, green: 0.73, blue: 0.51) : .primary)
                        Text(parts.year)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        let period = currentPeriodLabel(snapshot: snap, now: Date())
                        if !period.isEmpty {
                            Text(period)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        } else {
                            // Preserve layout height
                            Text(" ")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(localTimeString)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            snapshot = computeIslamicDaySnapshot()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            snapshot = computeIslamicDaySnapshot()
        }
    }
    
    private var localTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    private func currentPeriodLabel(snapshot: ComputedIslamicDay, now: Date) -> String {
        if snapshot.currentPhase != .sunrise_to_dhuhr {
            return formatCurrentPeriod(snapshot.currentPhase)
        }
        let t = now.timeIntervalSince1970
        let start = snapshot.timeline.sunrise.timeIntervalSince1970
        let end = snapshot.timeline.dhuhr.timeIntervalSince1970
        
        let hideFirst: TimeInterval = 20 * 60
        let hideLast: TimeInterval = 5 * 60
        
        if t < start + hideFirst { return "" }
        if t > end - hideLast { return "" }
        return formatCurrentPeriod(snapshot.currentPhase)
    }
}

#Preview {
    ContentView()
}
