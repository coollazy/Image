import Foundation
import Image

do {
    let imageURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("Resources")
        .appendingPathComponent("image.png")
    
    // 載入圖檔
    let image = try Image(url: imageURL)
    print(image)
    
    // 調整圖片尺寸
    let resizeImage = try image.resize(to: .init(width: 50, height: 50))
    print("resizeImage => \(resizeImage)")
    
    // 圖檔存檔
    
    let outputImageURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("resize-image.png")
    try resizeImage.data.write(to: outputImageURL)
    debugPrint("success !!")
}
catch {
    print(error.localizedDescription)
}
