import Foundation

private struct ImageSizeConstants {
    // PNG
    static let pngWidthOffset = 16
    static let pngHeightOffset = 20

    // GIF
    static let gifWidthOffset = 6
    static let gifHeightOffset = 8

    // BMP
    static let bmpHeaderLengthOffset = 14 // Start of DIB header size field (4 bytes)
    static let bmpExpectedDIBHeaderSize: UInt32 = 40 // BITMAPINFOHEADER size
    static let bmpWidthOffset = 18
    static let bmpHeightOffset = 22

    // JPEG
    static let jpegStartOfImage: UInt8 = 0xFF
    static let jpegSOIMarker: UInt8 = 0xD8
    static let jpegStartOfFrameMarkers: ClosedRange<UInt8> = 0xC0...0xCF // SOF0-SOF15
    static let jpegAPPMarkers: ClosedRange<UInt8> = 0xE0...0xEF // APP0-APP15
    static let jpegHeightOffset = 5 // Relative to Start of Frame marker
    static let jpegWidthOffset = 7 // Relative to Start of Frame marker
}

/// 解析 Image Data 取得圖片尺寸
// 參考 https://github.com/pixel-foundry/remote-image-dimensions/blob/3c85ebd8e076503e2576dc14e79472ed739910e0/Sources/RemoteImageDimensions/Parsing/ImageDimensionParser.swift
extension Data {
    var imageSize: CGSize? {
        if let minLen = imageFormat.minimumSample, count <= minLen {
            return nil // not enough data collected to evaluate png size
        }

        switch imageFormat {
        case .png:
            return getPNGImageSize()
        case .gif:
            return getGIFImageSize()
        case .jpeg:
            return getJPGImageSize()
        case .bmp:
            return getBMPImageSize()
        default:
            return nil
        }
    }
}

extension Data {
    func getPNGImageSize() -> CGSize? {
        // Need at least 24 bytes for PNG IHDR chunk (8 bytes signature + 12 bytes IHDR + 4 bytes CRC)
        guard count >= 24 else { return nil }
        let w = Double(self[ImageSizeConstants.pngWidthOffset..<(ImageSizeConstants.pngWidthOffset + 4)].unsafeUInt32.bigEndian)
        let h = Double(self[ImageSizeConstants.pngHeightOffset..<(ImageSizeConstants.pngHeightOffset + 4)].unsafeUInt32.bigEndian)
        return CGSize(width: w, height: h)
    }
}

extension Data {
    func getGIFImageSize() -> CGSize? {
        // Need at least 10 bytes for GIF header + logical screen descriptor
        guard count >= 10 else { return nil }
        let w = Double(self[ImageSizeConstants.gifWidthOffset..<(ImageSizeConstants.gifWidthOffset + 2)].unsafeUInt16)
        let h = Double(self[ImageSizeConstants.gifHeightOffset..<(ImageSizeConstants.gifHeightOffset + 2)].unsafeUInt16)
        return CGSize(width: w, height: h)
    }
}

extension Data {
    func getBMPImageSize() -> CGSize? {
        // Need at least 26 bytes for BMP header (14 bytes File Header + 12 bytes BITMAPCOREHEADER)
        // Or 54 bytes for BITMAPINFOHEADER (14 bytes File Header + 40 bytes BITMAPINFOHEADER)
        guard count >= 26 else { return nil } // Min for any BMP is 26 bytes for width/height
        
        let dibHeaderSize = self[ImageSizeConstants.bmpHeaderLengthOffset..<(ImageSizeConstants.bmpHeaderLengthOffset + 4)].unsafeUInt32 // DIB Header size (little endian)
        
        // For BITMAPINFOHEADER (most common), it's 40 bytes.
        guard dibHeaderSize == ImageSizeConstants.bmpExpectedDIBHeaderSize else {
            // print("[ERROR] Unsupported BMP DIB header size: \(dibHeaderSize). Expected \(ImageSizeConstants.bmpExpectedDIBHeaderSize)")
            return nil
        }
        
        // Ensure enough data for width/height based on BITMAPINFOHEADER
        guard count >= ImageSizeConstants.bmpHeightOffset + 4 else { return nil }
        
        let w = Double(self[ImageSizeConstants.bmpWidthOffset..<(ImageSizeConstants.bmpWidthOffset + 4)].unsafeUInt32)
        let h = Double(self[ImageSizeConstants.bmpHeightOffset..<(ImageSizeConstants.bmpHeightOffset + 4)].unsafeUInt32)
        return CGSize(width: w, height: h)
    }
}

extension Data {
    func getJPGImageSize() -> CGSize? {
        var i = 0
        // Check for Start of Image (SOI) marker (FF D8) and first APP marker (FF E0-EF)
        guard count >= 4 && // Ensure enough bytes for initial markers
              self[i] == ImageSizeConstants.jpegStartOfImage &&
              self[i + 1] == ImageSizeConstants.jpegSOIMarker &&
              self[i + 2] == ImageSizeConstants.jpegStartOfImage &&
              (self[i + 3] >= ImageSizeConstants.jpegAPPMarkers.lowerBound && self[i + 3] <= ImageSizeConstants.jpegAPPMarkers.upperBound) else {
            // print("[ERROR] Unsupported image format: not a JPEG (SOI/APP marker mismatch)")
            return nil
        }
        i += 4

        while (i + 9) < count { // Need at least 9 more bytes for SOF marker + length + dimensions
            guard self[i] == ImageSizeConstants.jpegStartOfImage else {
                i += 1
                continue
            }
            // Check for Start of Frame (SOF) markers (FF C0-CF)
            guard self[i + 1] >= ImageSizeConstants.jpegStartOfFrameMarkers.lowerBound &&
                  self[i + 1] <= ImageSizeConstants.jpegStartOfFrameMarkers.upperBound else {
                i += 1
                continue
            }
            
            // SOF marker found, read dimensions (height then width)
            // Ensure enough bytes for dimensions
            guard count >= i + ImageSizeConstants.jpegWidthOffset + 2 else { return nil }
            
            let h = Int(self[(i + ImageSizeConstants.jpegHeightOffset)..<(i + ImageSizeConstants.jpegHeightOffset + 2)].unsafeUInt16.bigEndian)
            let w = Int(self[(i + ImageSizeConstants.jpegWidthOffset)..<(i + ImageSizeConstants.jpegWidthOffset + 2)].unsafeUInt16.bigEndian)
            
            return CGSize(width: Double(w), height: Double(h))
        }

        return nil
    }
}
