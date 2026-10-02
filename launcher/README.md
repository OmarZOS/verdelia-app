# launcher

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)



## Generating the signed appbundle

        keytool -genkey -v -keystore verdelia_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias verdelia_android_key

        jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore verdelia_keystore.jks build/app/outputs/bundle/release/app-release.aab verdelia_android_key

        # Check certificates in the AAB
        jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
