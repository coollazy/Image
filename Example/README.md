# Image Example App

這是一個使用 `Image` 函式庫的範例應用程式，展示了如何在 Swift 專案中使用圖片處理功能，以及如何在 Docker 環境中部署。

## 準備工作

在運行範例之前，請確保：
1.  `Resources` 目錄下存在名為 `image.png` 的圖片檔案。程式會讀取此檔案進行測試。

## 本地運行 (macOS/Linux)

如果您已安裝 Swift 和 ImageMagick，可以直接在本地運行：

```bash
cd Example
swift run
```

## 使用 Docker 運行

我們支援使用 Docker 來構建和運行此範例，這也是驗證 Linux 兼容性的最佳方式。

### 1. 構建 Docker 映像

請在**專案的根目錄**（`Image` 庫的根目錄）下執行以下命令。這是為了確保 Docker 能同時讀取到 `Image` 庫的原始碼和 `Example` 專案。

```bash
# 在專案根目錄執行
docker build -t image-example:latest -f Example/Dockerfile .
```

### 2. 運行 Docker 容器

構建成功後，執行以下命令來啟動容器：

```bash
docker run --rm image-example:latest
```

容器啟動後將自動執行應用程式，您將看到同步與異步圖片處理的日誌輸出。
