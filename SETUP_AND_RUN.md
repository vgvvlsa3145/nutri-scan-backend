# NutriScan Project - Exact Setup & Run Documentation

This document contains **every single detail** you need to set up this project on a brand new Windows PC from scratch (0 to 100%).

---

## 🛑 1. Software Checklist (Exact Versions)
You **MUST** install these specific versions to guarantee it works.

| Software | Version Required | Download Link / Notes |
| :--- | :--- | :--- |
| **OS** | Windows 10 or 11 | 64-bit |
| **Java (JDK)** | **OpenJDK 17** | [Download Microsoft Build of OpenJDK 17](https://learn.microsoft.com/en-us/java/openjdk/download#openjdk-17) |
| **Python** | **3.10.x** (e.g., 3.10.11) | [Download Python 3.10.11](https://www.python.org/downloads/release/python-31011/)<br>**IMPORTANT:** Check "Add Python to PATH" during install. |
| **Flutter SDK** | **3.38.6** (Stable) | [Download Flutter Windows](https://docs.flutter.dev/get-started/install/windows)<br>Extract to `C:\flutter`. |
| **Android Studio**| Latest Version | [Download](https://developer.android.com/studio)<br>(Required only for SDK tools, not editing). |
| **VS Code** | Latest Version | [Download](https://code.visualstudio.com/)<br>(Recommended Code Editor). |

---

## 🛠️ 2. Installation Steps (Step-by-Step)

### Step A: Install Java JDK 17
1.  Download the `.msi` installer for OpenJDK 17.
2.  Run it. Keep defaults.
3.  **Verify:** Open Command Prompt (`cmd`) and type: `java -version`.
    *   *Success Output:* `openjdk version "17.0.17"...`

### Step B: Install Python 3.10
1.  Run the Python installer.
2.  **CRITICAL:** Check the box ** Add Python 3.10 to PATH** at the bottom.
3.  Click "Install Now".
4.  **Verify:** Open new `cmd` and type: `python --version`.
    *   *Success Output:* `Python 3.10.11`

### Step C: Install Flutter SDK
1.  Extract the flutter zip file to `C:\src\flutter` (or `C:\flutter`).
2.  Add to PATH:
    *   Search Windows for "Edit environment variables for your account".
    *   Double-click `Path`.
    *   Click "New" -> `C:\src\flutter\bin`.
    *   Click OK.
3.  **Verify:** Open new `cmd` and type: `flutter --version`.

### Step D: Setup Android SDK
1.  Install Android Studio.
2.  Open it -> "SDK Manager" (More Actions > SDK Manager).
3.  **SDK Platforms Tab:** Check **Android 14.0 ("UpsideDownCake") (API Level 34)**.
4.  **SDK Tools Tab:** Check **Android SDK Command-line Tools (latest)**.
5.  Click "Apply" to download everything.
6.  **Accept Licenses:**
    *   Open `cmd` (Run as Admin).
    *   Run: `flutter doctor --android-licenses`.
    *   Type `y` to all questions.

---

## 📂 3. Project Setup

### Step A: Get the Code
1.  Copy the `nutri_scan_app` project folder to your Desktop.

### Step B: Install Backend Dependencies
1.  Open `cmd` inside `nutri_scan_app/nutri_scan_backend`.
2.  Run:
    ```bash
    pip install -r requirements.txt
    ```
    *This installs Flask, YOLO, Groq, Mongo tools, etc.*

### Step C: Configure IP Address
1.  Open `cmd` and type `ipconfig`.
2.  Note YOUR "IPv4 Address" (e.g., `192.168.1.5`).
3.  Open `nutri_scan_app/lib/utils/app_config.dart`.
4.  Edit **Line 10**:
    ```dart
    static const String _androidLocalBaseUrl = 'http://192.168.1.5:5000/api';
    ```
    *(Replace with YOUR IP).*

---

## 🚀 4. How to Run (Daily Routine)

### Step A: Start the Backend (Brain) 🧠
1.  Open VS Code or Terminal.
2.  Navigate to backend: `cd nutri_scan_backend`
3.  Run:
    ```bash
    python app.py
    ```
    *Success:* You see `Running on all addresses (0.0.0.0)`.

### Step B: Run the App on Phone (Body) 📱
1.  Connect your Android phone via USB.
2.  Enable "USB Debugging" on phone settings.
3.  Navigate to app folder: `cd nutri_scan_app`
4.  Run:
    ```bash
    flutter run --debug
    ```
    *(Or install the APK provided earlier).*

---

## 🚑 Troubleshooting

**Issue: "Gradle task assembleDebug failed"**
*   **Fix:** Ensure you are using Java 17 and have accepted licenses.
*   Run: `flutter clean` then try again.

**Issue: "App won't connect to server"**
*   **Fix:** Ensure Phone and Laptop are on the **SAME WiFi**.
*   Check that `app_config.dart` has the correct Laptop IP.
*   Turn off Windows Firewall temporarily to test.

**Issue: "SDK location not found"**
*   **Fix:** Create a file `android/local.properties` with:
    ```
    sdk.dir=C:\\Users\\YOUR_USER\\AppData\\Local\\Android\\sdk
    flutter.sdk=C:\\src\\flutter
    ```
