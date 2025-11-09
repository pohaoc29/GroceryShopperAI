# Group Chat Web App + LLM Bot

FastAPI + MySQL + Flutter/Vanilla HTML/JS group chat with LLM bot integration.

> 🚀 **New here?** Start with [QUICKSTART.md](QUICKSTART.md) for the fastest setup!

---

## Quick Start (Dev)

### 1) MySQL Database Setup

```bash
# Run the schema file to create database, user, and tables
mysql -u root -p < sql/schema.sql

# Or manually:
mysql -u root -p
# Then paste contents of sql/schema.sql

# Load GroceryDataset.csv (optional)
cd backend
python load_groceries.py

# 2) Backend
cd backend
python -m venv .venv && source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Copy env and edit values
cp .env.example .env

# 3) Run app
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

Open http://localhost:8000

## LLM Model Configuration

The application now supports multiple LLM models:

- **OpenAI** (gpt-4o-mini) - Cloud API
- **Google Gemini** (2.5-flash) - Cloud API
- **TinyLlama** - Local model via Ollama

### Environment Configuration

Edit `backend/.env` with your API credentials:

```bash
# Database
DATABASE_URL=mysql+asyncmy://chatuser:chatpass@localhost:3306/groceryshopperai
JWT_SECRET=your-long-secret-key-here-minimum-32-characters
JWT_EXPIRE_MINUTES=43200
APP_HOST=0.0.0.0
APP_PORT=8000

# OpenAI (optional)
OPENAI_API_KEY=sk-your-openai-key-here

# Google Gemini (optional)
GEMINI_API_KEY=AIza_your-gemini-key-here
GEMINI_MODEL=models/gemini-2.5-flash

# Ollama (optional, for local TinyLlama)
# OLLAMA_API_BASE=http://localhost:11434
```

---

## 📁 Project Structure

```
GroceryShopperAI/
│
├── 📂 backend/                          # FastAPI Backend (Python)
│   ├── app.py                          # Main FastAPI application with all API routes
│   ├── db.py                           # SQLAlchemy ORM models (User, Room, Message, RoomMember)
│   ├── auth.py                         # JWT authentication, password hashing
│   ├── llm.py                          # LLM integration (OpenAI, Gemini, TinyLlama)
│   ├── websocket_manager.py            # WebSocket connection manager for real-time chat
│   ├── load_groceries.py               # Script to load GroceryDataset.csv into database
│   ├── requirements.txt                # Python dependencies (FastAPI, SQLAlchemy, Google Generative AI, etc.)
│   ├── .env.example                    # Environment variables template
│   ├── GroceryDataset.csv              # Grocery items dataset
│   └── __pycache__/                    # Python cache
│
├── 📂 flutter_frontend/                 # Flutter Cross-Platform App (Dart)
│   ├── lib/
│   │   ├── main.dart                   # App entry point, theme setup
│   │   ├── 📂 pages/                   # Screen pages
│   │   │   ├── login_page.dart         # Login & Signup screen
│   │   │   ├── home_page.dart          # Room list screen
│   │   │   ├── chat_detail_page.dart   # Chat screen
│   │   │   └── profile_page.dart       # User profile & model selection
│   │   ├── 📂 services/                # Business logic services
│   │   │   ├── api_client.dart         # HTTP client for backend API
│   │   │   ├── auth_service.dart       # Authentication logic
│   │   │   ├── storage_service.dart    # Secure local token storage
│   │   │   └── image_service.dart      # Image handling
│   │   ├── 📂 models/                  # Data models
│   │   │   └── message.dart            # Message model
│   │   ├── 📂 widgets/                 # Reusable UI components
│   │   │   ├── frosted_glass_button.dart
│   │   │   └── ... other widgets
│   │   └── 📂 themes/                  # Theme configuration
│   │       ├── colors.dart             # Color palette
│   │       ├── light_mode.dart         # Light theme
│   │       └── dark_mode.dart          # Dark theme
│   ├── ios/                            # iOS specific configuration
│   │   ├── Runner/                     # Xcode project
│   │   ├── Pods/                       # CocoaPods dependencies
│   │   └── Podfile                     # iOS dependency management
│   ├── android/                        # Android specific configuration
│   │   ├── app/                        # Android app module
│   │   ├── gradle/                     # Gradle build system
│   │   └── build.gradle                # Project-level build config
│   ├── web/                            # Web specific configuration
│   │   ├── index.html                  # Web entry point
│   │   └── manifest.json               # Web app manifest
│   ├── assets/                         # App resources
│   │   ├── fonts/                      # Custom fonts
│   │   └── ... images, etc
│   ├── pubspec.yaml                    # Flutter project config & dependencies
│   ├── pubspec.lock                    # Locked dependency versions
│   ├── analysis_options.yaml           # Dart analyzer rules
│   └── README.md                       # Flutter app documentation
│
├── 📂 frontend/                         # Optional: Vanilla HTML/JS Web Frontend
│   ├── index.html                      # Main HTML page
│   ├── app.js                          # JavaScript logic
│   └── styles.css                      # Styling
│
├── 📂 sql/                              # Database Schema
│   └── schema.sql                      # MySQL database setup script
│       ├── CREATE DATABASE groceryshopperai
│       ├── CREATE USER chatuser
│       ├── CREATE TABLE users
│       ├── CREATE TABLE rooms
│       ├── CREATE TABLE room_members
│       ├── CREATE TABLE messages
│       └── CREATE INDEXES
│
├── 📂 twa_android_src/                  # Trusted Web Activity (Android)
│   ├── app/
│   ├── build.gradle
│   └── settings.gradle
│
├── 📄 README.md                         # Main project documentation
├── 📄 QUICKSTART.md                     # Quick setup guide (5 min)
├── 📄 CHECKLIST.md                      # Setup verification checklist
├── 📄 requirements.txt                  # Reference copy of backend dependencies
└── 📄 .gitignore                        # Git ignore rules

