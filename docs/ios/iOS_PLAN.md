# Kantoku iOS Development Plan

This document outlines the implementation roadmap and coding standards for the Kantoku iOS application.

## 🏗 Project Architecture
- **Framework:** SwiftUI (iOS 16.0+)
- **Pattern:** MVVM (Model-View-ViewModel)
- **Backend:** Supabase (Auth, Database, Storage)
- **Integration:** n8n workflows for AI processing (Task generation, Review, Grading)

## 📁 Directory Structure
```
ios/kantoku/
├── App/           # App Entry & Global State
├── Models/        # Codable Data Structures
├── Views/         # SwiftUI View Files (UI)
├── ViewModels/    # Business Logic & State Management
├── Services/      # API, DB, & Hardware Clients
├── Components/    # Reusable UI Elements
├── Utils/         # Extensions & Constants
└── Resources/     # Assets & Localization
```

## 🚀 Implementation Roadmap

### Phase 1: Infrastructure & Foundation ✅
- [x] Initialize directory structure
- [x] Setup `Constants.swift` (Colors, Typography, Spacing)
- [x] Configure Supabase SDK and Environment variables
- [x] Create `AuthService` and `SupabaseService`

### Phase 2: Core Model & Component Library ✅
- [x] Define Models: `User`, `Task`, `Submission`, `Review`, `Test`
- [x] Implement Base Components: `PrimaryButton`, `TaskCard`, `StatusBadge`, `InputField`
- [x] Setup Navigation (Tab-based with `NavigationStack`)

### Phase 3: Authentication & Onboarding (P0) ✅
- [x] Login / Sign up views
- [x] Auth ViewModel with session management
- [x] Basic Profile setup

### Phase 4: Dashboard & Task Management (P0) ✅
- [x] Dashboard View: Summary cards & Daily progress
- [x] Task List & Detail views
- [x] Task filtering and categorization

### Phase 5: Submission & AI Review (P1) ✅
- [x] Audio/Video recording interface
- [x] File upload to Supabase Storage
- [x] Polling/Webhook integration for AI Review results

### Phase 6: Progress & Statistics (P1)
- [ ] Swift Charts integration for performance tracking
- [ ] Kana mastery heatmaps
- [ ] Achievement/Level system logic

### Phase 7: Testing & Quizzes (P2)
- [ ] Dynamic quiz generation interface
- [ ] Grading flow and feedback visualization

## 🎨 Design System Guidelines
- **Primary Color:** Deep Blue `#1A237E`
- **Secondary Colors:** Orange `#FF6F00`, Green `#2E7D32`, Red `#C62828`
- **Typography:** SF Pro (Display for Headers, Text for Body), Hiragino Sans for Japanese
- **Spacing:** 8pt grid system (8, 16, 24, 32)
- **Corners:** 12pt default corner radius for cards and buttons

## 🛠 Vibe Coding Instructions
1. **Context First:** Always read relevant documentation in `docs/ui/` before modifying UI.
2. **Modular Development:** Build Services and ViewModels before implementing the View.
3. **Strict MVVM:** Views should not contain business logic or direct Service calls.
4. **Safety:** Ensure sensitive keys are handled via `.env` or Secure Storage (Keychain).
5. **Verification:** Test on Simulator/Device for accessibility and Dark Mode compatibility.


## Related documents
- docs/ios/ui/*.md

