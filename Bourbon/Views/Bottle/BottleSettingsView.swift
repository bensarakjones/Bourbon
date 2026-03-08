import SwiftUI

struct BottleSettingsView: View {
    
    @Binding var bottle: Bottle
    @ObservedObject var bottleManager: BottleManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Performance
                VStack(alignment: .leading, spacing: 12) {
                    BourbonSectionHeader(title: "Performance")
                    
                    VStack(spacing: 0) {
                        BourbonToggleRow(
                            title: "ESYNC",
                            description: "Event synchronization for better CPU performance",
                            isOn: $bottle.esync
                        )
                        Divider().background(BourbonColors.border)
                        BourbonToggleRow(
                            title: "MSYNC",
                            description: "Mach semaphores - Apple Silicon optimized",
                            isOn: $bottle.msync
                        )
                        Divider().background(BourbonColors.border)
                        BourbonToggleRow(
                            title: "DXVK",
                            description: "DirectX to Vulkan translation layer",
                            isOn: $bottle.dxvk
                        )
                        Divider().background(BourbonColors.border)
                        BourbonToggleRow(
                            title: "High Performance GPU",
                            description: "Disable Metal validation for max performance",
                            isOn: $bottle.highPerformanceGPU
                        )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(BourbonColors.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(BourbonColors.border, lineWidth: 1)
                            )
                    )
                }
                
                // MARK: - Display
                VStack(alignment: .leading, spacing: 12) {
                    BourbonSectionHeader(title: "Display")
                    
                    VStack(spacing: 0) {
                        BourbonToggleRow(
                            title: "Retina Mode",
                            description: "High DPI rendering on Retina displays",
                            isOn: $bottle.retinaMode
                        )
                        Divider().background(BourbonColors.border)
                        BourbonToggleRow(
                            title: "Metal HUD",
                            description: "Show GPU performance overlay",
                            isOn: $bottle.metalHUD
                        )
                        Divider().background(BourbonColors.border)
                        BourbonToggleRow(
                            title: "DXVK HUD",
                            description: "Show FPS, VRAM and device info overlay",
                            isOn: $bottle.dxvkHUD
                        )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(BourbonColors.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(BourbonColors.border, lineWidth: 1)
                            )
                    )
                }
                
                // MARK: - Windows Version
                VStack(alignment: .leading, spacing: 12) {
                    BourbonSectionHeader(title: "Windows Version")
                    
                    VStack(spacing: 4) {
                        ForEach(Bottle.WindowsVersion.allCases, id: \.self) { version in
                            VersionRow(
                                version: version,
                                isSelected: bottle.windowsVersion == version
                            ) {
                                bottle.windowsVersion = version
                                bottleManager.updateBottle(bottle)
                            }
                        }
                    }
                }
                
                // MARK: - Save Button
                HStack {
                    Spacer()
                    BourbonButton(
                        title: "Save Settings",
                        icon: "checkmark.circle.fill",
                        style: .primary
                    ) {
                        bottleManager.updateBottle(bottle)
                    }
                }
            }
            .padding(20)
        }
        .background(BourbonColors.background)
    }
}
