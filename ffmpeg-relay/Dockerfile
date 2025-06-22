FROM alpine:latest

# 必要なパッケージをインストール
RUN apk add --no-cache \
    ffmpeg \
    bash \
    wget \
    curl \
    && rm -rf /var/cache/apk/*

# 作業ディレクトリを設定
WORKDIR /app

# エントリーポイントスクリプトを作成
COPY scripts/relay.sh /app/relay.sh
RUN chmod +x /app/relay.sh

ENTRYPOINT ["/app/relay.sh"]