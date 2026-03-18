import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Islamic Day Dial")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Open the app on your Apple Watch")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
