import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isOnboardingComplete {
                MainWindowView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut, value: appState.isOnboardingComplete)
    }
}
