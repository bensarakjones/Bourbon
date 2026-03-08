import Foundation

enum WineComponent: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case vcredist2022 = "vcredist2022"
    case vcredist2019 = "vcredist2019"
    case vcredist2015 = "vcredist2015"
    case dotnet48     = "dotnet48"
    case dotnet6      = "dotnet6"
    case directx9     = "d3dx9"
    case dxvk         = "dxvk"
    case vkd3d        = "vkd3d"
    case openal       = "openal"
    case xact         = "xact"
    case physx        = "physx"
    
    var displayName: String {
        switch self {
        case .vcredist2022: return "Visual C++ 2022"
        case .vcredist2019: return "Visual C++ 2019"
        case .vcredist2015: return "Visual C++ 2015"
        case .dotnet48:     return ".NET Framework 4.8"
        case .dotnet6:      return ".NET 6"
        case .directx9:     return "DirectX 9"
        case .dxvk:         return "DXVK"
        case .vkd3d:        return "VKD3D"
        case .openal:       return "OpenAL"
        case .xact:         return "XACT Audio"
        case .physx:        return "PhysX"
        }
    }
    
    var category: String {
        switch self {
        case .vcredist2022, .vcredist2019, .vcredist2015:
            return "Visual C++"
        case .dotnet48, .dotnet6:
            return ".NET"
        case .directx9, .dxvk, .vkd3d:
            return "DirectX"
        case .openal, .xact:
            return "Audio"
        case .physx:
            return "Physics"
        }
    }
}
