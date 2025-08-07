import Foundation

public extension Image {
    @discardableResult
    func resize(to size: CGSize) throws -> Self {
        guard let convertPath = pathForConvert() else {
            throw NSError(domain: "ImageMagick", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot find convert command, please install ImageMagick first."])
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
        process.arguments = [inputURL.path, "-resize", "\(Int(size.width))x\(Int(size.height))", outputURL.path]

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ImageMagick", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: errorOutput
            ])
        }

        // Step 3: Read resized image data
        let resizedData = try Data(contentsOf: outputURL)

        return try Image(data: resizedData)
    }
    
    private func pathForConvert() -> String? {
        let possiblePaths = [
            "/opt/homebrew/bin/convert",    // Apple Silicon
            "/usr/local/bin/convert"        // Intel Mac
        ]
        
        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        return nil
    }
}
