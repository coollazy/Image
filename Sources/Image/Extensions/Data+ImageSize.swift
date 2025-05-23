import Foundation

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
        let w = Double(self[16..<20].unsafeUInt32.bigEndian)
        let h = Double(self[20..<24].unsafeUInt32.bigEndian)
        return CGSize(width: w, height: h)
    }
}

extension Data {
    func getGIFImageSize() -> CGSize? {
        let w = Double(self[6..<8].unsafeUInt16)
        let h = Double(self[8..<10].unsafeUInt16)
        return CGSize(width: w, height: h)
    }
}

extension Data {
    func getBMPImageSize() -> CGSize? {
        let length: UInt16 = self[14..<18].unsafeUInt16
        guard length == 40 else {
            print("[ERROR] Unsupported image format: not a BMP [length: \(length)]")
            return nil
        }
        let widthStart = 18
        let heightStart = widthStart + 4
        let w = Double(self[widthStart..<(widthStart + 4)].unsafeUInt32)
        let h = Double(self[heightStart..<(heightStart + 4)].unsafeUInt32)
        return CGSize(width: w, height: h)
    }
}

extension Data {
    func getJPGImageSize() -> CGSize? {
        var i = 0
        guard self[i] == 0xFF && self[i + 1] == 0xD8 && self[i + 2] == 0xFF else {
            print("[ERROR] Unsupported image format: not a JPEG")
            return nil
        }
        guard self[i + 3] >= 0xE0 || self[i + 3] <= 0xEF else {
            print("[ERROR] Unsupported image format: not a JPEG")
            return nil
        }
        i += 4

        while (i + 9) < count {
            guard self[i] == 0xFF else {
                i += 1
                continue
            }
            guard self[i + 1] >= 0xC0 && self[i + 1] <= 0xCF else {
                i += 1
                continue
            }
            let w = Int(self[(i + 7)..<(i + 9)].unsafeUInt16.bigEndian)
            let h = Int(self[(i + 5)..<(i + 7)].unsafeUInt16.bigEndian)
            
            return CGSize(width: Double(Int(w)), height: Double(Int(h)))
        }

        return nil
    }
}
