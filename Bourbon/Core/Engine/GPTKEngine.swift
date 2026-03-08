import Foundation

class GPTKEngine {
    
    private let manager = EngineManager.shared
    
    // MARK: - Build environment variables
    func buildEnvironment(for bottle: Bottle) async -> [String: String] {
        
        guard let engine = await manager.preferredEngine() else { return [:] }
        
        let wineRoot = engine.binaryURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        // Use the app's own temp directory so Wine isn't blocked by sandbox
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("bourbon-wine")
            .path
        try? FileManager.default.createDirectory(
            atPath: tmpDir,
            withIntermediateDirectories: true
        )
        
        var env: [String: String] = [
            
            // Core Wine
            "WINEPREFIX": bottle.path.path,
            "WINEARCH":   "win64",
            
            // Point Wine's server socket away from /tmp (fixes sandbox block)
            "TMPDIR":     tmpDir,
            
            // Apple Silicon sync
            "WINEESYNC":  bottle.esync ? "1" : "0",
            "WINEMSYNC":  bottle.msync ? "1" : "0",
            
            // Metal
            "MTL_HUD_ENABLED":         bottle.metalHUD ? "1" : "0",
            "WINE_SIMULATE_WRITECOPY": "1",
            "WINE_D3D_CONFIG":         "renderer=metal",
            
            // DXVK
            "DXVK_ASYNC": "1",
            "DXVK_HUD":   bottle.dxvkHUD ? "fps,devinfo,memory" : "0",
            
            // Library paths
            "DYLD_FALLBACK_LIBRARY_PATH": [
                "\(wineRoot.path)/lib",
                "/usr/lib",
                "/usr/local/lib",
                "/opt/homebrew/lib"
            ].joined(separator: ":"),
        ]
        
        if bottle.retinaMode {
            env["WINE_METAL_RETINA"] = "1"
        }
        
        if bottle.highPerformanceGPU {
            env["MTL_SHADER_VALIDATION"] = "0"
            env["MTL_DEBUG_LAYER"]       = "0"
        }
        
        return env
    }
    
    // MARK: - Initialize a new bottle
    func initializeBottle(_ bottle: Bottle) async throws {
        
        try FileManager.default.createDirectory(
            at: bottle.path,
            withIntermediateDirectories: true
        )
        
        let result = try await runInBottle(
            command: "wineboot",
            args: ["--init"],
            bottle: bottle
        )
        
        guard result.succeeded else {
            throw BourbonError.bottleCreationFailed(result.stderr)
        }
        
        try await setWindowsVersion(bottle.windowsVersion, in: bottle)
    }
    
    // MARK: - Launch a program
    func launch(
        _ program: Program,
        in bottle: Bottle,
        onOutput: ((String) -> Void)? = nil
    ) async throws {
        
        guard let engine = await manager.preferredEngine() else {
            throw BourbonError.engineNotFound
        }
        
        let env  = await buildEnvironment(for: bottle)
        let args = [engine.binaryURL.path, program.executableURL.path]
        + program.launchArguments
        
        if let onOutput {
            _ = try await ProcessRunner.runStreaming(
                args,
                environment: env,
                onOutput: onOutput
            )
        } else {
            let result = try await ProcessRunner.run(args, environment: env)
            if !result.succeeded {
                throw BourbonError.programLaunchFailed(result.stderr)
            }
        }
    }
    
    // MARK: - Install a component via Winetricks
    func install(
        component: WineComponent,
        in bottle: Bottle,
        onOutput: ((String) -> Void)? = nil
    ) async throws {
        
        guard let winetricks = findWinetricks() else {
            throw BourbonError.winetricksNotFound
        }
        
        let env = await buildEnvironment(for: bottle)
        
        if let onOutput {
            _ = try await ProcessRunner.runStreaming(
                [winetricks, "-q", component.rawValue],
                environment: env,
                onOutput: onOutput
            )
        } else {
            let result = try await ProcessRunner.run(
                [winetricks, "-q", component.rawValue],
                environment: env
            )
            if !result.succeeded {
                throw BourbonError.installationFailed(result.stderr)
            }
        }
    }
    
    // MARK: - Run a Wine command inside a bottle
    @discardableResult
    func runInBottle(
        command: String,
        args:    [String] = [],
        bottle:  Bottle
    ) async throws -> ProcessResult {
        
        guard let engine = await manager.preferredEngine() else {
            throw BourbonError.engineNotFound
        }
        
        let env = await buildEnvironment(for: bottle)
        
        return try await ProcessRunner.run(
            [engine.binaryURL.path, command] + args,
            environment: env
        )
    }
    
    // MARK: - Set Windows version
    private func setWindowsVersion(
        _ version: Bottle.WindowsVersion,
        in bottle: Bottle
    ) async throws {
        try await runInBottle(
            command: "winecfg",
            args:    ["/v", version.rawValue],
            bottle:  bottle
        )
    }
    
    private func findWinetricks() -> String? {
        let paths = [
            "/usr/local/bin/winetricks",
            "/opt/homebrew/bin/winetricks"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
}
