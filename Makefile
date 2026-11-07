SHELL := /bin/bash

# ============================ 项目配置 ============================
# APK 文件名前缀，默认取 package.json 的 name
APP_SLUG ?= $(shell bun -e 'console.log(require("./package.json").name)')
# 版本号，默认取 package.json 的 version，可在命令上覆盖：make apk VERSION=1.2.3
VERSION  ?= $(shell bun -e 'console.log(require("./package.json").version)')
# Android versionCode = 主版本 * 10000 + 次版本 * 100 + 修订版本
VERSION_CODE ?= $(shell echo "$(VERSION)" | awk -F. '{printf "%d%02d%02d", $$1, $$2, $$3}')

# Java 环境：优先使用外部传入的 JAVA_HOME（CI 由 setup-java 提供），否则在本机常见位置探测
JAVA_HOME ?= $(shell for d in "$$JAVA_HOME" \
	"$$HOME/.source/java/jdk-21/Contents/Home" \
	"/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
	/Applications/Android\ Studio.app/Contents/jbr/Contents/Home \
	$$(/usr/libexec/java_home 2>/dev/null) ; do \
	if [ -x "$$d/bin/java" ]; then echo "$$d"; break; fi; done)
export JAVA_HOME

DIST_DIR      := dist
ANDROID_DIR   := android
RELEASE_DIR   := release
APK_DEBUG_SRC := $(ANDROID_DIR)/app/build/outputs/apk/debug/app-debug.apk
APK_REL_DIR   := $(ANDROID_DIR)/app/build/outputs/apk/release
APK_DEBUG     := $(RELEASE_DIR)/$(APP_SLUG)-$(VERSION)-debug.apk
APK_RELEASE   := $(RELEASE_DIR)/$(APP_SLUG)-$(VERSION)-release.apk

.DEFAULT_GOAL := apk

.PHONY: help version deps dev web sync apk apk-debug apk-release clean

help: ## 显示所有可用命令
	@echo "应用标识: $(APP_SLUG)"
	@echo "当前版本: v$(VERSION) (versionCode=$(VERSION_CODE))"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*? ## ' $(MAKEFILE_LIST) | sed 's/:.* ## /\t/' | awk -F'\t' '{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

version: ## 显示当前版本号
	@echo "versionName: $(VERSION)"
	@echo "versionCode: $(VERSION_CODE)"

deps: ## 安装依赖
	bun install

dev: deps ## 启动本地开发服务器（http://localhost:3000，改代码自动刷新）
	bun index.html

web: ## 打包前端资源到 dist/
	rm -rf $(DIST_DIR)
	bun build ./index.html --outdir $(DIST_DIR) --minify --define INJECTED_VERSION="'$(VERSION)'"
	@echo "前端资源已输出到 $(DIST_DIR)/ (v$(VERSION))"

sync: web deps ## 打包前端并同步到 Android 工程
	bun run cap sync android

apk: apk-debug ## 打包 APK（默认打包 Debug）

apk-debug: sync ## 打包 Debug APK
	cd $(ANDROID_DIR) && ./gradlew assembleDebug -PappVersionName=$(VERSION) -PappVersionCode=$(VERSION_CODE)
	@mkdir -p $(RELEASE_DIR)
	cp $(APK_DEBUG_SRC) $(APK_DEBUG)
	@echo "APK 输出: $(APK_DEBUG)"

apk-release: sync ## 打包 Release APK（配置签名后自动签名）
	cd $(ANDROID_DIR) && ./gradlew assembleRelease -PappVersionName=$(VERSION) -PappVersionCode=$(VERSION_CODE)
	@mkdir -p $(RELEASE_DIR)
	@cp $$(ls -1 $(APK_REL_DIR)/*.apk | head -n 1) $(APK_RELEASE)
	@echo "APK 输出: $(APK_RELEASE)"

clean: ## 清理构建产物
	rm -rf $(DIST_DIR) $(RELEASE_DIR)
	cd $(ANDROID_DIR) && ./gradlew clean
