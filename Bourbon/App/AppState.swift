import SwiftUI
import Combine

class AppState: ObservableObject {
    
    @Published var isOnboardingComplete: Bool
    @Published var selectedBottle: Bottle?
    @Published var engineStatus: EngineStatus = .unknown
    
    init() {
        self.isOnboardingComplete = UserDefaults.standard
            .bool(forKey: "bourbon.onboardingComplete")
        
        Task {
            let installed = await EngineManager.shared.isInstalled()
            await MainActor.run {
                self.engineStatus = installed ? .ready : .notInstalled
            }
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "bourbon.onboardingComplete")
        isOnboardingComplete = true
    }
    
    func refreshEngineStatus() {
        Task {
            let installed = await EngineManager.shared.isInstalled()
            await MainActor.run {
                self.engineStatus = installed ? .ready : .notInstalled
            }
        }
    }
    
    enum EngineStatus: Equatable {
        case unknown
        case checking
        case notInstalled
        case installing
        case ready
        case error(String)
        
        var label: String {
            switch self {
            case .unknown:        return "Unknown"
            case .checking:       return "Checking..."
            case .notInstalled:   return "Not Installed"
            case .installing:     return "Installing..."
            case .ready:          return "Ready"
            case .error(let msg): return "Error: \(msg)"
            }
        }
        
        var isReady: Bool {
            if case .ready = self { return true }
            return false
        }
    }
}
