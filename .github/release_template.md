# Conceal FlClash Android vVERSION

Android root TUN-focused FlClash fork with a SukiSU Ultra helper module.

## Artifacts

- `conceal-flclash-android-vVERSION-arm64-v8a.apk`
- `conceal-flclash-tun-helper-vVERSION.zip`

## Notes

- Package name: `com.github.ychaiyi.conceal_flclash`
- App name: `Conceal FlClash Android`
- Module name: `Conceal FlClash TUN Helper`
- Author: `YChaiyi`

The app start path uses the SukiSU Ultra helper module to launch a root `mihomo` TUN process. It does not request Android `VpnService` consent and does not fall back to Android `VpnService` when the module is missing or fails.

## Install

1. Install the APK.
2. Open the app once and select a working profile.
3. Install the helper ZIP in SukiSU Ultra.
4. Reboot, use the module action button, or press start in the app.
