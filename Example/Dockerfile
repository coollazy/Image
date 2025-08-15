# ================================
# Build image
# ================================
FROM swift:5.10-noble AS build

WORKDIR /build

# 先解決 Swift package
COPY Package.* ./
RUN swift package resolve \
    $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

# 複製專案並編譯
COPY . .
RUN swift build -c release --static-swift-stdlib

# ================================
# Run image
# ================================
FROM ubuntu:noble

# 安裝 runtime 依賴（包含 ImageMagick CLI）
RUN apt-get update && apt-get install -y \
      ca-certificates \
      imagemagick-6.q16 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 複製可執行檔和 Resources
COPY --from=build /build/.build/release/App ./
COPY --from=build /build/Resources ./Resources

EXPOSE 8080
CMD ["./App"]
