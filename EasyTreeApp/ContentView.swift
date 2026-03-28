import EasyTreeKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "tree.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("EasyTree v\(EasyTreeKit.version)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
