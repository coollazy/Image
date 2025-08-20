import Foundation

public extension Image {
    @discardableResult
    func resize(to size: CGSize) throws -> Self {
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
        
        print("convert path: \(convertPath)")
        print("input file: \(inputURL.path)")
        print("output file: \(outputURL.path)")
        
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
                let error = NSError(
                    domain: "ImageMagickError",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: "Convert failed with status \(process.terminationStatus)"]
                )
                result = .failure(error)
            }
            semaphore.signal()
        }

        do {
            try process.run()
            let timeoutResult = semaphore.wait(timeout: .now() + 5)
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
        case .success(let image):
            return try Image(url: outputURL)
        case .failure(let error):
            throw error
        }
    }
    
    private func pathForConvert() -> String? {
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
        
        for path in allPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        return nil
    }
}
