# 📱 news.ai

A modern, minimalist Flutter news application with AI-powered text-to-speech functionality and clean design.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

## ✨ Features

### 🎯 Core Functionality
- **📰 News Feed**: Browse AI-written news articles organized by categories
- **🔊 Text-to-Speech**: TTS-powered news reading with play/pause controls
- **📖 News Player**: Dedicated screen for listening to news with word tracking
- **🔖 Bookmarks**: Save articles for later reading
- **👤 User Authentication**: Secure login and registration system
- **🏷️ Categories**: Filter news by different categories (Technology, Sports, Politics, etc.)

### 🎨 User Experience
- **🎯 Minimal Design**: Clean, classic white background with black text
- **📱 Responsive UI**: Optimized for mobile devices
- **♾️ Infinite Scroll**: Seamless pagination for news articles
- **🔄 Pull to Refresh**: Easy content updates
- **🌐 Multilingual**: English UI with proper date formatting

### 🎵 Audio Features
- **▶️ Smart Playback**: Auto-play next article when current finishes
- **⏸️ Pause & Resume**: Continue from where you left off
- **📊 Word Tracking**: Visual highlighting of currently spoken words
- **🎛️ Playback Controls**: Forward, backward, play, and stop controls

### 👥 User Management
- **🔐 Secure Authentication**: JWT-based authentication system
- **👤 User Profiles**: Personal profile management
- **🛡️ Role-based Access**: Admin and Moderator roles
- **🔒 Secure Storage**: Encrypted local storage for sensitive data

## 🏗️ Architecture

### 📁 Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── haber.dart           # News article model
│   └── kategori.dart        # Category model
├── screens/                  # UI screens
│   ├── ana_ekran.dart       # Main news feed
│   ├── news_player_screen.dart # Audio player
│   ├── profil_ekrani.dart   # User profile
│   ├── kaydedilenler_ekrani.dart # Bookmarks
│   ├── haber_detay_ekrani.dart # Article details
│   ├── giris_ekrani.dart    # Login screen
│   └── kayit_ekrani.dart    # Registration screen
├── services/                 # Business logic
│   ├── api_service.dart     # REST API integration
│   ├── auth_service.dart    # Authentication service
│   └── tts_service.dart     # Text-to-speech service
├── widgets/                  # Reusable UI components
│   └── haber_karti.dart     # News card widget
└── utils/                    # Utility functions
    └── icon_helper.dart     # Category icons and translations
```

### 🛠️ Technology Stack
- **Frontend**: Flutter (Dart)
- **State Management**: Provider pattern
- **HTTP Client**: http package
- **Text-to-Speech**: flutter_tts
- **Secure Storage**: flutter_secure_storage
- **Pagination**: infinite_scroll_pagination
- **Fonts**: Google Fonts (Lato)
- **Date Formatting**: intl package

## 🚀 Getting Started

### 📋 Prerequisites
- Flutter SDK (3.5.3 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### 🔧 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/TahaYG/AINewsFlutter.git
   cd AINewsFlutter/Ai_News
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   - Update the `baseUrl` in `lib/services/api_service.dart`
   - For Android emulator: `http://10.0.2.2:5175`
   - For iOS simulator: `http://localhost:5175`
   - For physical device: Use your computer's IP address

4. **Run the application**
   ```bash
   flutter run
   ```

## 🎯 API Integration

The app connects to a REST API backend with the following endpoints:

- `POST /api/Auth/login` - User authentication
- `POST /api/Auth/register` - User registration
- `GET /api/Kategori` - Fetch categories
- `GET /api/Haber` - Fetch news articles with pagination
- `GET /api/Haber/{id}` - Get specific article
- `POST /api/Bookmark` - Bookmark management

## 🔊 Text-to-Speech Features

### Audio Controls
- **Play/Pause**: Toggle playback with visual feedback
- **Word Tracking**: Real-time highlighting of spoken words
- **Auto-Next**: Automatically play next article when current finishes

### Smart Features
- Resume from last position when pausing
- Stop playback when navigating away from player
- Visual progress indicator

## 🎨 Design Philosophy

### Minimal & Classic
- **Clean Interface**: White backgrounds with black text
- **Typography**: Lato font family for readability
- **Spacing**: Generous whitespace for better UX
- **Icons**: Consistent iconography throughout the app

### User-Centric
- **Intuitive Navigation**: Tab-based category browsing
- **Quick Actions**: Easy access to bookmarks and profile
- **Feedback**: Visual feedback for all interactions
- **Accessibility**: High contrast and readable fonts

## 🔧 Configuration

### Environment Setup
```dart
// lib/services/api_service.dart
static const String baseUrl = 'YOUR_API_URL_HERE';
```

### Localization
The app supports English localization with proper date formatting:
```dart
await initializeDateFormatting('en_US', null);
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

Created with ❤️ by Taha Yiğit Göksu

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Flutter community for helpful packages

---

⭐ **Star this repository if you found it helpful!**
