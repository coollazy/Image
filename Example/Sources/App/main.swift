import Foundation
import Image

do {
    let imageURL = URL(fileURLWithPath: "path_to_your_local_image") // 本地圖檔
//    let imageURL = URL(string: "https://example.com/image.png")! // 遠端圖檔
    
    let image = try Image(url: imageURL)

    // 檔案路徑
    print(image.url)

    // 檔案 Data
    print(image.data)

    // 檔案尺寸 (CGSize)
    print(image.size)

    // 檔案格式 (Unknown, PNG, JPEG, GIF, TIFF, WEBP, HEIC)
    print(image.format)
} catch {
    print(error.localizedDescription)
}