```

---

## 🔧 Backend Architecture

### API Endpoints

#### Authentication

- `POST /api/signup` - Create new user account
- `POST /api/login` - User login, returns JWT token

#### Chat Rooms

- `GET /api/rooms` - List all rooms user is member of
- `POST /api/rooms` - Create new room
- `GET /api/rooms/{room_id}/members` - Get room members
- `POST /api/rooms/{room_id}/invite` - Invite user to room

#### Messages

- `GET /api/rooms/{room_id}/messages` - Get chat history (limit: 50)
- `POST /api/rooms/{room_id}/messages` - Send message (triggers LLM if @gro mentioned)

#### LLM Model Management

- `GET /api/users/llm-model?platform=ios|android|web|desktop` - Get available models
- `PUT /api/users/llm-model` - Change user's preferred model
- `POST /api/models/download-tinyllama` - Download TinyLlama locally
- `GET /api/models/download-progress` - Check download progress

#### WebSocket

- `WS /ws?room_id={room_id}` - Real-time chat connection

### Database Schema

#### Users Table

- id (PK)
- username (UNIQUE)
- password_hash
- preferred_llm_model (openai | gemini | tinyllama)
- created_at, updated_at

#### Rooms Table

- id (PK)
- name (UNIQUE)
- owner_id (FK → users.id)
- created_at

#### Room Members Table

- id (PK)
- room_id (FK → rooms.id)
- user_id (FK → users.id)
- joined_at

#### Messages Table

- id (PK)
- room_id (FK → rooms.id)
- user_id (FK → users.id, nullable)
- content (TEXT)
- is_bot (BOOLEAN)
- created_at

---

## 📱 Flutter Frontend Architecture

### Authentication Flow

1. User enters credentials on LoginPage
2. ApiClient sends POST request to `/api/login`
3. Backend returns JWT token
4. StorageService stores token securely
5. App navigates to HomePage

### Chat Flow

1. HomePage displays list of rooms
2. User selects room → ChatDetailPage
3. WebSocket connects to `/ws?room_id={id}`
4. Messages stream in real-time
5. User types message → POST to `/api/rooms/{id}/messages`
6. Message broadcast to all connected clients

### LLM Bot Trigger

1. User types message with `@gro` mention
2. Message sent to backend
3. Backend detects `@gro` mention
4. LLM called (based on user's preferred model)
5. Bot response created as message with `is_bot=true`
6. WebSocket broadcasts bot message to room

### Model Selection

1. User navigates to ProfilePage
2. Clicks "AI Model" setting
3. Dialog shows available models based on platform:
   - iOS/Android: OpenAI, Gemini
   - Web/Desktop: TinyLlama, OpenAI, Gemini
4. Selection saved via PUT `/api/users/llm-model`

---

## 🤖 LLM Integration

### Supported Models

| Model                | Type      | Provider | Setup          | Platform Support |
| -------------------- | --------- | -------- | -------------- | ---------------- |
| **gpt-4o-mini**      | Cloud API | OpenAI   | API Key        | All              |
| **gemini-2.5-flash** | Cloud API | Google   | API Key        | All              |
| **tinyllama**        | Local     | Ollama   | Local download | Desktop/Web only |

### LLM Processing

1. User sends message with `@gro`
2. Backend extracts user's preferred model
3. Calls appropriate LLM provider:
   - **OpenAI**: Uses `openai` library, sends to `api.openai.com`
   - **Gemini**: Uses `google-generativeai` SDK, sends to Google API
   - **TinyLlama**: Calls local `ollama` server
4. Response streamed back
5. Bot message inserted to database
6. WebSocket broadcasts to room

---

## 🔐 Technology Stack

### Backend

- **Framework**: FastAPI (async Python web framework)
- **Server**: Uvicorn (ASGI server)
- **Database ORM**: SQLAlchemy 2.0 (async)
- **Database Driver**: asyncmy (async MySQL)
- **Authentication**: PyJWT + passlib (bcrypt)
- **Real-time**: WebSocket via Starlette
- **LLM**: google-generativeai, openai (via requests), ollama (HTTP)

### Frontend

- **Framework**: Flutter 3.x (Dart)
- **HTTP**: http package
- **WebSocket**: web_socket_channel
- **Storage**: flutter_secure_storage (encrypted)
- **UI**: Material Design
- **Fonts**: google_fonts
- **Image Handling**: image_picker

### Database

- **MySQL 8.0+**
- **Character Set**: utf8mb4 (supports emoji, multiple languages)
- **Engine**: InnoDB (transactions, foreign keys)

### Infrastructure

- **Local Development**: Uvicorn + MySQL + Ollama (optional)
- **Deployment Ready**: Docker compatible, scalable

---

## 🚀 Key Features

✅ **Real-time Chat** - WebSocket for instant messaging  
✅ **LLM Integration** - Multiple AI models support  
✅ **Cross-platform** - iOS, Android, Web from single codebase  
✅ **Secure Auth** - JWT + bcrypt password hashing  
✅ **User Management** - Signup, login, profiles  
✅ **Room Management** - Create rooms, invite members  
✅ **Message History** - Persistent chat storage  
✅ **Model Selection** - Per-user LLM preference  
✅ **Responsive UI** - Works on all screen sizes

---

## 📊 Data Flow Diagram

```
User (App)
    ↓
