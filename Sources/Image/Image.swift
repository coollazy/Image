import Foundation

public struct Image {
    private(set) public var url: URL?
    /// 圖片 raw data
    public let data: Data
    /// 圖片尺寸
    public let size: CGSize?
    /// 圖片格式
    public let format: ImageFormat
    
    public init(url: URL) throws {
        self.url = url
        self.data = try Data(contentsOf: url)
        guard data.imageFormat != .unknown else {
            throw ImageError.unsupportedFormat
        }
        self.format = data.imageFormat
        self.size = data.imageSize
    }
    
    public init(data: Data) throws {
        self.data = data
        guard data.imageFormat != .unknown else {
            throw ImageError.unsupportedFormat
        }
        self.format = data.imageFormat
        self.size = data.imageSize
    }
}

public enum ImageError: Error, CustomStringConvertible, LocalizedError {
    case unsupportedFormat
    
    public var description: String {
        switch self {
        case .unsupportedFormat:
            return NSLocalizedString("不支援的圖片格式", comment: "")
        }
    }
    
    public var errorDescription: String? {
        description
    }
}
