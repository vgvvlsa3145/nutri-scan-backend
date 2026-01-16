# Nutri Scan Mobile App

Flutter mobile application for smart food recognition and intelligent nutrition assistance.

## Features

- **User Authentication**: Registration and login
- **Profile Management**: User profile with BMI calculation and daily requirements
- **Food Image Scanning**: Capture or upload food images for detection
- **YOLO-Based Food Detection**: Automatic food item identification
- **Nutrition Analysis**: Extract calories, proteins, carbs, fats, vitamins
- **Nutrition Visualization**: Pie charts and summary tables
- **RDA Comparison**: Compare nutrients with recommended daily allowances
- **Diet Plan Generation**: Personalized diet plans based on nutritional needs
- **Daily Reports**: Track daily nutrition intake
- **Recipe Suggestions**: Get healthy recipes based on available ingredients
- **Location-Based Recommendations**: Region-specific food suggestions

## Setup

### Prerequisites

- Flutter SDK (3.6.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Backend API running (see backend README)

### Installation

1. Navigate to the app directory:
```bash
cd nutri_scan_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update API configuration:
   - Open `lib/utils/app_config.dart`
   - Update `baseUrl` to match your backend URL:
     - Android Emulator: `http://10.0.2.2:5000/api`
     - iOS Simulator: `http://localhost:5000/api`
     - Physical Device: `http://YOUR_COMPUTER_IP:5000/api`

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── profile_model.dart
│   └── food_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── profile_provider.dart
│   └── food_provider.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── profile/
│   │   └── profile_setup_screen.dart
│   ├── food/
│   │   ├── food_scan_screen.dart
│   │   └── food_result_screen.dart
│   ├── reports/
│   │   └── reports_screen.dart
│   ├── recipes/
│   │   └── recipes_screen.dart
│   └── diet/
│       └── diet_plan_screen.dart
├── services/                 # API services
│   └── api_service.dart
└── utils/                     # Utilities
    └── app_config.dart
```

## Usage

1. **Register/Login**: Create an account or login with existing credentials
2. **Setup Profile**: Enter your personal information (name, age, gender, weight, height)
3. **Scan Food**: Use camera or gallery to capture food images
4. **View Analysis**: See detected foods, nutrition breakdown, and RDA comparison
5. **Get Recommendations**: Receive suggestions to increase or reduce nutrients
6. **Generate Diet Plan**: Get personalized meal plans based on your needs
7. **View Reports**: Check daily nutrition reports
8. **Find Recipes**: Get recipe suggestions based on available ingredients

## Dependencies

- `provider`: State management
- `http`: HTTP requests
- `image_picker`: Camera and gallery access
- `fl_chart`: Charts and visualizations
- `shared_preferences`: Local storage
- `geolocator`: Location services
- And more (see `pubspec.yaml`)

## Notes

- Make sure the backend API is running before using the app
- For food detection, ensure YOLO model is properly configured in the backend
- Location services require appropriate permissions
- Image upload requires camera/storage permissions

## Troubleshooting

- **Connection Error**: Check if backend is running and URL is correct
- **Image Upload Fails**: Check camera/storage permissions
- **No Food Detected**: Ensure YOLO model is properly set up in backend
