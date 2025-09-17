
# MEGA for iOS

[Download on the App Store](https://apps.apple.com/app/mega/id706857885)

A fully-featured iOS client for accessing your secure cloud storage and communication tools, powered by [MEGA](https://mega.io).

---

## 🛠️ Building & Running the Application

This guide will help you build the MEGA iOS application using Xcode on macOS.

### Prerequisites

- [Xcode](https://itunes.apple.com/app/xcode/id497799835?mt=12)

---

### 🔧 Configuration Steps (Public Users)

1. **Update `.gitmodules`**:
   - Update:
     - `Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK` → `https://github.com/meganz/MEGAchat.git`
     - `SDK` → `https://github.com/meganz/SDK.git`

2. **Remove submodules**:
   - `iosTransifex`
   - `Modules/MEGASharedRepo`

3. **Replace Shared Repo**:
   - [Download MEGASharedRepo](https://mega.nz/folder/TqBmgDyI#USMnXad535FoQtIkHPEb9g/file/myZRBRaa)
   - Replace the old one in the `/Modules` directory.

4. **Install CMake**:
   - Navigate to the `scripts` folder and run:
     ```bash
     ./install-cmake.sh
     ```
   - Alternatively, public users may run from the root folder:
     ```bash
     ./config.sh
     ```
     and ignore any non-critical errors.

5. **Synchronize Git Submodules**:
   ```bash
   git add .gitmodules
   git rm --cached Modules/MEGASharedRepo
   git rm --cached iosTransifex
   git submodule sync
   git submodule update --init --recursive
   ```

6. **Manually Pull Code if Needed**:
   - For folders that failed to fetch:
     - `Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK`
     - `Modules/DataSource/MEGASDK/Sources/MEGASDK`
     - `iMEGA/Vendor/SVProgressHUD`
     - `iMEGA/Vendor/LTHPasscodeViewController`

   Run:
   ```bash
   git checkout <latest-commit>
   git branch -D master
   git checkout -b master
   ```

   - For **SVProgressHUD** (use `custom_mega` branch) and **LTHPasscodeViewController** (use `custom-MEGA` branch):
     ```bash
     git checkout <latest-commit>
     git branch -D master
     git checkout -b <branch_name>
     ```

7. **Download and Unzip Required Dependencies**:
   Place these under:
   `Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK/bindings/Objective-C/3rdparty`
   - [include.zip](https://mega.nz/folder/TqBmgDyI#USMnXad535FoQtIkHPEb9g/file/SuxFjAjJ)
   - [webrtc.zip](https://mega.nz/folder/TqBmgDyI#USMnXad535FoQtIkHPEb9g/file/f7pBWQCY)

8. **Generate the DB Schema**:
   Navigate to:
   ```bash
   Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK/src
   ```
   and run:
   ```bash
   cmake -P genDbSchema.cmake
   ```

9. **Update Swift Package Dependency**:
   Replace:
   - `https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios`
   with:
   - [`https://github.com/meganz/mobile-analytics-ios.git`](https://github.com/meganz/mobile-analytics-ios.git)

---

### 🧪 Running the Project (MEGA Engineers)

1. In the terminal, run:
   ```bash
   ./configure.sh
   ```
2. Open the Xcode workspace:
   ```bash
   open iMEGA.xcworkspace
   ```
3. Select the `MEGA` target.
4. Build and run using ⌘R.

---

## 🧱 Building 3rd-Party Packages (Optional)

To build third-party dependencies manually:

1. Open a terminal at:
   ```bash
   Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/3rdparty
   ```

2. Run:
   ```bash
   sh build-all.sh --enable-chat
   ```
   > ⚠️ This may take ~30 minutes.

### Required Tools

- `autoconf`
- `automake`
- `cmake`
- `libtool`

### WebRTC Build Guide

Refer to the official documentation:  
👉 [WebRTC for iOS](https://webrtc.github.io/webrtc-org/native-code/ios/)