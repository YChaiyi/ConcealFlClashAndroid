# Conceal FlClash Android

[简体中文](README_zh_CN.md)

Conceal FlClash Android is a fork of [chen08209/FlClash](https://github.com/chen08209/FlClash) for Android root TUN transparent proxying with a SukiSU Ultra companion module.

- App long name: `Conceal FlClash Android`
- Package name: `com.github.ychaiyi.conceal_flclash`
- Module name: `Conceal FlClash TUN Helper`
- Author: `YChaiyi`

## Root TUN Mode

The companion SukiSU Ultra module starts a root `mihomo` process with a generated TUN configuration based on the app's current `config.yaml`.

The module does not call Android `VpnService.prepare()` and does not install REDIR or TPROXY rules. It:

- starts or stops the root TUN process from module actions or the app start button;
- grants notification permission when root is available;
- cleans legacy `FLCLASH_*` REDIR chains from earlier test builds;
- checks that the `ConcealFlClash` TUN interface appears after startup.

The Conceal Android start path only uses the root module. If the SukiSU Ultra module is missing or fails to start, the app reports failure instead of falling back to Android `VpnService`.

## Install

1. Install the matching `Conceal FlClash Android` APK.
2. Open the app once and import/select a working profile.
3. Install `conceal-flclash-tun-helper.zip` in SukiSU Ultra.
4. Reboot, use the SukiSU module action button, or press start in the app to start/stop the root TUN service.

## Android Actions

The helper module can still be toggled by SukiSU module actions or by these app quick actions:

```text
com.github.ychaiyi.conceal_flclash.action.START
com.github.ychaiyi.conceal_flclash.action.STOP
com.github.ychaiyi.conceal_flclash.action.TOGGLE
```

## Build

```bash
git submodule update --init --recursive
flutter pub get
flutter build apk --release --target-platform android-arm64
./tools/package-root-module.sh
```

Create `android/local.properties` if needed:

```properties
sdk.dir=/Users/liuhaiyi/Library/Android/sdk
flutter.sdk=/path/to/flutter
```

## Release Artifacts

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- SukiSU module: `build/root-module/conceal-flclash-tun-helper.zip`

## Upstream Credits

This project is based on [chen08209/FlClash](https://github.com/chen08209/FlClash) and the ClashMeta core.
