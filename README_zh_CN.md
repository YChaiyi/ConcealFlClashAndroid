# Conceal FlClash Android

[English](README.md)

Conceal FlClash Android 是 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的 Android 分支，用于配合 SukiSU Ultra 模块启动 root TUN 透明代理。

- APP 长名：`Conceal FlClash Android`
- 包名：`com.github.ychaiyi.conceal_flclash`
- 模块名：`Conceal FlClash TUN Helper`
- 作者：`YChaiyi`

## Root TUN 模式

SukiSU Ultra 配套模块会启动一个 root `mihomo` 进程，并基于 App 当前的 `config.yaml` 生成 root TUN 配置。

模块不会调用 Android `VpnService.prepare()`，也不会写入 REDIR/TPROXY 透明代理规则。模块负责：

- 通过模块操作按钮或 App 启动按钮启动/停止 root TUN 进程；
- 在 root 环境下授予通知权限；
- 清理早期测试版可能残留的 `FLCLASH_*` REDIR 链；
- 启动后检查 `ConcealFlClash` TUN 网卡是否出现。

Conceal Android 启动路径只使用 root 模块。如果 SukiSU Ultra 模块未安装或启动失败，App 会提示失败，不会 fallback 到 Android `VpnService`。

## 安装

1. 安装匹配的 `Conceal FlClash Android` APK。
2. 打开 App 一次，导入/选择可用配置。
3. 在 SukiSU Ultra 里安装 `conceal-flclash-tun-helper.zip`。
4. 重启，使用 SukiSU 模块操作按钮，或在 App 内点击启动/停止 root TUN 服务。

## Android Actions

配套模块也可以通过这些 App quick action 切换：

```text
com.github.ychaiyi.conceal_flclash.action.START
com.github.ychaiyi.conceal_flclash.action.STOP
com.github.ychaiyi.conceal_flclash.action.TOGGLE
```

## 构建

```bash
git submodule update --init --recursive
flutter pub get
flutter build apk --release --target-platform android-arm64
./tools/package-root-module.sh
```

必要时创建 `android/local.properties`：

```properties
sdk.dir=/Users/liuhaiyi/Library/Android/sdk
flutter.sdk=/path/to/flutter
```

## Release 文件

- APK：`build/app/outputs/flutter-apk/app-release.apk`
- SukiSU 模块：`build/root-module/conceal-flclash-tun-helper.zip`

## 上游致谢

本项目基于 [chen08209/FlClash](https://github.com/chen08209/FlClash) 和 ClashMeta core。
