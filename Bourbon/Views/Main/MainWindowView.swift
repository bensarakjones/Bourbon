import SwiftUI

struct MainWindowView: View {
    
    @EnvironmentObject var appState: AppState
    @StateObject private var bottleManager = BottleManager()
    
    var body: some View {
        NavigationSplitView {
            SidebarView(bottleManager: bottleManager)
        } detail: {
            if let bottle = appState.selectedBottle {
                BottleDetailView(
                    bottle: bottle,
                    bottleManager: bottleManager
                )
            } else {
                EmptyDetailView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(BourbonColors.background)
    }
}
