# Google Sign-In Setup (Android + Windows)

This project uses:
- **Android**: `google_sign_in` (native Google Sign-In)
- **Windows**: `desktop_webview_auth` (OAuth in an embedded webview)

If Google Sign-In shows **“Access blocked: Authorization Error”** with **`Error 401: invalid_client`**, it means the app is using an OAuth client ID that Google cannot find (or it is the wrong client type / redirect URI).

---

## 1) Firebase Console: enable Google provider

1. Open **Firebase Console** → your project.
2. Go to **Build → Authentication → Sign-in method**.
3. Enable **Google** provider.
4. Set a support email.

---

## 2) Android setup (fixes most Android sign-in failures)

### 2.1 Add Android app in Firebase

1. Firebase Console → **Project settings** → **Your apps**.
2. Add an **Android app** (or confirm it exists).
3. **Package name** must match your `applicationId`:
   - From `android/app/build.gradle`: `com.musiclyco.musicly`

### 2.2 Download and place `google-services.json`

1. Firebase Console → Android app → download **google-services.json**.
2. Put it here:
   - `android/app/google-services.json`

(You already have this file in the repo, but re-download if you changed SHA keys or app registration.)

### 2.3 Add SHA-1 + SHA-256 fingerprints in Firebase

This is required for Google Sign-In to work reliably.

#### Debug keystore (local development)
Run:

```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy **SHA1** and **SHA-256** into:
- Firebase Console → Project settings → Your Android app → **SHA certificate fingerprints**

#### Release keystore (for APK/AAB)
If you use your own keystore, run keytool against that file and add its SHA1/SHA-256 too.

If you upload an AAB to Play Console, you must also add the **App signing** SHA-1/256 from Play Console.

### 2.4 Build/run
After changing SHA keys or `google-services.json`, do:

```bash
flutter clean
flutter pub get
flutter run
```

---

## 3) Windows setup (fixes the `401: invalid_client` screen)

### Why this happens

Windows sign-in uses OAuth in a webview (`desktop_webview_auth`). The OAuth **clientId must be a Desktop OAuth client** from Google Cloud.

Using a Firebase **Web client ID** (often found in `google-services.json` as `client_type: 3`) frequently causes:
- `Error 401: invalid_client`

### 3.1 Create a Desktop OAuth Client ID

1. Open **Google Cloud Console** (same project as Firebase):
   - https://console.cloud.google.com/
2. Go to **APIs & Services → Credentials**.
3. Click **Create credentials → OAuth client ID**.
4. Application type: **Desktop app**.
5. Create it and copy the **Client ID**.

### 3.2 Configure redirect URI

This project defaults to:
- `http://localhost`

If you change it, you must also pass it via `--dart-define` (see below).

### 3.3 Pass the Desktop OAuth Client ID at build/run time

The code reads these values from `--dart-define`:

- `GOOGLE_OAUTH_CLIENT_ID_WINDOWS`
- `GOOGLE_OAUTH_REDIRECT_URI_WINDOWS` (optional, defaults to `http://localhost`)

Run (Windows PowerShell):

```powershell
flutter run -d windows --dart-define=GOOGLE_OAUTH_CLIENT_ID_WINDOWS=YOUR_DESKTOP_OAUTH_CLIENT_ID
```

Optional (if you changed redirect URI):

```powershell
flutter run -d windows `
  --dart-define=GOOGLE_OAUTH_CLIENT_ID_WINDOWS=YOUR_DESKTOP_OAUTH_CLIENT_ID `
  --dart-define=GOOGLE_OAUTH_REDIRECT_URI_WINDOWS=http://localhost
```

---

## 4) Optional but recommended: server client ID for consistent `idToken`

If you ever get an error like **"Google Sign-In failed to return an idToken"**, you may need a server client ID.

1. In Google Cloud Console → Credentials, find the **Web client ID** used by Firebase Auth.
2. Pass it as:

```powershell
flutter run -d windows `
  --dart-define=GOOGLE_OAUTH_CLIENT_ID_WINDOWS=YOUR_DESKTOP_OAUTH_CLIENT_ID `
  --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

For Android, this can also help token consistency.

---

## 5) Quick verification checklist

- Android:
  - **Google provider enabled** in Firebase Auth
  - `android/app/google-services.json` present
  - **SHA-1 and SHA-256** added for debug and release keys
  - Rebuilt after changes (`flutter clean`)

- Windows:
  - Created **Desktop app** OAuth client ID in Google Cloud
  - Running with `--dart-define=GOOGLE_OAUTH_CLIENT_ID_WINDOWS=...`

---

## 6) If it still fails

Send:
- The exact platform (Android/Windows)
- The exact error text from logs
- Whether you are using debug or release build on Android
