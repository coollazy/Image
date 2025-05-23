public enum ImageFormat {
    case unknown
    case png
    case jpeg
    case gif
    case bmp
    case tiff
    case webp
    case heic
    case heif
    case pdf
    case svg
}

public extension ImageFormat {
    /// 要判斷 Image data 的 format，需要的最少的bytes數量
    // 參考 https://github.com/pixel-foundry/remote-image-dimensions/blob/3c85ebd8e076503e2576dc14e79472ed739910e0/Sources/RemoteImageDimensions/Models/ImageFormat.swift
    var minimumSample: Int? {
        switch self {
        case .jpeg:
            return nil // will be checked by the parser (variable data is required)
        case .png:
            return 25
        case .gif:
            return 11
        case .bmp:
            return 29
        default:
            return nil
        }
    }
}
