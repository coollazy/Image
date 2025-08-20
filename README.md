# Image

![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SPM](https://img.shields.io/badge/SPM-Supported-green)
[![CI](https://github.com/coollazy/Image/actions/workflows/ci.yml/badge.svg)](https://github.com/coollazy/Image/actions/workflows/ci.yml)

## 介紹

Image Model parser - 一個用於處理圖片的 Swift 函式庫，提供圖片解析、格式識別和尺寸調整等功能。

## 安裝

### SPM 安裝

在你的 `Package.swift` 中加入以下設定：

- Package.swift 的 dependencies 增加

```swift
.package(name: "Image", url: "https://github.com/coollazy/Image.git", from: "1.1.1"),
```

- target 的 dependencies 增加

```swift
.product(name: "Image", package: "Image"),
```

## 使用範例

### 基本使用

```swift
import Image

// 從 URL 初始化圖片
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

// 調整圖片尺寸
let resizeImage = try image.resize(to: .init(width: 50, height: 50))
print("resizeImage => \(resizeImage)")
```



## 系統需求

### ImageMagick 依賴

因為 resize 功能底層透過 ImageMagick 實現，所以需要在系統中安裝 ImageMagick。

### 檢查本地是否已安裝 ImageMagick

在使用 Image 函式庫前，請先確認你的環境是否已安裝 ImageMagick：

```bash
# 檢查 convert 命令是否可用
which convert

# 檢查 ImageMagick 版本（最推薦的方法）
convert -version

# 檢查 ImageMagick 支援的格式
convert -list format

# 檢查 identify 命令（ImageMagick 的另一個工具）
which identify
identify -version
```

如果上述命令無法執行或找不到 convert 命令，表示你需要先安裝 ImageMagick。

## ImageMagick 安裝指南

### MacOS

使用 Homebrew 安裝：

```bash
# 安裝 Homebrew（如果尚未安裝）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安裝 ImageMagick
brew install imagemagick

# 驗證安裝
convert -version
```

使用 MacPorts 安裝：

```bash
# 安裝 MacPorts（需要先從官網下載安裝包）
# https://www.macports.org/install.php

# 安裝 ImageMagick
sudo port install ImageMagick

# 驗證安裝
convert -version
```

### Linux

#### Ubuntu/Debian

```bash
# 更新套件列表
sudo apt update

# 安裝 ImageMagick
sudo apt install imagemagick

# 驗證安裝
convert -version
```

#### CentOS/RHEL/Fedora

```bash
# CentOS/RHEL 7/8
sudo yum install ImageMagick ImageMagick-devel

# Fedora/CentOS Stream/RHEL 9+
sudo dnf install ImageMagick ImageMagick-devel

# 驗證安裝
convert -version
```

#### Arch Linux

```bash
# 安裝 ImageMagick
sudo pacman -S imagemagick

# 驗證安裝
convert -version
```

#### Alpine Linux

```bash
# 安裝 ImageMagick
apk add imagemagick imagemagick-dev

# 驗證安裝
convert -version
```

### Docker

#### Dockerfile 範例

```dockerfile
# Ubuntu/Debian 基礎映像
FROM ubuntu:22.04

# 安裝系統套件
RUN apt-get update && \
    apt-get install -y imagemagick && \
    rm -rf /var/lib/apt/lists/*

# 驗證安裝
RUN convert -version
```

```dockerfile
# Alpine 基礎映像（更小的映像檔案）
FROM alpine:3.18

# 安裝 ImageMagick
RUN apk add --no-cache imagemagick imagemagick-dev

# 驗證安裝
RUN convert -version
```

#### Swift 專案 Dockerfile 完整範例

```dockerfile
# ================================
# Build image
# ================================
FROM swift:5.10-noble AS build

WORKDIR /build

COPY Package.* ./
RUN swift package resolve \
    $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

COPY . .
RUN swift build -c release --static-swift-stdlib

# ================================
# Run image
# ================================
FROM ubuntu:noble

# 安裝 runtime 依賴
RUN apt-get update && apt-get install -y \
      ca-certificates \
      imagemagick-6.q16 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /build/.build/release/App ./
COPY --from=build /build/Resources ./Resources

EXPOSE 8080
CMD ["./App"]
```

## 常見問題

### ImageMagick 政策限制

如果遇到權限錯誤，可能是 ImageMagick 的安全政策限制。可以檢查政策檔案：

```bash
# 查看政策檔案位置
convert -list policy

# Ubuntu/Debian 政策檔案通常在：
# /etc/ImageMagick-6/policy.xml
# /etc/ImageMagick-7/policy.xml
```

### 記憶體限制

處理大圖片時可能遇到記憶體限制，可以調整環境變數：

```bash
export MAGICK_MEMORY_LIMIT=1GB
export MAGICK_DISK_LIMIT=2GB
```

## 功能特色

- ✅ 支援多種圖片格式 (PNG, JPEG, GIF, TIFF, WEBP, HEIC)
- ✅ 圖片尺寸調整
- ✅ 圖片格式識別
- ✅ 圖片尺寸資訊取得
- ✅ 跨平台支援 (macOS, Linux, Docker)
- ✅ Swift Package Manager 支援
