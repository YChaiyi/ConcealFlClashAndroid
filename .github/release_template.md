# Conceal FlClash Android vVERSION

Android TUN-focused FlClash fork with a SukiSU Ultra helper module.

## Artifacts

- `conceal-flclash-android-vVERSION-arm64-v8a.apk`
- `conceal-flclash-tun-helper-vVERSION.zip`

## Notes

- Package name: `com.github.ychaiyi.conceal_flclash`
- App name: `Conceal FlClash Android`
- Module name: `Conceal FlClash TUN Helper`
- Author: `YChaiyi`

The app keeps FlClash's built-in Android `VpnService` TUN path. The SukiSU Ultra helper starts/stops the app service and verifies that a `tun*` interface appears; it does not install REDIR/TPROXY rules.

## Install

1. Install the APK.
2. Open the app once, select a profile, enable TUN/VPN mode, and approve the Android VPN prompt.
3. Install the helper ZIP in SukiSU Ultra.
4. Reboot or use the module action button.
