# Spendly — Technical Documentation

## 1. How to Run

### Requirements
- Flutter SDK 3.x
- Python 3.10+
- Android emulator or physical Android device

### Backend Setup
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0
```
API available at `http://localhost:8000`  
Swagger UI: `http://localhost:8000/docs`

### Flutter App Setup
```bash
flutter pub get
flutter run
```
Update `baseUrl` in `lib/services/api_service.dart` with your machine's local IP address.

---

## 2. Architecture

Spendly follows a clean layered architecture with strict separation between UI, business logic, and data layers.

### Overall Structure

spendly_app/

├── lib/                    # Flutter frontend

│   ├── main.dart           # Entry point

│   ├── models/             # Data layer: Expense model

│   ├── services/           # Data layer: API communication

│   ├── providers/          # Business logic: Riverpod state

│   ├── screens/            # UI layer: 5 screens

│   └── widgets/            # UI layer: reusable components

└── backend/                # FastAPI backend

├── main.py

├── database.py

├── models.py

├── schemas.py

├── auth.py

└── routers/

### Frontend Layers

**UI Layer (`screens/`, `widgets/`):**  
Responsible only for rendering and user interaction. No business logic.

**Business Logic Layer (`providers/`):**  
`ExpenseNotifier` (Riverpod `AsyncNotifier`) manages the expense list state, handles loading/error/data states, and delegates API calls to the service layer.

**Data Layer (`services/`, `models/`):**  
`ApiService` handles all HTTP communication with the backend. `Expense` model handles JSON serialization/deserialization.

### Backend Layers

**Routing Layer (`routers/`):**  
`auth_router.py` handles `/auth` endpoints. `expenses_router.py` handles `/expenses` endpoints.

**Business Logic (`auth.py`):**  
JWT creation/verification, password hashing with bcrypt.

**Data Layer (`models.py`, `database.py`):**  
SQLAlchemy ORM models mapped to SQLite tables. `get_db()` dependency injection for database sessions.

---

## 3. Libraries Used

### Flutter
| Library | Version | Justification |
|---|---|---|
| flutter_riverpod | 2.x | Chosen over Provider for better support of async state (AsyncNotifier), compile-time safety, and testability. Industry standard for Flutter state management. |
| http | 1.x | Lightweight HTTP client sufficient for REST API calls. No need for heavier alternatives like dio for this project scope. |
| flutter_secure_storage | 9.x | Stores JWT tokens in the platform's secure keystore (Android Keystore / iOS Keychain). Prevents token theft from plaintext storage. |
| intl | 0.19 | Official Dart internationalization library for date and currency formatting. |

### Python / FastAPI
| Library | Version | Justification |
|---|---|---|
| fastapi | 0.x | Chosen for its automatic OpenAPI/Swagger documentation generation, Pydantic integration, and async support. More productive than Flask for API development. |
| sqlalchemy | 2.x | Mature ORM with strong typing support. Chosen over raw SQL for maintainability and security (prevents SQL injection). |
| pydantic | 2.x | Integrated with FastAPI for automatic request validation and response serialization. |
| python-jose | 3.x | Standard JWT implementation for Python. Used for creating and verifying access tokens. |
| passlib[bcrypt] | 1.x | Industry-standard password hashing. bcrypt chosen for its adaptive cost factor, making brute-force attacks computationally expensive. |
| uvicorn | 0.x | ASGI server required to run FastAPI. Chosen for its performance and compatibility with FastAPI. |
| SQLite (via SQLAlchemy) | — | File-based database, zero configuration required. Appropriate for a single-user mobile app. In production, PostgreSQL would be used. |

---

## 4. Technical Decisions

### State Management: Riverpod (AsyncNotifier)
We chose Riverpod over alternatives (Provider, BLoC, setState) because:
- `AsyncNotifier` natively handles loading/error/data states required for API calls
- Compile-time safe — no runtime `context.read` errors
- Clear separation: UI watches state, notifier manages logic

### Authentication: JWT (stateless)
We chose JWT over session-based auth because:
- Stateless: backend does not need to store session data
- Mobile-friendly: token stored securely on device
- Standard: compatible with any future frontend (web, iOS)

Tokens are stored using `flutter_secure_storage` which uses Android Keystore on Android and iOS Keychain on iOS, preventing access from other apps.

### Database: SQLite
SQLite was chosen for its simplicity and zero-configuration setup, appropriate for a development/prototype context. The SQLAlchemy ORM abstracts the database layer, making migration to PostgreSQL straightforward in production.

### API Design: REST
Standard RESTful conventions:
- `POST /auth/register` — create user
- `POST /auth/login` — authenticate, receive JWT
- `GET /auth/me` — get current user
- `DELETE /auth/me` — delete account (GDPR right to erasure)
- `GET /expenses/` — list user's expenses
- `POST /expenses/` — create expense
- `DELETE /expenses/{id}` — delete expense

All expense endpoints are protected by JWT authentication via FastAPI's `Depends()` mechanism.

---

## 5. Regulatory Framework & Data Privacy

### GDPR (General Data Protection Regulation)
Spendly processes personal financial data of EU users, making GDPR applicable.

**Measures implemented:**
- **Lawful basis:** Contract (user registers and consents to data processing)
- **Data minimization:** Only name, email, and expense data collected. No location, device ID, or analytics.
- **Security:** Passwords hashed with bcrypt. JWT stored in encrypted secure storage.
- **Right to erasure (Art. 17):** Users can delete their account and all associated data via Settings → Delete Account. Backend cascades deletion to all expense records.
- **No plaintext secrets:** No API keys, passwords, or secrets committed to the repository. `SECRET_KEY` loaded from environment variable in production.

**What would be needed in production:**
- HTTPS enforced (currently HTTP for local development only)
- Privacy policy accessible in-app
- Data Processing Agreement if using third-party services
- Cookie/consent banner if adding analytics

### Accessibility
- WCAG 2.1 AA contrast ratio target met via Material Design 3 color system
- Semantic labels on all interactive elements for TalkBack (Android) / VoiceOver (iOS)
- Minimum 48x48dp touch targets
- Scalable text (respects system font size)