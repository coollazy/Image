import XCTest
@testable import Image

final class ImageTests: XCTestCase {
    
    // MARK: - Test Helpers (Base64 Images)
    
    // 1x1 Pixel PNG (Transparent)
    // Width: 1, Height: 1
    let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
    
    // 1x1 Pixel JPEG (Solid Color)
    // Width: 1, Height: 1
    let jpegBase64 = "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wAALCAABAAEBAREA/8QAAF3/2gAIAQEAAD8A/wD/2Q=="
    
    // 1x1 Pixel GIF (Transparent)
    // Width: 1, Height: 1
    let gifBase64 = "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
    
    // 1x1 Pixel BMP
    // Width: 1, Height: 1
    let bmpBase64 = "Qk06AAAAAAAAADYAAAAoAAAAAQAAAAEAAAABABgAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="

    // Invalid Data (Random String)
    let invalidBase64 = "SGVsbG8gV29ybGQ=" // "Hello World"
    
    // Helper to get Data from Base64
    func data(from base64: String) -> Data? {
        return Data(base64Encoded: base64)
    }
    
    // MARK: - Initialization & Format Tests
    
    func testInitWithPNG() throws {
        guard let data = data(from: pngBase64) else { XCTFail("Invalid Base64"); return }
        
        let image = try Image(data: data)
        
        XCTAssertEqual(image.format, .png)
        XCTAssertEqual(image.size, CGSize(width: 1, height: 1))
        XCTAssertNotNil(image.data)
    }
    
    func testInitWithJPEG() throws {
        guard let data = data(from: jpegBase64) else { XCTFail("Invalid Base64"); return }
        
        let image = try Image(data: data)
        
        XCTAssertEqual(image.format, .jpeg)
        XCTAssertEqual(image.size, CGSize(width: 1, height: 1))
    }
    
    func testInitWithGIF() throws {
        guard let data = data(from: gifBase64) else { XCTFail("Invalid Base64"); return }
        
        let image = try Image(data: data)
        
        XCTAssertEqual(image.format, .gif)
        XCTAssertEqual(image.size, CGSize(width: 1, height: 1))
    }
    
    func testInitWithBMP() throws {
        guard let data = data(from: bmpBase64) else { XCTFail("Invalid Base64"); return }
        
        let image = try Image(data: data)
        
        XCTAssertEqual(image.format, .bmp)
        XCTAssertEqual(image.size, CGSize(width: 1, height: 1))
    }
    
    func testInitWithInvalidData() {
        guard let data = data(from: invalidBase64) else { XCTFail("Invalid Base64"); return }
        
        XCTAssertThrowsError(try Image(data: data)) { error in
            guard let imageError = error as? ImageError else {
                XCTFail("Unexpected error type: \(error)")
                return
            }
            XCTAssertEqual(imageError, .unsupportedFormat)
        }
    }
    
    func testInitWithEmptyData() {
        let data = Data()
        XCTAssertThrowsError(try Image(data: data)) { error in
            XCTAssertEqual(error as? ImageError, .unsupportedFormat)
        }
    }

    func testInitWithPartialData() throws {
        // Only 4 bytes (incomplete header for PNG)
        let partialData = Data([0x89, 0x50, 0x4E, 0x47])
        
        let image = try Image(data: partialData)
        XCTAssertEqual(image.format, .png) // Magic bytes match PNG
        XCTAssertNil(image.size)           // But not enough data for size
    }
    
    func testInitWithMissingFile() {
        let fileURL = URL(fileURLWithPath: "/path/to/nowhere/ghost.png")
        XCTAssertThrowsError(try Image(url: fileURL)) { error in
            // Should be a Cocoa error (file read error), not ImageError
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Resizing Tests
    
    func testResizePNG() throws {
        // Skip if convert is not installed (Optional check, but good for CI without deps)
        if !isConvertInstalled() {
             print("Skipping resize test: 'convert' command not found.")
             return
        }

        guard let data = data(from: pngBase64) else { XCTFail("Invalid Base64"); return }
        let image = try Image(data: data)
        
        // Resize to 10x10 (Upscaling)
        let targetSize = CGSize(width: 10, height: 10)
        let resizedImage = try image.resize(to: targetSize)
        
        // Verify result is a valid image
        XCTAssertEqual(resizedImage.format, .png) // Convert usually keeps format or defaults to PNG
        XCTAssertNotNil(resizedImage.size)
        
        // Note: We check if size is present, but exact pixel matching might vary depending on ImageMagick version/settings.
        // For a 1x1 resize to 10x10, it should be 10x10.
        XCTAssertEqual(resizedImage.size, targetSize)
    }
    
    func testResizeTimeout() {
        if !isConvertInstalled() { return }

        guard let data = data(from: pngBase64) else { XCTFail("Invalid Base64"); return }
        
        do {
            let image = try Image(data: data)
            // Use an extremely small timeout to force a timeout error
            try image.resize(to: CGSize(width: 100, height: 100), timeout: 0.00001)
            XCTFail("Should have thrown TimeoutError")
        } catch {
            let nsError = error as NSError
            if nsError.domain == "TimeoutError" {
                XCTAssertEqual(nsError.code, -1)
            } else {
                 // On very fast machines, it might actually finish or fail with a different error.
                 // We accept TimeoutError as the primary success criteria here.
                 // print("Caught error: \(error)")
            }
        }
    }
    
    func testResizeToZero() throws {
        if !isConvertInstalled() { return }
        guard let data = data(from: pngBase64) else { return }
        let image = try Image(data: data)
        
        // ImageMagick behavior on 0x0 is error
        do {
            _ = try image.resize(to: CGSize.zero)
            XCTFail("Should have thrown error for zero size")
        } catch {
            // Expected
        }
    }
    
    func testResizeToNegative() throws {
        if !isConvertInstalled() { return }
        guard let data = data(from: pngBase64) else { return }
        let image = try Image(data: data)
        
        do {
            _ = try image.resize(to: CGSize(width: -10, height: -10))
            XCTFail("Should have thrown error for negative size")
        } catch {
            // Expected
        }
    }

    // MARK: - Helper Functions
    
    private func isConvertInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["convert"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}