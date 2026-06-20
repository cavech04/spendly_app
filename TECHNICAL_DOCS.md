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

├── lib/

│   ├── main.dart               # Entry point, theme, AuthGate

│   ├── models/

│   │   └── expense.dart        # Expense data model

│   ├── services/

│   │   └── api_service.dart    # HTTP communication layer

│   ├── providers/

│   │   ├── expense_provider.dart   # Expense state (Riverpod)

│   │   ├── currency_provider.dart  # Currency preference state

│   │   └── budget_provider.dart    # Monthly budget state

│   ├── screens/

│   │   ├── login_screen.dart

│   │   ├── register_screen.dart

│   │   ├── home_screen.dart

│   │   ├── expense_list_screen.dart

│   │   ├── add_expense_screen.dart

│   │   ├── edit_expense_screen.dart

│   │   ├── stats_screen.dart

│   │   └── settings_screen.dart

│   └── widgets/

│       └── category_chart.dart     # Pie chart widget

└── backend/

├── main.py

├── database.py

├── models.py

├── schemas.py

├── auth.py

└── routers/

├── auth_router.py

└── expenses_router.py

### Frontend Layers

**UI Layer (`screens/`, `widgets/`):**
Responsible only for rendering and user interaction. No business logic embedded in widgets.

**Business Logic Layer (`providers/`):**
Three Riverpod providers manage global state:
- `ExpenseNotifier` — async list of expenses, CRUD operations
- `CurrencyNotifier` — selected currency, persisted in secure storage
- `BudgetNotifier` — monthly budget, persisted in secure storage

**Data Layer (`services/`, `models/`):**
`ApiService` handles all HTTP communication. `Expense` model handles JSON serialization/deserialization.

### Backend Layers

**Routing Layer (`routers/`):**
`auth_router.py` — `/auth` endpoints (register, login, me, delete account)
`expenses_router.py` — `/expenses` endpoints (list, create, update, delete)

**Business Logic (`auth.py`):**
JWT creation/verification, password hashing with bcrypt.

**Data Layer (`models.py`, `database.py`):**
SQLAlchemy ORM models mapped to SQLite tables. `get_db()` dependency injection for sessions.

---

## 3. Libraries Used

### Flutter
| Library | Version | Justification |
|---|---|---|
| flutter_riverpod | 2.x | Chosen over Provider for better async state support (AsyncNotifier), compile-time safety, and testability. Industry standard for Flutter state management. |
| http | 1.x | Lightweight HTTP client sufficient for REST API calls. No need for heavier alternatives like dio for this project scope. |
| flutter_secure_storage | 9.x | Stores JWT tokens, currency preference, and budget in the platform's secure keystore (Android Keystore / iOS Keychain). Prevents data theft from plaintext storage. |
| intl | 0.19 | Official Dart internationalization library for date and currency formatting. |
| fl_chart | 0.68 | Mature, well-maintained charting library for Flutter. Used for the category pie chart on the dashboard. Chosen for its declarative API and visual quality. |

### Python / FastAPI
| Library | Version | Justification |
|---|---|---|
| fastapi | 0.x | Chosen for automatic OpenAPI/Swagger documentation, Pydantic integration, and async support. More productive than Flask for API development. |
| sqlalchemy | 2.x | Mature ORM with strong typing support. Chosen over raw SQL for maintainability and security (prevents SQL injection). |
| pydantic | 2.x | Integrated with FastAPI for automatic request validation and response serialization. |
| python-jose | 3.x | Standard JWT implementation for Python. Used for creating and verifying access tokens. |
| passlib[bcrypt] | 1.x | Industry-standard password hashing. bcrypt chosen for its adaptive cost factor, making brute-force attacks computationally expensive. |
| uvicorn | 0.x | ASGI server required to run FastAPI. Chosen for performance and compatibility. |
| SQLite (via SQLAlchemy) | — | File-based database, zero configuration. Appropriate for a single-user mobile app. In production, PostgreSQL would be used. |

---

## 4. Technical Decisions

### State Management: Riverpod (AsyncNotifier)
We chose Riverpod over alternatives (Provider, BLoC, setState) because:
- `AsyncNotifier` natively handles loading/error/data states for API calls
- Compile-time safe — no runtime `context.read` errors
- Clear separation: UI watches state, notifier manages logic
- Three independent providers keep concerns separated (expenses, currency, budget)

### Authentication: JWT (stateless)
We chose JWT over session-based auth because:
- Stateless: backend does not need to store session data
- Mobile-friendly: token stored securely on device
- Standard: compatible with any future frontend (web, iOS)

Tokens are stored using `flutter_secure_storage` which uses Android Keystore on Android and iOS Keychain on iOS.

### Database: SQLite
SQLite was chosen for simplicity and zero-configuration setup. The SQLAlchemy ORM abstracts the database layer, making migration to PostgreSQL straightforward in production.

### Local Persistence: flutter_secure_storage
Currency preference and monthly budget are stored locally in secure storage rather than on the server. This is a deliberate design choice: these are UI preferences, not financial data, and storing them locally avoids unnecessary API calls and keeps the backend simpler.

### API Design: REST
Standard RESTful conventions:
- `POST /auth/register` — create user
- `POST /auth/login` — authenticate, receive JWT
- `GET /auth/me` — get current user
- `DELETE /auth/me` — delete account (GDPR right to erasure)
- `GET /expenses/` — list user's expenses
- `POST /expenses/` — create expense
- `PUT /expenses/{id}` — update expense
- `DELETE /expenses/{id}` — delete expense

All expense endpoints are protected by JWT authentication via FastAPI's `Depends()` mechanism.

---

## 5. Features

| Feature | Description |
|---|---|
| Register / Login | JWT-based authentication with bcrypt password hashing |
| Dashboard | Monthly total, expense count, category pie chart, recent expenses list |
| Budget tracking | Set a monthly budget; progress bar shows spending vs budget in real time |
| Add expense | Form with title, amount, category, date picker, optional note |
| Edit expense | Long press on any expense to edit all fields |
| Delete expense | Swipe left on any expense to delete with confirmation snackbar |
| Expense list | Full list with search bar and category filter chips |
| Statistics | Monthly total, average per day, top category, all-time total, monthly breakdown |
| Currency selector | Choose from USD, EUR, GBP, PLN, JPY, CAD, CHF — applied globally |
| Delete account | Permanently deletes account and all data (GDPR right to erasure) |
| Auto login | JWT token persisted securely; app skips login if token is present |

---

## 6. Regulatory Framework & Data Privacy

### GDPR (General Data Protection Regulation)
Spendly processes personal financial data of EU users, making GDPR applicable.

**Measures implemented:**
- **Lawful basis:** Contract (user registers and consents to data processing)
- **Data minimization:** Only name, email, and expense data collected. No location, device ID, or analytics.
- **Security:** Passwords hashed with bcrypt. JWT and preferences stored in encrypted secure storage.
- **Right to erasure (Art. 17):** Users can delete their account and all associated data via Settings → Delete Account. Backend cascades deletion to all expense records.
- **No plaintext secrets:** No API keys, passwords, or secrets committed to the repository.

**What would be needed in production:**
- HTTPS enforced (currently HTTP for local development only)
- Privacy policy accessible in-app
- Data Processing Agreement if using third-party services

---

## 7. Accessibility

- WCAG 2.1 AA contrast ratio target met via Material Design 3 color system
- Semantic labels on all

