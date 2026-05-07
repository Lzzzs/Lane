import SwiftUI
import LaneCore

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Lane")
                .font(.system(size: 28, weight: .medium))
            Text("v0.1 scaffold — UI lands in upcoming milestones")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
