import Foundation
import SwiftUI
import Combine


class BottleManager: ObservableObject {
    
    @Published var bottles:   [Bottle]      = []
    @Published var isLoading: Bool          = false
    @Published var error:     BourbonError? = nil
    
    private let engine  = GPTKEngine()
    private let saveURL: URL
    
    init() {
        self.saveURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Bourbon/bottles.json")
        
        loadFromDisk()
    }
    
    // MARK: - Create a bottle
    func createBottle(
        name:           String,
        windowsVersion: Bottle.WindowsVersion = .windows10,
        engineType:     Bottle.EngineType     = .gptk
    ) async {
        await MainActor.run { isLoading = true }
        
        let bottle = Bottle(
            name:           name,
            windowsVersion: windowsVersion,
            engineType:     engineType
        )
        
        do {
            try await engine.initializeBottle(bottle)
            await MainActor.run {
                bottles.append(bottle)
                isLoading = false
                saveToDisk()
            }
        } catch let e as BourbonError {
            await MainActor.run {
                self.error = e
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .bottleCreationFailed(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    // MARK: - Scan bottle for installed .exe programs
    @discardableResult
    func scanForPrograms(in bottle: Bottle) async -> Int {
        
        // Directories inside the bottle's C: drive to search
        let searchPaths = [
            bottle.cDrivePath.appendingPathComponent("Program Files"),
            bottle.cDrivePath.appendingPathComponent("Program Files (x86)")
        ]
        
        // EXE names to skip — system/installer noise
        let blocklist: Set<String> = [
            "uninstall.exe", "unins000.exe", "unins001.exe",
            "setup.exe", "install.exe", "installer.exe",
            "update.exe", "updater.exe", "autoupdate.exe",
            "crashreporter.exe", "crashhandler.exe",
            "helper.exe", "launcher_helper.exe",
            "dxsetup.exe", "vcredist_x86.exe", "vcredist_x64.exe",
            "dotnetfx.exe", "windowsdesktop-runtime.exe",
            "isbundles.exe", "issetup.exe"
        ]
        
        var discovered: [Program] = []
        let fm = FileManager.default
        
        for searchPath in searchPaths {
            guard fm.fileExists(atPath: searchPath.path) else { continue }
            
            guard let enumerator = fm.enumerator(
                at: searchPath,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension.lowercased() == "exe" else { continue }
                
                let filename = fileURL.lastPathComponent.lowercased()
                guard !blocklist.contains(filename) else { continue }
                
                // Skip if already in the bottle's program list
                let alreadyAdded = bottle.programs.contains {
                    $0.executableURL.path == fileURL.path
                }
                guard !alreadyAdded else { continue }
                
                // Use the filename without extension as the display name
                let name = fileURL.deletingPathExtension().lastPathComponent
                var program = Program(name: name, executableURL: fileURL)
                
                // Try to extract the icon from the exe
                program.iconData = extractIcon(from: fileURL)
                
                discovered.append(program)
            }
        }
        
        guard !discovered.isEmpty else { return 0 }
        
        await MainActor.run {
            guard let index = bottles.firstIndex(where: { $0.id == bottle.id }) else { return }
            bottles[index].programs.append(contentsOf: discovered)
            saveToDisk()
        }
        
        return discovered.count
    }
    
    // MARK: - Extract icon from .exe using NSWorkspace
    private func extractIcon(from url: URL) -> Data? {
        // NSWorkspace can read the icon of any file, including .exe
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        guard let tiff = icon.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
    
    // MARK: - Delete a bottle
    func deleteBottle(_ bottle: Bottle) {
        do {
            if FileManager.default.fileExists(atPath: bottle.path.path) {
                try FileManager.default.removeItem(at: bottle.path)
            }
            bottles.removeAll { (b: Bottle) -> Bool in b.id == bottle.id }
            saveToDisk()
        } catch {
            self.error = .processFailure(error.localizedDescription)
        }
    }
    
    // MARK: - Update a bottle
    func updateBottle(_ bottle: Bottle) {
        guard let i = bottles.firstIndex(where: { (b: Bottle) -> Bool in
            b.id == bottle.id
        }) else { return }
        bottles[i] = bottle
        saveToDisk()
    }
    
    // MARK: - Add program to bottle
    func addProgram(_ program: Program, to bottle: Bottle) {
        guard let i = bottles.firstIndex(where: { (b: Bottle) -> Bool in
            b.id == bottle.id
        }) else { return }
        bottles[i].programs.append(program)
        saveToDisk()
    }
    
    // MARK: - Remove program from bottle
    func removeProgram(_ program: Program, from bottle: Bottle) {
        guard let i = bottles.firstIndex(where: { (b: Bottle) -> Bool in
            b.id == bottle.id
        }) else { return }
        bottles[i].programs.removeAll { (p: Program) -> Bool in
            p.id == program.id
        }
        saveToDisk()
    }
    
    // MARK: - Launch a program
    func launch(
        _ program: Program,
        in bottle: Bottle,
        onOutput: ((String) -> Void)? = nil
    ) async {
        do {
            try await engine.launch(
                program,
                in: bottle,
                onOutput: onOutput
            )
        } catch let e as BourbonError {
            await MainActor.run { self.error = e }
        } catch {
            await MainActor.run {
                self.error = .programLaunchFailed(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Install component
    func installComponent(
        _ component: WineComponent,
        in bottle: Bottle,
        onOutput: ((String) -> Void)? = nil
    ) async {
        do {
            try await engine.install(
                component: component,
                in: bottle,
                onOutput: onOutput
            )
        } catch let e as BourbonError {
            await MainActor.run { self.error = e }
        } catch {
            await MainActor.run {
                self.error = .installationFailed(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Clear error
    func clearError() {
        error = nil
    }
    
    // MARK: - Save
    private func saveToDisk() {
        do {
            try FileManager.default.createDirectory(
                at: saveURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(bottles)
            try data.write(to: saveURL, options: .atomicWrite)
        } catch {
            print("⚠️ Bourbon: Failed to save — \(error)")
        }
    }
    
    // MARK: - Load
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: saveURL.path)
        else { return }
        
        do {
            let data = try Data(contentsOf: saveURL)
            bottles  = try JSONDecoder().decode([Bottle].self, from: data)
        } catch {
            print("⚠️ Bourbon: Failed to load — \(error)")
        }
    }
}
