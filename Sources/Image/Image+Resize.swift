#if os(macOS) || os(Linux)
import Foundation

public extension Image {
    /// 使用 ImageMagick 調整圖片大小。
    ///
    /// 此方法會調用系統的 `convert` 命令行工具來執行縮放操作。
    /// 
    /// - Important: 執行環境必須安裝 **ImageMagick**。
    ///   - **macOS**: `brew install imagemagick`
    ///   - **Linux (Ubuntu)**: `apt-get install imagemagick`
    ///
    /// - Parameters:
    ///   - size: 目標尺寸 (`CGSize`)。
    ///   - timeout: 操作的超時時間（秒）。預設為 5 秒。如果在指定時間內未完成，將拋出 `TimeoutError`。
    /// - Returns: 一個新的 `Image` 實例，包含調整大小後的圖片數據。
    /// - Throws: 
    ///   - `ImageMagickError`: 如果 `convert` 指令執行失敗。
    ///   - `TimeoutError`: 如果操作超時。
    ///   - `NSError`: 如果找不到 `convert` 指令或其他系統錯誤。
    @discardableResult
    func resize(to size: CGSize, timeout: TimeInterval = 5) throws -> Self {
        // Parameter validation
        guard size.width > 0 && size.height > 0 else {
            throw NSError(
                domain: "ImageResizeError",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Resize dimensions must be greater than zero. Provided: \(size)"]
            )
        }

        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Self, Error>?
        
        guard let convertPath = pathForConvert() else {
            throw NSError(domain: "ImageMagick", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot find convert command. Please ensure ImageMagick is installed."])
        }
        
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("Image-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tmpDir)
        }
        
        let inputURL = tmpDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        let outputURL = tmpDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")

        // Step 1: Write image data to temp input file
        try data.write(to: inputURL)
        
        // Step 2: Use ImageMagick to resize
        let process = Process()
        process.executableURL = URL(fileURLWithPath: convertPath)
        
        process.arguments = [
            inputURL.path,
            "-resize", "\(Int(size.width))x\(Int(size.height))",
            outputURL.path
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // 設定完成回調(Docker container 裡面運行的時候，一定要用 terminatinHandler 才不會卡住，只有 convert 這個指令有點異常。)
        process.terminationHandler = { process in
            if process.terminationStatus == 0 {
                result = .success(self)
            }
            else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                
                let error = NSError(
                    domain: "ImageMagickError",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: "Convert failed with status \(process.terminationStatus). Detail: \(errorMessage)"]
                )
                result = .failure(error)
            }
            semaphore.signal()
        }

        do {
            try process.run()
            let timeoutResult = semaphore.wait(timeout: .now() + timeout)
            if timeoutResult == .timedOut {
                process.terminate()
                throw NSError(
                    domain: "TimeoutError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Resize operation timed out"]
                )
            }
        } catch {
            result = .failure(error)
        }
        
        guard let result else {
            throw NSError(
                domain: "ResizeError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Resize operation failed, no result"]
            )
        }
        switch result {
        case .success(_): // 變更為 _ 以消除警告
            return try Image(url: outputURL)
        case .failure(let error):
            throw error
        }
    }
    
    /// 使用 ImageMagick 調整圖片大小 (異步版本)。
    ///
    /// 此方法透過 `Task.detached` 將同步的縮放操作移至後台執行緒，
    /// 確保在 Docker/Linux 環境下的穩定性（避免 `terminationHandler` 潛在的掛起問題），
    /// 同時提供符合現代 Swift Concurrency 的非阻塞 API。
    ///
    /// - Parameters:
    ///   - size: 目標尺寸 (`CGSize`)。
    ///   - timeout: 操作的超時時間（秒）。預設為 5 秒。
    /// - Returns: 一個新的 `Image` 實例。
    func resize(to size: CGSize, timeout: TimeInterval = 5) async throws -> Self {
        return try await Task.detached(priority: .userInitiated) {
            return try self.resize(to: size, timeout: timeout)
        }.value
    }
    
    private static var cachedConvertPath: String?

    private func pathForConvert() -> String? {
        if let path = Self.cachedConvertPath {
            return path
        }
        
        // Docker 容器中優先檢查標準路徑
        let containerPaths = [
            "/usr/bin/convert",             // Ubuntu/Debian 標準路徑 (最常見)
            "/bin/convert",                 // 有些容器配置
            "/usr/local/bin/convert",       // 自訂編譯安裝
        ]
        
        // macOS 開發環境路徑
        let macOSPaths = [
            "/opt/homebrew/bin/convert",    // Apple Silicon
            "/usr/local/bin/convert",       // Intel Mac
        ]
        
        // 合併所有可能的路徑，優先檢查容器環境的路徑
        let allPaths = containerPaths + macOSPaths
        
        var foundPath: String?
        for path in allPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                foundPath = path
                break
            }
        }
        
        // 如果硬編碼路徑找不到，嘗試使用 which 命令動態查找
        if foundPath == nil, let whichPath = shell("which convert")?.trimmingCharacters(in: .whitespacesAndNewlines),
           !whichPath.isEmpty,
           FileManager.default.isExecutableFile(atPath: whichPath) {
            foundPath = whichPath
        }
        
        // Store and return found path
        Self.cachedConvertPath = foundPath
        return foundPath
    }

    // 輔助函數：執行 shell 命令並返回輸出
    private func shell(_ command: String) -> String? {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/bash") // 或 /usr/bin/env bash
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            task.waitUntilExit() // 等待命令完成
            return output
        } catch {
            return nil
        }
    }
}
#endif
