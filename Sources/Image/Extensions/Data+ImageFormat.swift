import Foundation

/// 解析 Image Data 的第一個 bytes ，判斷圖片格式
extension Data {
    // 參考 https://github.com/SDWebImage/SDWebImage/blob/master/SDWebImage/Core/NSData%2BImageContentType.m
    var imageFormat: ImageFormat {
        switch self[0] {
        case 0x89:
            return .png
        case 0xFF:
            return .jpeg
        case 0x47:
            return .gif
        case 0x49, 0x4D:
            return .tiff
        case 0x42:
            return .bmp
        case 0x52 where count >= 12:
            let subdata = self[0...11]
            if let dataString = String(data: subdata, encoding: .ascii),
                dataString.hasPrefix("RIFF"),
                dataString.hasSuffix("WEBP") {
                return .webp
            }
        case 0x00 where count >= 12 :
            let subdata = self[8...11]

            ///OLD: "ftypheic", "ftypheix", "ftyphevc", "ftyphevx"
            if let dataString = String(data: subdata, encoding: .ascii),
                Set(["heic", "heix", "hevc", "hevx"]).contains(dataString) {
                return .heic
            }
        case 0x25 where count >= 4:
            let subdata = self[1...3]
            if let dataString = String(data: subdata, encoding: .ascii),
               dataString == "PDF" {
                return .pdf
            }
        case 0x3C:
            return .svg
        default:
            return .unknown
        }
        return .unknown
    }
}
