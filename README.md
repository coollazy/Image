# Image

## 介紹

Image Model parser

## SPM安裝

- Package.swift 的 dependencies 增加

```
.package(name: "Image", url: "https://github.com/coollazy/Image.git", from: "1.0.0"),
```

- target 的 dependencies 增加

```
.product(name: "Image", package: "Image"),
```

## 範例

- 初始化

```
let imageURL = URL(string: "path_to_your_image")! // or remote URL
let image = try Image(url: imageURL)

// 檔案路徑
print(image.url)

// 檔案 Data
print(image.data)

// 檔案尺寸 (CGSize)
print(image.size)

// 檔案格式 (Unknown, PNG, JPEG, GIF, TIFF, WEBP, HEIC)
print(image.format)

```
