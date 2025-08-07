import Foundation
import Image

do {
    
    let imageURL = URL(fileURLWithPath: "path_to_your_local_image") // 本地圖檔
//    let imageURL = URL(string: "https://example.com/image.png")! // 遠端圖檔
    
    let image = try Image(url: imageURL)
    print(image)
    
    // 調整圖片尺寸
    let resizeImage = try image.resize(to: .init(width: 50, height: 50))
    print("resizeImage => \(resizeImage)")
    
}
catch {
    print(error.localizedDescription)
}
