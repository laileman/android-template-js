# App Template · Capacitor + Bun + Android

一个可直接复用的移动端仓库模板：前端用 **Bun** 打包成静态资源，**Capacitor** 把资源嵌进 Android WebView，`make` 一键产出带版本号的 APK，GitHub Actions 自动构建。

---

## 1. 目录结构

```
.
├── index.html                 # 前端入口（Bun 的打包入口，也是开发服务器入口）
├── src/
│   ├── app.js                 # 前端逻辑
│   └── styles.css             # 前端样式
├── package.json               # 依赖 · 应用标识(name) · 版本号(version)   ← 常用改动
├── capacitor.config.ts        # Capacitor 配置：appId / appName            ← 常用改动
├── Makefile                   # 开发与打包命令
├── release/                   # APK 产物（已 gitignore）
├── .github/workflows/         # GitHub Actions
└── android/                   # Capacitor 生成的原生工程
    ├── app/build.gradle       # 版本号注入 · 发布签名
    ├── app/src/main/res/      # 应用名 · 图标 · 启动图 · 主题              ← 常用改动
    ├── keystore.properties.example
    └── local.properties       # 本机 SDK 路径（已 gitignore）
```

> `android/` 由 `bun run cap add android` 生成，日常不需要重新生成，只改其中的配置与资源文件。

---

## 2. 环境要求

