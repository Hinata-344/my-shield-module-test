# 設定ファイルが入っているディレクトリを指定
CONFIG_DIR = config

# 左用ビルドに含めるファイル群（ファイル名に "_right" を含まないもの）
SRCS_LEFT = $(shell find $(CONFIG_DIR) -type f ! -name "*_right*")

# 右用ビルドに含めるファイル群（ファイル名に "_left" を含まないもの）
SRCS_RIGHT = $(shell find $(CONFIG_DIR) -type f ! -name "*_left*")

# 左用ビルドのターゲットUF2ファイルのパス
TARGET_LEFT = ../zmk/app/build/left/zephyr/zmk.uf2

# 右用ビルドのターゲットUF2ファイルのパス
TARGET_RIGHT = ../zmk/app/build/right/zephyr/zmk.uf2

# build, clean タスクを常に実行する（ファイルターゲットではなくコマンド実行用）
.PHONY: build clean

# build タスクは左右両方のUF2生成を依存関係にする
build: $(TARGET_LEFT) $(TARGET_RIGHT)

# 左用ターゲットのビルドルール
$(TARGET_LEFT): $(SRCS_LEFT)
	# Docker内でZMKビルド実行。ビルドディレクトリは build/left
	# ボードは seeeduino_xiao_ble
	# SHIELDを futaba_left に指定し、ZMK設定ディレクトリをマウント
	docker exec -w /workspaces/zmk/app -it $(container_name) west build -d build/left -b seeeduino_xiao_ble -S studio-rpc-usb-uart -- -DSHIELD=futaba_left -DZMK_CONFIG="/workspaces/zmk-config/config" -DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n
	# ビルド成果物UF2ファイルをコピーしてわかりやすくリネーム
	docker exec -w /workspaces/zmk/app -it $(container_name) cp build/left/zephyr/zmk.uf2 build/futaba_left.uf2

# 右用ターゲットのビルドルール
$(TARGET_RIGHT): $(SRCS_RIGHT)
	# Docker内で右用ビルドを実行（build/right）
	# SHIELDを futaba_right に切り替えてビルド
	docker exec -w /workspaces/zmk/app -it $(container_name) west build -d build/right -b seeeduino_xiao_ble -- -DSHIELD=futaba_right -DZMK_CONFIG="/workspaces/zmk-config/config"
	# 右用UF2もコピーしてわかりやすくリネーム
	docker exec -w /workspaces/zmk/app -it $(container_name) cp build/right/zephyr/zmk.uf2 build/futaba_right.uf2

# clean タスクはDocker内のビルド成果物ディレクトリを丸ごと削除してクリーンアップ
clean:
	docker exec -it $(container_name) rm -rf /workspaces/zmk/app/build
