# Spendly 💸

A personal expense tracker mobile app built with Flutter and FastAPI.

## Target Users
Budget-conscious individuals (especially students) who want a simple, private way to track daily expenses by category.

## Features
- Register and login with JWT authentication
- Add, view, and delete expenses
- Filter expenses by category
- Dashboard with monthly spending summary
- Secure token storage (flutter_secure_storage)
- Full data deletion (GDPR right to erasure)

---

## How to Run

### Prerequisites
- Flutter SDK 3.x
- Python 3.10+
- Android emulator or physical device

### Backend (FastAPI)

```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0
```

The API will be available at `http://localhost:8000`.  
Interactive docs: `http://localhost:8000/docs`

### Flutter App

```bash
cd spendly_app
flutter pub get
flutter run
```

> **Note:** update `baseUrl` in `lib/services/api_service.dart` to match your machine's local IP address if running on a physical device or emulator.

---

## Architecture

The project is split into two parts:

### Frontend (Flutter)
Follows a layered architecture with clear separation of concerns:

lib/

├── main.dart               # Entry point, theme, AuthGate

├── models/                 # Data models (Expense)

├── services/               # API communication (ApiService)

├── providers/              # State management (Riverpod)

├── screens/                # UI screens

└── widgets/                # Reusable UI components

### Backend (FastAPI)

backend/

├── main.py                 # App entry point, CORS, router registration

├── database.py             # SQLAlchemy engine and session

├── models.py               # ORM models (User, Expense)

├── schemas.py              # Pydantic schemas for validation

├── auth.py                 # JWT creation, password hashing, auth dependency

└── routers/

├── auth_router.py      # /auth endpoints (register, login, me, delete)

└── expenses_router.py  # /expenses endpoints (list, create, delete)

---

## Libraries Used

### Flutter
| Library | Purpose |
|---|---|
| flutter_riverpod | State management |
| http | HTTP requests to the backend |
| flutter_secure_storage | Secure JWT token storage |
| intl | Date and currency formatting |

### Python / FastAPI
| Library | Purpose |
|---|---|
| fastapi | REST API framework |
| sqlalchemy | ORM for SQLite database |
| pydantic | Request/response validation |
| python-jose | JWT token creation and verification |
| passlib[bcrypt] | Password hashing |
| uvicorn | ASGI server |

---

## Data Privacy & GDPR

Spendly processes personal financial data, which falls under GDPR for EU users:

- Passwords are hashed with **bcrypt** and never stored in plaintext
- JWT tokens are stored in **secure storage** (encrypted on device), not in plaintext shared preferences
- No sensitive data is hardcoded or committed to the repository
- Users can **delete their account and all associated data** at any time (right to erasure, Art. 17 GDPR)
- Data is transmitted over the local network only; in production, HTTPS would be enforced

---

## Accessibility

- Semantic labels on interactive elements for screen reader support (TalkBack/VoiceOver)
- Minimum touch target size of 48x48dp on all buttons
- Text uses scalable units (Flutter default) to respect system font size preferences
- Sufficient color contrast following Material Design 3 guidelines
- Error states and loading states communicated visually and semantically

---

## Git Workflow

This project follows a PR-based workflow:
- `main` branch is protected (no direct pushes)
- All features developed on separate branches
- Changes merged via Pull Requests
