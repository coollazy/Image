import Foundation

private struct ImageMagicNumbers {
    static let png: UInt8 = 0x89
    static let jpeg: UInt8 = 0xFF
    static let gif: UInt8 = 0x47
    static let tiffBigEndian: UInt8 = 0x49 // 'I'
    static let tiffLittleEndian: UInt8 = 0x4D // 'M'
    static let bmp: UInt8 = 0x42
    static let webpRiff: UInt8 = 0x52 // 'R' for RIFF
    static let heicStart: UInt8 = 0x00 // Common start for ISO BMFF
    static let pdfStart: UInt8 = 0x25 // '%'
    static let svgStart: UInt8 = 0x3C // '<'
}

/// 解析 Image Data 的第一個 bytes ，判斷圖片格式
extension Data {
    // 參考 https://github.com/SDWebImage/SDWebImage/blob/master/SDWebImage/Core/NSData%2BImageContentType.m
    var imageFormat: ImageFormat {
        guard count >= 1 else { return .unknown }
        switch self[0] {
        case ImageMagicNumbers.png:
            return .png
        case ImageMagicNumbers.jpeg:
            return .jpeg
        case ImageMagicNumbers.gif:
            return .gif
        case ImageMagicNumbers.tiffBigEndian, ImageMagicNumbers.tiffLittleEndian:
            return .tiff
        case ImageMagicNumbers.bmp:
            return .bmp
        case ImageMagicNumbers.webpRiff where count >= 12:
            let subdata = self[0...11]
            if let dataString = String(data: subdata, encoding: .ascii),
                dataString.hasPrefix("RIFF"),
                dataString.hasSuffix("WEBP") {
                return .webp
            }
        case ImageMagicNumbers.heicStart where count >= 12 :
            let subdata = self[8...11]

            ///OLD: "ftypheic", "ftypheix", "ftyphevc", "ftyphevx"
            if let dataString = String(data: subdata, encoding: .ascii),
                Set(["heic", "heix", "hevc", "hevx"]).contains(dataString) {
                return .heic
            }
        case ImageMagicNumbers.pdfStart where count >= 4:
            let subdata = self[1...3]
            if let dataString = String(data: subdata, encoding: .ascii),
               dataString == "PDF" {
                return .pdf
            }
        case ImageMagicNumbers.svgStart:
            return .svg
        default:
            return .unknown
        }
        return .unknown
    }
}
