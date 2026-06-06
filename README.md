# Conceal FlClash Android

[简体中文](README_zh_CN.md)

Conceal FlClash Android is a fork of [chen08209/FlClash](https://github.com/chen08209/FlClash) for Android TUN proxying with a SukiSU Ultra companion module.

- App long name: `Conceal FlClash Android`
- Package name: `com.github.ychaiyi.conceal_flclash`
- Module name: `Conceal FlClash TUN Helper`
- Author: `YChaiyi`

## TUN Mode

FlClash already includes an Android `VpnService` implementation that creates a TUN virtual network interface and starts the ClashMeta core with `Core.startTun(...)`. This fork keeps that path intact.

The SukiSU Ultra module does not install REDIR or TPROXY rules. It only:

- starts or stops the app through the app's quick Android actions;
- grants notification permission when root is available;
- cleans legacy `FLCLASH_*` REDIR chains from earlier test builds;
- checks that a `tun*` interface appears after startup.

Android VPN consent is still the system-controlled gate for `VpnService`. Open the app once and grant the VPN prompt; after that, the module action and boot script can start the existing TUN service.

## Install

1. Install the matching `Conceal FlClash Android` APK.
2. Open the app once, import/select a working profile, enable TUN/VPN mode, and approve the Android VPN prompt.
3. Install `conceal-flclash-tun-helper.zip` in SukiSU Ultra.
4. Reboot, or use the SukiSU module action button to start/stop the TUN service.

## Android Actions

The helper module uses these actions:

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

This project is based on [chen08209/FlClash](https://github.com/chen08209/FlClash), the FlClash Android `VpnService` TUN implementation, and the ClashMeta core.
