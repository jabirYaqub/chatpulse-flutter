# flutter-chat-app 💬

A modern, real-time chat application built with Flutter and Firebase. Connect with friends, send instant messages, and manage your social connections through an intuitive and beautiful interface.

![Flutter](https://img.shields.io/badge/Flutter-3.27.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![GetX](https://img.shields.io/badge/GetX-9C27B0?style=for-the-badge&logo=flutter&logoColor=white)


<img width="169" height="370" alt="image" src="https://github.com/user-attachments/assets/c3a4e3ad-e0b1-454d-ba90-7abb13421e7a" />
<img width="167" height="360" alt="image" src="https://github.com/user-attachments/assets/e2442f73-dd4d-489f-ba27-5ddfe059111a" />
<img width="167" height="364" alt="image" src="https://github.com/user-attachments/assets/75a21f0c-0909-410e-9aa7-d5ae6ea93844" />
<img width="171" height="373" alt="image" src="https://github.com/user-attachments/assets/736a19e3-a514-4101-b1b4-57333fbb8b25" />
<img width="171" height="364" alt="image" src="https://github.com/user-attachments/assets/a271659c-5397-4d1c-98e0-7e44533f9d76" />
<img width="167" height="359" alt="image" src="https://github.com/user-attachments/assets/88e49b43-8ba0-4537-92c0-7eb8374bd37f" />
<img width="167" height="364" alt="image" src="https://github.com/user-attachments/assets/d5ea7319-ab50-4d2c-b11a-9e320a511887" />
<img width="165" height="362" alt="image" src="https://github.com/user-attachments/assets/6339165d-540f-49c3-9208-6a45e9d714ce" />
<img width="166" height="365" alt="image" src="https://github.com/user-attachments/assets/bee2e56c-3780-4834-a669-22ff2b6e77e5"

## ✨ Features

### 🔐 Authentication
- **Secure Registration & Login** with email/password
- **Password Reset** via email verification
- **Profile Management** with photo upload
- **Account Security** with re-authentication for sensitive operations

### 💬 Real-time Messaging
- **Instant Message Delivery** with WebSocket connections
- **Read Receipts** (✓ sent, ✓✓ delivered, ✓✓ read)
- **Typing Indicators** to see when someone is composing
- **Message Management** (edit, delete, copy)
- **Chat History** with efficient pagination

### 👥 Friend System
- **User Discovery** - Search and find other users
- **Friend Requests** - Send, receive, accept, decline
- **Relationship Management** - Block/unblock users
- **Online Status** - See who's active and last seen times
- **Friend Lists** with search functionality

### 🔔 Smart Notifications
- **Real-time Alerts** for messages and friend activities
- **Notification Center** with organized history
- **Smart Navigation** - Tap to go to relevant content
- **Batch Operations** - Mark all as read, bulk actions

### 🎨 Modern UI/UX
- **Material Design 3** with custom theming
- **Cross-platform** support (Android, iOS, Web)
- **Responsive Design** for all screen sizes
- **Smooth Animations** and transitions
- **Dark/Light Theme** ready architecture

### 🚀 Advanced Features
- **Chat Filtering** (All, Unread, Recent, Active)
- **Search Conversations** and message history
- **Unread Counters** with visual badges
- **Profile Customization** with Cloudinary integration
- **Soft Delete** for chats and messages

## 📱 Screenshots


## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.27.0+ |
| **Language** | Dart 3.6.2+ |
| **State Management** | GetX 4.7.2 |
| **Backend** | Firebase (Firestore, Auth) |
| **Image Storage** | Cloudinary |
| **Architecture** | Clean MVC with GetX |
| **UI Design** | Material Design 3 |

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.27.0 or later)
- [Dart SDK](https://dart.dev/get-dart) (3.6.2 or later)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Firebase Account](https://firebase.google.com/)
- [Cloudinary Account](https://cloudinary.com/) (for image uploads)

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/flutter-chat-app.git
cd flutter-chat-app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "ChatApp Flutter"
3. Enable **Authentication** with Email/Password provider
4. Create **Firestore Database** in production mode

#### Configure Android
1. Add Android app with package name: `com.example.chatAppFlutter`
2. Download `google-services.json`
3. Place it in `android/app/` directory

#### Configure iOS
1. Add iOS app with bundle ID: `com.example.chatAppFlutter`
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/` directory

#### Set Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read all profiles but only edit their own
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Messages between authenticated users only
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // Chats accessible only by participants
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
    
    // Friend requests and friendships
    match /friendRequests/{requestId} {
      allow read, write: if request.auth != null;
    }
    match /friendships/{friendshipId} {
      allow read, write: if request.auth != null;
    }
    
    // Personal notifications only
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

### 4. Cloudinary Setup (for Profile Pictures)

1. Create account at [Cloudinary](https://cloudinary.com/)
2. Get your **Cloud Name** and create an **Upload Preset**
3. Update `lib/services/storage_service.dart`:

```dart
final String _cloudName = 'your_cloud_name_here';
final String _uploadPreset = 'your_upload_preset_here';
```

### 5. Run the Application

```bash
# Check your Flutter installation
flutter doctor

# Run on your device/emulator
flutter run

# Build for release
flutter build apk        # Android
flutter build ios        # iOS
```

## 📁 Project Structure

```
lib/
├── 📁 config/           # App configuration and themes
│   └── app_theme.dart   # Custom theme definitions
├── 📁 controllers/      # GetX controllers (9 files)
│   ├── auth_controller.dart
│   ├── chat_controller.dart
│   ├── home_controller.dart
│   └── ...
├── 📁 models/          # Data models (6 files)
│   ├── user_model.dart
│   ├── message_model.dart
│   └── ...
├── 📁 services/        # Business logic (3 files)
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── 📁 views/           # UI screens (12+ files)
│   ├── auth/           # Authentication screens
│   ├── chat_view.dart
│   ├── home_view.dart
│   └── ...
├── 📁 widgets/         # Reusable components (6 files)
│   ├── chat_list_item.dart
│   ├── message_bubble.dart
│   └── ...
├── 📁 routes/          # Navigation setup
│   ├── app_routes.dart
│   └── app_pages.dart
└── main.dart           # App entry point
```

## 🔧 Key Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  get: ^4.7.2                    # State management & routing
  firebase_core: ^3.15.1         # Firebase core
  firebase_auth: ^5.6.2          # Authentication
  cloud_firestore: ^5.6.11       # Real-time database
  image_picker: ^1.2.0           # Image selection
  http: ^1.5.0                   # HTTP requests
  uuid: ^4.5.1                   # Unique ID generation
```

## 🎯 Key Features Deep Dive

### Real-time Messaging System
- **WebSocket Integration**: Instant message delivery
- **Message Status Tracking**: Complete lifecycle management
- **Offline Support**: Messages sync when connection restored
- **Message Encryption**: Secure data transmission

### Advanced Friend Management
- **Relationship States**: None, Pending, Friends, Blocked
- **Smart Notifications**: Auto-generated for all friend activities
- **Privacy Controls**: Complete blocking and visibility management
- **Search & Discovery**: Find users with advanced filtering

### Professional UI/UX
- **Material Design 3**: Latest design system implementation
- **Consistent Theming**: Unified color and typography system
- **Responsive Layouts**: Optimized for all screen sizes
- **Accessibility**: Screen reader support and proper contrast

## 🚨 Troubleshooting

### Common Issues

**Firebase Connection Failed**
```bash
# Verify configuration files exist
ls android/app/google-services.json
ls ios/Runner/GoogleService-Info.plist

# Clean and rebuild
flutter clean && flutter pub get
```

**Build Errors**
```bash
flutter doctor -v
flutter clean
flutter pub deps
```

**Real-time Updates Not Working**
- Check Firestore security rules
- Verify internet connection
- Restart app to refresh listeners

## 🔐 Security

- **Firebase Security Rules**: Strict data access permissions
- **Input Validation**: Comprehensive form and data validation
- **Authentication**: Secure email/password with re-auth for sensitive operations
- **Data Encryption**: TLS in transit, AES-256 at rest
- **Privacy Controls**: User-controlled blocking and visibility

## 🌐 Platform Support

| Platform | Version | Status |
|----------|---------|--------|
| **Android** | API 21+ (5.0+) | ✅ Supported |
| **iOS** | 12.0+ | ✅ Supported |
| **Web** | Modern browsers | ✅ Supported |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Jabir Bin Yaqub**
- GitHub: [@your-github-username](https://github.com/jabirYaqub)
- Email: jabiryaqub5gmail@example.com

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev/) for the amazing framework
- [Firebase](https://firebase.google.com/) for backend services
- [GetX](https://pub.dev/packages/get) for state management
- [Cloudinary](https://cloudinary.com/) for image management
- [Material Design](https://material.io/) for design guidelines

---

<div align="center">

**⭐ Star this repository if you found it helpful!**

Made with ❤️ by [Jabir Bin Yaqub](https://github.com/jabirYaqub)

</div>
