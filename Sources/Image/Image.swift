import Foundation

/// 一個輕量級、跨平台的圖片表示結構。
///
/// `Image` 結構封裝了圖片的原始數據 (Raw Data)、格式 (Format) 和尺寸 (Size)。
/// 它不依賴於特定平台的 UI 框架 (如 UIKit 或 AppKit)，因此適用於 Linux 和 macOS 服務器端環境。
public struct Image {
    /// 圖片的來源 URL (如果是從檔案初始化的話)。
    private(set) public var url: URL?
    
    /// 圖片的原始二進制數據 (Raw Data)。
    public let data: Data
    
    /// 圖片的像素尺寸 (寬 x 高)。如果無法解析則為 nil。
    public let size: CGSize?
    
    /// 圖片的格式 (如 PNG, JPEG 等)。
    public let format: ImageFormat
    
    /// 從本地檔案 URL 初始化圖片。
    ///
    /// - Parameter url: 圖片檔案的本地路徑 URL。
    /// - Throws: 如果讀取檔案失敗，或圖片格式不被支援 (`ImageError.unsupportedFormat`)，將拋出錯誤。
    public init(url: URL) throws {
        self.url = url
        self.data = try Data(contentsOf: url)
        guard data.imageFormat != .unknown else {
            throw ImageError.unsupportedFormat
        }
        self.format = data.imageFormat
        self.size = data.imageSize
    }
    
    /// 從記憶體中的二進制數據初始化圖片。
    ///
    /// - Parameter data: 包含圖片內容的 `Data`。
    /// - Throws: 如果圖片格式無法識別或不被支援 (`ImageError.unsupportedFormat`)，將拋出錯誤。
    public init(data: Data) throws {
        self.data = data
        guard data.imageFormat != .unknown else {
            throw ImageError.unsupportedFormat
        }
        self.format = data.imageFormat
        self.size = data.imageSize
    }
}

/// 圖片處理過程中可能發生的錯誤。
public enum ImageError: Error, CustomStringConvertible, LocalizedError {
    /// 圖片格式不被支援或無法識別。
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
