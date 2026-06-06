# Conceal FlClash Android

[English](README.md)

Conceal FlClash Android 是 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的 Android 分支，保留 FlClash 自带的 `VpnService` 虚拟网卡代理，并提供 SukiSU Ultra 配套模块。

- APP 长名：`Conceal FlClash Android`
- 包名：`com.github.ychaiyi.conceal_flclash`
- 模块名：`Conceal FlClash TUN Helper`
- 作者：`YChaiyi`

## TUN 虚拟网卡模式

FlClash 本身已经有 Android `VpnService` 实现，会创建 `tun*` 虚拟网卡，并调用 ClashMeta core 的 `Core.startTun(...)`。这个分支保留这条路径。

SukiSU Ultra 模块不写入 REDIR/TPROXY 透明代理规则。模块只负责：

- 通过 App quick action 启动或停止服务；
- 在 root 环境下授予通知权限；
- 清理早期测试版可能残留的 `FLCLASH_*` REDIR 链；
- 启动后检查 `tun*` 网卡是否出现。

Android VPN 授权仍由系统控制。第一次使用需要打开 App 并同意 VPN 授权；授权后，模块操作按钮和开机脚本可以启动现有 TUN 服务。

## 安装

1. 安装匹配的 `Conceal FlClash Android` APK。
2. 打开 App 一次，导入/选择可用配置，开启 TUN/VPN 模式，并同意 Android VPN 授权。
3. 在 SukiSU Ultra 里安装 `conceal-flclash-tun-helper.zip`。
4. 重启，或使用 SukiSU 模块操作按钮启动/停止 TUN 服务。

## Android Actions

模块使用这些 action：

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

本项目基于 [chen08209/FlClash](https://github.com/chen08209/FlClash)、FlClash Android `VpnService` TUN 实现，以及 ClashMeta core。