Flutter Frontend (api_client.dart)
    ↓
HTTP/WebSocket
    ↓
FastAPI Backend (app.py)
    ↓
SQLAlchemy ORM (db.py)
    ↓
MySQL Database (sql/schema.sql)
    ↓
LLM Services (llm.py)
    ├→ OpenAI API
    ├→ Google Generative AI
    └→ Local Ollama Server
```

---

## 📦 Dependencies at a Glance

### Backend (requirements.txt)

- fastapi, uvicorn, starlette
- sqlalchemy, asyncmy
- passlib, pyjwt, python-jose
- google-generativeai, google-api-core, google-auth
- python-dotenv, httpx, requests
- pydantic, jinja2

### Frontend (pubspec.yaml)

- http, web_socket_channel
- flutter_secure_storage
- google_fonts, intl
- image_picker

---

## 📝 File Organization Tips

- **Backend changes**: Edit files in `backend/`, restart Uvicorn
- **Frontend changes**: Edit files in `flutter_frontend/lib/`, hot reload in Flutter
- **Database changes**: Modify `sql/schema.sql`, run migration script
- **Configuration**: Update `backend/.env` for API keys
- **Dependencies**: Update `backend/requirements.txt` or `flutter_frontend/pubspec.yaml`

---

## 🔄 Development Workflow

1. **Backend Development**

   - Edit `backend/app.py`, `db.py`, `llm.py`
   - Restart Uvicorn to see changes
   - Check logs in Terminal 1

2. **Frontend Development**

   - Edit files in `flutter_frontend/lib/`
   - Hot reload: Press `r` in Flutter console
   - Check logs in Terminal 2

3. **Database Changes**

   - Edit `sql/schema.sql`
   - Run: `mysql -u root -p < sql/schema.sql`
   - Restart backend to reconnect

4. **Testing**
   - Use app UI to test features
   - Check backend logs for API calls
   - Use database client to verify data
