import SwiftUI

@main
struct OCRApp: App {
    init() {
        // Optimize app launch by reducing initial work
        // This helps reduce CA Event and gesture timeout warnings
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Defer any heavy initialization until after first frame
                    DispatchQueue.main.async {
                        // Any post-launch setup can go here
                    }
                }
        }
    }
}