| 依赖 | 版本 | 说明 |
| --- | --- | --- |
| [Bun](https://bun.com) | ≥ 1.2 | 装依赖、打包前端、跑开发服务器；已替代 npm/npx，**不需要 Node** |
| JDK | 21 | AGP 8.13 要求；Makefile 会自动探测 `JAVA_HOME` |
| Android SDK | cmdline-tools + platform 36 + build-tools 35 | 用 **Android CLI**（`android sdk install`）安装组件，`./gradlew` 编译 APK |

macOS 上 `JAVA_HOME` 会自动在下面这些位置查找：`~/.source/java/jdk-21`、Android Studio 自带 JBR、`/usr/libexec/java_home`。其他位置请自行 `export JAVA_HOME=...`。

安装 SDK 组件用 Android CLI（`sdkmanager` 已废弃，不要再使用）。没装过 CLI 的话，macOS 上先跑官方安装脚本：

```bash
curl -fsSL https://dl.google.com/android/cli/latest/darwin_arm64/install.sh | bash   # Intel 机器把 darwin_arm64 换成 darwin_x86_64
```

包名用 `/` 分隔：

```bash
SDK="$HOME/.source/android-sdk"
"$SDK/cmdline-tools/latest/bin/android" --sdk="$SDK" sdk install \
  platforms/android-36 platform-tools build-tools/35.0.0
```

`android` 已在 `PATH` 中时可省略前面的 `--sdk=`，直接 `android sdk install platforms/android-36`；`android sdk list` 查看已安装组件。

所有命令都通过 `bun` / `make` 执行，**不要用 `npx`**（本机没有 Node/npm）。

---

## 3. 开发

```bash
make deps    # 安装依赖
make dev     # 启动开发服务器 http://localhost:3000
```

`make dev` 基于 Bun 内置的 HTML 开发服务器，修改 `index.html` / `src/` 下的文件会自动刷新。

---

## 4. 打包

```bash
make                 # 默认目标，等价于 make apk / make apk-debug
make apk-release     # Release APK（配置签名后自动签名）
```

产物统一输出到 `release/`，文件名自带应用标识与版本号：

```
release/app-1.0.0-debug.apk
release/app-1.0.0-release.apk
```

### 命令一览

| 命令 | 作用 |
| --- | --- |
| `make help` | 列出所有命令，并显示当前应用标识与版本 |
| `make version` | 显示 versionName / versionCode |
| `make deps` | 安装依赖 |
| `make dev` | 本地开发服务器（热更新） |
| `make web` | 只打包前端到 `dist/` |
| `make sync` | 打包前端并 `cap sync` 到 Android 工程 |
| `make apk` | 打包 Debug APK |
| `make apk-release` | 打包 Release APK |
| `make clean` | 清理 `dist/`、`release/` 与 gradle 产物 |

### 打包流程

```
src/ + index.html
   │  bun build（Makefile: web）
   ▼
dist/                       ← 前端静态资源
   │  cap sync（Makefile: sync）
   ▼
android/app/src/main/assets/public/
   │  gradlew assembleDebug / assembleRelease（Makefile: apk-debug / apk-release）
   ▼
release/app-<version>-<buildType>.apk
```

---

## 5. 版本号

**唯一来源：[package.json](file:///Users/leman/Desktop/sre/app/package.json) 的 `version` 字段。** 改这一处即可，其余自动跟随：

| 位置 | 取值方式 |
| --- | --- |
| APK 文件名 | `release/<name>-<version>-<buildType>.apk` |
| Android `versionName` | Makefile 通过 `-PappVersionName` 注入 |
| Android `versionCode` | Makefile 按 `主*10000 + 次*100 + 修订` 计算后注入 |
| 应用内显示的版本徽标 | `src/app.js` 直接 `import package.json` |

如需不修改文件就产出指定版本（例如 CI 按 tag 打包）：

```bash
make apk-release VERSION=1.2.3
```

---

## 6. 常用改动位置

| 想改什么 | 改哪里 |
| --- | --- |
| **版本号** | `package.json` → `version`（唯一来源，其余自动同步） |
| **应用显示名（桌面图标下的名字）** | ① `capacitor.config.ts` → `appName`<br>② `android/app/src/main/res/values/strings.xml` → `app_name`、`title_activity_main` |
| **APK 文件名前缀** | `package.json` → `name` |
| **包名 / applicationId** | ① `android/app/build.gradle` → `namespace`、`applicationId`<br>② `capacitor.config.ts` → `appId`<br>③ `android/app/src/main/res/values/strings.xml` → `package_name`、`custom_url_scheme`<br>④ `android/app/src/main/java/<包名路径>/MainActivity.java` 的 `package` 声明与目录路径 |
| **应用图标（logo）** | `android/app/src/main/res/mipmap-*/ic_launcher.png`（方形）与 `ic_launcher_round.png`（圆形） |
| **自适应图标（Android 8+）** | 前景 `mipmap-*/ic_launcher_foreground.png`，背景色 `android/app/src/main/res/values/ic_launcher_background.xml`，描述文件 `mipmap-anydpi-v26/ic_launcher.xml` |
| **启动图（splash）** | `android/app/src/main/res/drawable/splash.png`、`drawable-port-*/splash.png`、`drawable-land-*/splash.png` |
| **应用主题 / 状态栏** | `android/app/src/main/res/values/styles.xml` |
| **前端页面与样式** | `index.html`、`src/app.js`、`src/styles.css` |
| **接口地址等运行时配置** | `src/app.js` 顶部的常量 |

### 图标尺寸对照

| 目录 | 方形/圆形图标 | 自适应图标前景 |
| --- | --- | --- |
| `mipmap-mdpi` | 48×48 | 108×108 |
| `mipmap-hdpi` | 72×72 | 162×162 |
| `mipmap-xhdpi` | 96×96 | 216×216 |
| `mipmap-xxhdpi` | 144×144 | 324×324 |
| `mipmap-xxxhdpi` | 192×192 | 432×432 |

推荐用 Android Studio 的图标向导生成：右键 `android/app/src/main/res` → **New → Image Asset**，选好前景图后它会自动覆盖上述所有尺寸与 `mipmap-anydpi-v26/`。启动图同理用 **New → Image Asset → Icon Type: Launcher Icons / Notification Icons**，或直接替换各 `splash.png`。

> 注意：`cap sync` **不会**覆盖 `strings.xml` 与图标资源，这些必须手动改。

---

## 7. 敏感信息清单

当前仓库里**没有任何真实的密钥或凭证**，模板只包含示例文件。以下是需要留意的敏感/本机信息，全部已在 `.gitignore` 中：

| 文件 | 用途 | 是否入库 | 如何处理 |
| --- | --- | --- | --- |
| `android/local.properties` | 本机 Android SDK 路径（`sdk.dir`） | 否（已忽略） | 每台机器自己生成，或由 `ANDROID_HOME` 环境变量替代 |
| `android/keystore.properties` | 发布签名配置（口令、别名） | 否（已忽略） | 从 `keystore.properties.example` 复制后填写 |
| `*.jks` / `*.keystore` | 签名密钥库本体 | 否（已忽略） | 自己生成并**离线备份**，丢失后无法再更新同一应用 |
| `android/app/google-services.json` | Firebase / FCM 凭证 | 否（已忽略） | 从 Firebase 控制台下载，按需放入 |
| `.env` / `.env.*` | 环境变量（接口地址、第三方 Key 等） | 否（已忽略） | 需要时从 `.env.example` 复制 |
| `android/app/build/`、`release/`、`dist/` | 构建产物 | 否（已忽略） | 可随时重新生成 |

**判断原则**：只要一个文件能让别人冒用你的身份（签名密钥、服务账号、API Key），或只对某台机器生效（SDK 路径），就不要提交。

---

## 8. 发布签名

未配置签名时 `make apk-release` 产出的是**未签名** APK，无法上架也无法覆盖安装。启用签名：

```bash
# 1. 生成密钥库（只做一次，务必离线备份）
keytool -genkeypair -v -keystore android/release.jks -alias mykey \
  -keyalg RSA -keysize 2048 -validity 36500

# 2. 复制配置模板并填写
cp android/keystore.properties.example android/keystore.properties

# 3. 打包
make apk-release
```

`android/app/build.gradle` 检测到 `android/keystore.properties` 存在时会自动启用签名，产物变成已签名的 `release/app-<version>-release.apk`。

### 在 CI 中使用签名

在仓库 **Settings → Secrets and variables → Actions** 添加：

| Secret | 内容 |
| --- | --- |
| `KEYSTORE_BASE64` | `base64 -i android/release.jks \| pbcopy`（macOS）的输出 |
| `KEYSTORE_PASSWORD` | 密钥库口令 |
| `KEY_ALIAS` | 密钥别名 |
| `KEY_PASSWORD` | 密钥口令 |

未配置这些 Secret 时，CI 会自动跳过签名步骤，仍然能构建出未签名 release APK。

---

## 9. GitHub Actions

[.github/workflows/build-apk.yml](file:///Users/leman/Desktop/sre/app/.github/workflows/build-apk.yml)

| 触发条件 | 行为 |
| --- | --- |
| push 到 `main` / `master`、PR、手动触发 | 构建 Debug APK，上传为 workflow artifact |
| 推送 `v*` tag（如 `v1.2.0`） | 用 tag 作为版本号构建 Release APK，上传 artifact 并自动创建 GitHub Release |

版本号取自 tag 时会去掉前缀 `v`，即 tag `v1.2.0` → `versionName 1.2.0`、`versionCode 10200`、产物 `release/app-1.2.0-release.apk`。

CI 的整个 job 跑在 **容器**（`eclipse-temurin:21-jdk`）里，不依赖 runner 预装的 SDK：JDK 21 来自镜像，Android CLI 由官方脚本在容器内安装，SDK 组件用 `android sdk install platforms/android-36 platform-tools build-tools/35.0.0` 装好，全程不使用已废弃的 `sdkmanager`，也不再依赖 `android-actions/setup-android`。`ANDROID_HOME` / `ANDROID_SDK_ROOT` 指向 `/opt/android-sdk` 供 Gradle 使用。

换 JDK 或换成别的构建镜像时，容器内至少要有 `git`（checkout）、`curl`（装 Android CLI）、`make` 与 `awk`（Makefile 用到），并保证 `JAVA_HOME` 可用。

发布新版本：

```bash
git tag v1.0.1
git push origin v1.0.1
```

---

## 10. 复用为模板：改动清单

1. `package.json` → `name`（APK 文件名前缀）、`version`（版本号）
2. `capacitor.config.ts` → `appId`、`appName`
3. `android/app/src/main/res/values/strings.xml` → `app_name`、`title_activity_main`、`package_name`、`custom_url_scheme`
4. `android/app/build.gradle` → `namespace`、`applicationId`
5. `android/app/src/main/java/**/MainActivity.java` → `package` 声明，并同步调整目录结构
6. 替换 `android/app/src/main/res/mipmap-*` 与 `drawable*` 下的图标、启动图
7. 替换 `index.html` + `src/` 的前端代码
8. 清理上一版残留：`make clean`，并按需删除 `android/.gradle`、`android/app/build`

改完后执行一次 `make apk` 验证：能成功产出 `release/<name>-<version>-debug.apk` 即可。
