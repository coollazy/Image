// Example/Sources/App/main.swift
import Foundation
import Image // 確保這裡匯入了您的 Image 庫

// 模擬一個同步的圖片處理流程
func processImageSync() throws {
    print("--- Starting Sync Image Processing ---")
    let imageUrl = URL(fileURLWithPath: "Resources/image.png")
    
    // 檢查 Resources/image.png 是否存在
    guard FileManager.default.fileExists(atPath: imageUrl.path) else {
        print("Error: Resources/image.png not found. Please ensure it exists.")
        return
    }

    let image = try Image(data: try Data(contentsOf: imageUrl)) // 使用 Data(contentsOf:) 避免多次從 URL 初始化
    print("Original image format: \(image.format), size: \(String(describing: image.size))")

    // 使用同步 resize
    let resizedImage = try image.resize(to: CGSize(width: 50, height: 50), timeout: 10)
    print("Sync resized image format: \(resizedImage.format), size: \(String(describing: resizedImage.size))")
    print("--- Sync Image Processing Finished ---")
}

// 模擬一個異步的圖片處理流程
func processImageAsync() async throws {
    print("--- Starting Async Image Processing ---")
    let imageUrl = URL(fileURLWithPath: "Resources/image.png")
    
    // 檢查 Resources/image.png 是否存在
    guard FileManager.default.fileExists(atPath: imageUrl.path) else {
        print("Error: Resources/image.png not found. Please ensure it exists.")
        return
    }

    let image = try Image(data: try Data(contentsOf: imageUrl)) // 使用 Data(contentsOf:) 避免多次從 URL 初始化
    print("Original image format: \(image.format), size: \(String(describing: image.size))")

    // 使用異步 resize
    // await 關鍵字是呼叫 async 函數所必需的
    let resizedImage = try await image.resize(to: CGSize(width: 75, height: 75), timeout: 10)
    print("Async resized image format: \(resizedImage.format), size: \(String(describing: resizedImage.size))")
    print("--- Async Image Processing Finished ---")
}

// 這是新的程式進入點：直接在頂層呼叫 async 任務
Task {
    do {
        // 先運行同步版本
        try processImageSync()
        
        // 再運行異步版本
        try await processImageAsync()
        
    } catch {
        print("Error during image processing: \(error)")
    }
    
    // 確保程式結束
    exit(0)
}

// 為了讓 Task 有時間執行，需要讓 RunLoop 保持運行
// 在某些環境中，如果沒有 RunLoop 運行，Task 可能會立即退出
RunLoop.main.run()

