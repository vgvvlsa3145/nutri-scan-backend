# Deploying NutriScan to the Cloud (Render + MongoDB Atlas)

This guide helps you deploy your backend to the internet so your app works anywhere, not just on your home WiFi.

---

## Part 1: Set up the Cloud Database (MongoDB Atlas)
Since your local laptop isn't always on, we need a database in the cloud.

1.  **Create an Account**: Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas/register) and sign up (Free).
2.  **Create a Cluster**:
    *   Choose the **Shared** (Free) option.
    *   Select provider (AWS) and region (closest to you).
    *   Click **Create Cluster** (bottom of page).
3.  **Create User**:
    *   Go to **Database Access** (on the left menu).
    *   Click **+ Add New Database User**.
    *   **Username:** `admin`
    *   **Password:** `password123` (or choose your own, but remember it!).
    *   **Role:** Select "Read and write to any database".
    *   Click **Add User**.
4.  **Allow Access**:
    *   Go to **Network Access** (on the left menu).
    *   Click **+ Add IP Address**.
    *   Click **Allow Access from Anywhere** (You will see `0.0.0.0/0`).
    *   Click **Confirm**.
5.  **Get Connection String**:
    *   Go to **Database** (Cluster view).
    *   Click **Connect** button.
    *   Select **Drivers** (Python/3.12 or similar).
    *   **COPY** the connection string. It looks like:
        `mongodb+srv://admin:<password>@cluster0.abcde.mongodb.net/?retryWrites=true&w=majority`
    *   **IMPORTANT:** Replace `<password>` in that text with your actual password. **Save this URL.**

---

## Part 2: Deploy Backend to Render (Detailed Steps)

### Step A: Connect GitHub
1.  Go to [Render.com](https://render.com/) and Sign Up.
    *   **Recommended:** Click "Sign up with GitHub".
2.  Once logged in, look at the top right corner.
3.  Click the **"New +"** button.
4.  Select **"Web Service"**.
5.  On the "Connect a repository" page:
    *   You should see your `nutri-scan-backend` repo listed.
    *   Click the **"Connect"** button next to it.

### Step B: Configure the Service
Fill in the form with these EXACT values:

| Field | Value |
| :--- | :--- |
| **Name** | `nutri-scan-backend` |
| **Region** | Choose the one closest to you (e.g., Singapore, Frankfurt) |
| **Branch** | `master` (or `main`) |
| **Root Directory** | `nutri_scan_backend` (Important! Type exactly this) |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `gunicorn app:app` |
| **Instance Type** | Free |

### Step C: Environment Variables (The Secret Keys)
Scroll down to the **"Environment Variables"** section. Click **"Add Environment Variable"** for each row below:

| Key | Value |
| :--- | :--- |
| `PYTHON_VERSION` | `3.10.11` |
| `MONGO_URI` | *(Paste your MongoDB connection string from Part 1)* |
| `JWT_SECRET_KEY` | `super-secret-key-change-this` |
| `GROQ_API_KEY` | `gsk_...` (Paste your Groq Key here) |
| `GEMINI_API_KEY` | `AIza...` (Paste your Gemini Key here) |

### Step D: Launch!
1.  Click **"Create Web Service"** at the bottom.
2.  Render will start building your app. You will see text scrolling in the black box.
3.  Wait about 2-5 minutes.
4.  Look for: **"Your service is live"**.
5.  **COPY YOUR URL:** At the top left, under the name, you will see a URL like `https://nutri-scan-backend.onrender.com`.

---

## Part 3: Update and Rebuild App

Now that your brain is in the cloud, tell the body (App) where to find it.

1.  Open `lib/utils/app_config.dart`.
2.  Paste your Render URL into `productionBaseUrl`:
    ```dart
    static const String productionBaseUrl = 'https://nutri-scan-backend.onrender.com/api';
    ```
    *(Make sure to keep the `/api` at the end!)*
3.  Change `useProduction` to `true`:
    ```dart
    static const bool useProduction = true;
    ```
4.  **Rebuild the APK:**
    Open terminal in `nutri_scan_app` folder and run:
    ```bash
    flutter build apk --release
    ```

**Transfer this new APK to your phone, and you are done!** 🌍
