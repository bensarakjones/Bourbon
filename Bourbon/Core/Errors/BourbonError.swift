import Foundation

enum BourbonError: LocalizedError {
    
    case engineNotFound
    case engineNotInstalled
    case bottleCreationFailed(String)
    case bottleNotFound
    case programLaunchFailed(String)
    case processFailure(String)
    case installationFailed(String)
    case winetricksNotFound
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .engineNotFound:
            return "Engine binary could not be found."
        case .engineNotInstalled:
            return "No Wine or GPTK engine is installed."
        case .bottleCreationFailed(let r):
            return "Bottle creation failed: \(r)"
        case .bottleNotFound:
            return "Bottle not found on disk."
        case .programLaunchFailed(let r):
            return "Could not launch program: \(r)"
        case .processFailure(let r):
            return "Process error: \(r)"
        case .installationFailed(let r):
            return "Installation failed: \(r)"
        case .winetricksNotFound:
            return "Winetricks not found. Run: brew install winetricks"
        case .permissionDenied:
            return "Permission denied."
        }
    }
}
