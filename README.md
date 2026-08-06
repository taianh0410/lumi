# LUMI AI

LUMI AI is a Socratic tutoring platform designed for collaborative learning groups. Instead of providing direct answers, the AI guides learners through questions that develop critical thinking. The system allows teachers or group admins to upload course materials as PDFs, which are automatically indexed into a vector database and used to ground every AI response in the actual content of those documents.

The MVP targets Vietnamese high school Physics students and small private study groups, though the architecture is domain-agnostic.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [Installation](#installation)
- [Environment Variables](#environment-variables)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Documentation](#api-documentation)
- [Database](#database)
- [Authentication & Authorization](#authentication--authorization)
- [State Management](#state-management)
- [Error Handling](#error-handling)
- [Security](#security)
- [Performance Optimizations](#performance-optimizations)
- [Deployment](#deployment)
- [Testing](#testing)
- [Future Improvements](#future-improvements)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)

---

## Features

### Implemented

- User registration and login with role selection (`student` / `teacher`)
- JWT-based authentication with automatic session restore on app restart
- Dual token verification: local JWT (fast path) with Firebase ID token fallback
- Mock auth headers for local development and Postman testing
- Class management: create a class (teacher), join by a 6-character invite code (student)
- PDF material upload with automatic knowledge tag extraction via Gemini API
- Socratic AI tutor endpoint per class — never gives direct answers, only guiding questions
- AI chat sessions: create a session, send a message, retrieve full history
- RAG pipeline in the AI Engine: PDF ingestion → text extraction → chunking → embedding → ChromaDB upsert → semantic retrieval → Socratic response generation
- Real-time group messaging over Socket.IO with persistent MongoDB storage
- Friend system: send requests, accept requests, list friends, list pending requests
- Group chat: create groups, get or create a direct message channel between two users
- Knowledge gap heatmap endpoint returning a student × knowledge-tag score matrix
- Health check endpoints on both the backend API and AI Engine
- LLM provider switching between Gemini and OpenAI-compatible endpoints via environment variable
- Flutter app with go_router navigation, Riverpod state management, and automatic redirect on auth state change
- Optimistic message rendering in the chat UI
- Automatic 401 interception and logout in the Flutter HTTP client

### Planned

- LaTeX formula rendering inside chat messages (flutter_math_fork or KaTeX WebView)
- `@Lumi` tag detection in group chat with context aggregation from recent messages
- Reverse prompting / mini-quiz generation from weak areas in session history
- Socratic strictness configuration per class or group
- Firebase Firestore as primary real-time data layer (currently MongoDB + Socket.IO)
- Cloud Storage integration for PDF file management
- System admin dashboard with platform-wide knowledge gap analytics
- Pagination on message history and class list endpoints
- Semantic caching to reduce redundant LLM calls

---

## Tech Stack

### Frontend

- **Flutter 3.24+** with Dart 3.8+
- **flutter_riverpod** for reactive state management
- **go_router** for declarative routing with protected routes
- **dio** as HTTP client with automatic Bearer token injection
- **shared_preferences** for token persistence
- **socket_io_client** for real-time messaging
- **freezed** and **json_serializable** for data class generation
- **syncfusion_flutter_pdfviewer** for rendering uploaded PDFs
- **file_picker** for local file selection

### Backend API

- **Node.js 22+** with ES Modules
- **Express 4.21** for HTTP routing
- **Socket.IO 4.8** for real-time bidirectional communication
- **MongoDB 9.8** with Mongoose ODM
- **Firebase Admin SDK 13.5** for ID token verification and Firestore/Storage integration
- **jsonwebtoken 9.0** for local JWT signing and verification
- **bcryptjs 3.0** for password hashing with 12 rounds
- **multer 2.2** for multipart file upload handling
- **pdf-parse 2.4** for extracting text from PDFs (used via CommonJS `require` to avoid ES Module conflicts)
- **@google/generative-ai 0.24** for Gemini API integration in lesson upload knowledge extraction
- **axios 1.11** for HTTP client proxying to AI Engine
- **cors 2.8** middleware for cross-origin requests
- **dotenv 17.2** for environment configuration

### AI Engine

- **Python 3.10+**
- **FastAPI 0.115** for async REST API with auto-generated OpenAPI docs
- **Uvicorn** with standard extras for ASGI server
- **google-generativeai 0.8** for Gemini integration
- **httpx 0.27** for async HTTP requests
- **Pydantic 2.8** for request/response validation
- **sentence-transformers 3.0** for local embeddings (`all-MiniLM-L6-v2` by default)
- **ChromaDB 0.5** as persistent vector store with cosine similarity
- **PyMuPDF (fitz) 1.24** for PDF text extraction
- **langchain-text-splitters 0.3** for recursive text chunking with 1000-char chunks and 150-char overlap
- **pytest 8.0** for testing
- **ruff 0.6** for linting

### Infrastructure

- **Docker Compose** orchestration for Postgres and ChromaDB containers
- **Nodemon 3.1** for hot reload during development
- **Firebase Emulator Suite** for local Firebase Auth, Firestore, and Storage testing

---

## Architecture

LUMI AI follows a three-tier architecture optimized for a solo developer to build, maintain, and deploy.

### High-Level Layers

1. **Frontend (Flutter)**  
   Responsible for UI, navigation, authentication state, file upload, chat rendering, and WebSocket connection management. All HTTP requests include a Bearer token automatically injected via a Dio interceptor.

2. **Backend API (Node.js + Express + Socket.IO)**  
   Acts as the orchestration layer and security gateway. Validates all requests with JWT or Firebase ID tokens, enforces role-based access control, proxies AI requests to the Python AI Engine, manages real-time messaging, and writes persistent data to MongoDB.

3. **AI Engine (Python + FastAPI)**  
   Handles all AI-specific logic: PDF ingestion with text extraction and chunking, embedding generation using sentence-transformers, vector storage in ChromaDB with scope isolation by `room_id` or `user_id`, semantic retrieval of top-k chunks, and Socratic response synthesis using Gemini or OpenAI-compatible LLMs.

### Design Decisions

- **Why Node.js for the backend?**  
  Express provides a minimal, well-understood HTTP framework. Socket.IO enables real-time chat with minimal configuration. The Node.js ecosystem is mature and integrates seamlessly with Firebase.

- **Why FastAPI for AI Engine?**  
  FastAPI's async support, automatic OpenAPI generation, and Pydantic validation reduce boilerplate and improve developer experience. Python dominates the AI/ML ecosystem, making library availability and community support critical.

- **Why MongoDB?**  
  Document-oriented storage aligns with the flexible schema of chat messages, classes, and user profiles. Mongoose provides a simple ODM with schema validation and middleware hooks.

- **Why ChromaDB?**  
  ChromaDB is lightweight, supports persistent local storage, and requires no external cluster management. It's ideal for MVP-stage vector search with isolated scopes.

- **Why Flutter?**  
  Single codebase for iOS, Android, and Web. Strong reactive programming model with Riverpod. Mature package ecosystem for file upload, real-time updates, and PDF rendering.

### Data Flow Example: PDF Upload → Socratic Answer

1. Teacher uploads a PDF via Flutter.
2. Backend receives the file, validates the teacher role, extracts text using pdf-parse, sends text to Gemini to extract knowledge tags, merges tags into the Class document, and returns success.
3. Simultaneously, the teacher can choose to send the PDF to the AI Engine for RAG indexing.
4. Backend forwards the file buffer to AI Engine `/api/upload`.
5. AI Engine extracts text, chunks it, generates embeddings, and stores vectors in ChromaDB with metadata `{scope_type: "room", scope_id: classId, file_name, page, chunk_index}`.
6. Student asks a question via `/api/classes/:classId/socratic`.
7. Backend retrieves the class, verifies membership, forwards question to AI Engine.
8. AI Engine queries ChromaDB for top-5 semantically similar chunks scoped to that class, constructs a Socratic prompt, calls Gemini/OpenAI, and returns a guiding question.
9. Backend returns the Socratic response to Flutter, which renders it in the chat UI.

### Module Interaction

```
┌───────────────┐          ┌────────────────────┐         ┌────────────────────┐
│  Flutter App  │ ◄──JWT──► │ Node.js Backend    │ ◄─HTTP─► │ Python AI Engine   │
│               │           │ (Express, Socket)  │         │ (FastAPI, ChromaDB)│
└───────────────┘           └────────────────────┘         └────────────────────┘
        │                            │                               │
        │                            ▼                               ▼
        │                    ┌────────────────┐            ┌─────────────────┐
        │                    │   MongoDB      │            │   ChromaDB      │
        │                    │  (Mongoose)    │            │ (Vector Store)  │
        │                    └────────────────┘            └─────────────────┘
        │
        ▼
┌────────────────────┐
│  Firebase Auth     │
│  (Optional Token)  │
└────────────────────┘
```

---

## Folder Structure

```
.
├── ai_engine/                     # Python FastAPI AI service
│   ├── app/
│   │   └── main.py                # FastAPI routes, RAG pipeline, LLM integration
│   ├── data/
│   │   └── chroma/                # Persistent ChromaDB storage (gitignored)
│   ├── requirements.txt           # Python dependencies
│   ├── .env.example               # Environment template for AI Engine
│   └── .env                       # Actual secrets (gitignored)
│
├── backend_api/                   # Node.js Express backend
│   ├── src/
│   │   ├── app.js                 # Express app setup
│   │   ├── server.js              # Entry point, Socket.IO, MongoDB connection
│   │   ├── config/
│   │   │   ├── db.js              # MongoDB connection
│   │   │   └── firebase.js        # Firebase Admin SDK initialization
│   │   ├── controllers/           # Request handlers
│   │   │   ├── authController.js  # Register, login, me endpoints
│   │   │   ├── classController.js # Create, join, list classes
│   │   │   ├── lessonController.js# Upload material, create lesson
│   │   │   ├── classAiController.js # Socratic chat endpoint
│   │   │   ├── chatController.js  # Chat session, send message, history
│   │   │   ├── groupController.js # Group and direct chat CRUD
│   │   │   ├── friendController.js# Friend request lifecycle
│   │   │   ├── analyticsController.js # Heatmap data
│   │   │   └── aiController.js    # Proxy chat/upload to AI Engine
│   │   ├── middlewares/
│   │   │   ├── authMiddleware.js  # JWT and Firebase token verification
│   │   │   ├── rbacMiddleware.js  # Role enforcement
│   │   │   ├── errorHandler.js    # Global error middleware
│   │   │   └── uploadMiddleware.js# Multer config for PDF uploads
│   │   ├── models/                # Mongoose schemas
│   │   │   ├── User.js            # username, password, role, friends, friendRequests
│   │   │   ├── Class.js           # name, teacherId, students, joinCode, knowledgeTags
│   │   │   ├── Lesson.js          # classId, title, contentScript, resources
│   │   │   ├── Message.js         # senderId, groupId, content, sender (user|ai)
│   │   │   ├── ChatSession.js     # userId, classId, roomId, title
│   │   │   └── Group.js           # name, adminId, members, isDirect
│   │   ├── routes/                # Route definitions
│   │   │   ├── index.js           # Main router aggregating all sub-routers
│   │   │   ├── authRoutes.js      # /api/auth/*
│   │   │   ├── classRoutes.js     # /api/classes/*
│   │   │   ├── chatRoutes.js      # /api/chat/*
│   │   │   ├── groupRoutes.js     # /api/groups/*
│   │   │   ├── friendRoutes.js    # /api/friends/*
│   │   │   ├── aiRoutes.js        # /api/chat, /api/upload (AI Engine proxy)
│   │   │   └── healthRoutes.js    # /health
│   │   └── services/
│   │       └── aiEngineClient.js  # Axios wrappers for AI Engine HTTP calls
│   ├── firebase.json              # Firebase Emulator config
│   ├── firestore.rules            # Firestore security rules (open for MVP)
│   ├── firestore.indexes.json     # Firestore composite indexes
│   ├── package.json               # Node dependencies and scripts
│   ├── .env.example               # Environment template
│   └── .env                       # Actual secrets (gitignored)
│
├── lumi_app/                      # Flutter mobile/web app
│   ├── lib/
│   │   ├── main.dart              # App entry point, MaterialApp.router setup
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   └── app_constants.dart # Base URLs, mock auth flags
│   │   │   ├── network/
│   │   │   │   └── api_client.dart    # Dio singleton with token interceptor
│   │   │   └── routes/
│   │   │       └── app_router.dart    # GoRouter config with auth redirect
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── screens/       # LoginScreen, RegisterScreen
│   │   │   │   ├── providers/     # authProvider (Riverpod StateNotifier)
│   │   │   │   └── data/          # AuthService, AuthUser model
│   │   │   ├── classes/
│   │   │   │   ├── screens/       # ClassScreen, ClassDetailScreen
│   │   │   │   ├── providers/     # classProvider
│   │   │   │   └── data/          # ClassService, ClassModel
│   │   │   ├── chat/
│   │   │   │   ├── screens/       # ChatScreen
│   │   │   │   ├── presentation/  # chat_session_provider
│   │   │   │   └── data/          # chat_session_service, chat_models
│   │   │   ├── dashboard/
│   │   │   │   └── screens/       # MainLayout (bottom nav wrapper)
│   │   │   └── home/
│   │   │       └── screens/       # WelcomeScreen
│   │   ├── models/                # Shared models (UserModel, GroupModel, MessageModel)
│   │   ├── providers/             # Global providers (GroupProvider, FriendProvider)
│   │   └── services/              # Global services (GroupService, FriendService)
│   ├── pubspec.yaml               # Flutter dependencies
│   └── README.md                  # Flutter-specific setup notes
│
├── docs/                          # Project documentation
│   ├── PRD-LUMI-AI-MVP.md         # Product requirements document
│   ├── TECH-ARCHITECTURE.md       # Architectural decisions and diagrams
│   └── BACKLOG-MVP.md             # Implementation backlog and task breakdown
│
├── docker-compose.yml             # Local Postgres and ChromaDB containers
├── .gitignore                     # Ignore .env, node_modules, build artifacts
└── README.md                      # This file
```

---

## Installation

### Prerequisites

- Node.js 22+
- Python 3.10+
- MongoDB 6+ (local or Atlas)
- Docker and Docker Compose (for ChromaDB and Postgres containers)
- Flutter 3.24+ with Dart 3.8+

### 1. Clone the repository

```bash
git clone https://github.com/your-org/lumi-ai.git
cd lumi-ai
```

### 2. Set up the Backend API

```bash
cd backend_api
cp .env.example .env
# Edit .env with your MongoDB URI, JWT secret, and Firebase credentials
npm install
npm run dev
```

The backend starts on `http://localhost:3000`.

### 3. Set up the AI Engine

```bash
cd ai_engine
cp .env.example .env
# Edit .env with GEMINI_API_KEY or LLM_API_KEY

python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # macOS/Linux

pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The AI Engine starts on `http://localhost:8000`.

### 4. Start supporting services

```bash
# From repo root — starts ChromaDB on port 8001 and Postgres on 5432
docker compose up -d
```

> The AI Engine uses `CHROMA_PERSIST_DIR` from `.env` (default `./data/chroma`). If you run ChromaDB via Docker, update `CHROMA_PERSIST_DIR` to point to the container or switch to the HTTP client.

### 5. Set up the Flutter app

```bash
cd lumi_app
flutter pub get
```

Update `lib/core/constants/app_constants.dart` to point `backendBaseUrl` at your running backend.

```bash
flutter run
```

### 6. Firebase setup (optional for local dev)

For local development without Firebase, set `MOCK_AUTH_ENABLED=true` in `backend_api/.env`. The backend accepts `x-mock-user-id` and `x-mock-user-role` headers instead of Bearer tokens.

To use the Firebase Emulator Suite:

```bash
cd backend_api
npm run emulators
```

---

## Environment Variables

### backend_api/.env

| Variable | Required | Description |
|---|---|---|
| `PORT` | No | HTTP server port. Defaults to `3000`. |
| `MONGODB_URI` | Yes | Full MongoDB connection string. |
| `JWT_SECRET` | Yes | Secret used to sign and verify local JWTs. |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Conditional | Path to Firebase service account JSON file. Required for Firebase token verification unless using emulators. |
| `GOOGLE_APPLICATION_CREDENTIALS` | Conditional | Alternative to `FIREBASE_SERVICE_ACCOUNT_PATH`. |
| `FIREBASE_PROJECT_ID` | Conditional | Firebase project ID. Can be used instead of service account file together with client email and private key. |
| `FIREBASE_CLIENT_EMAIL` | Conditional | Firebase client email from service account. |
| `FIREBASE_PRIVATE_KEY` | Conditional | Firebase private key from service account. Use `\\n` for newlines. |
| `FIREBASE_EMULATOR_HOST` | No | Enables emulator mode. E.g. `localhost:8080`. |
| `FIRESTORE_EMULATOR_HOST` | No | Firestore emulator host. Defaults to `FIREBASE_EMULATOR_HOST` if set. |
| `FIREBASE_AUTH_EMULATOR_HOST` | No | Auth emulator. Defaults to `localhost:9099`. |
| `FIREBASE_STORAGE_EMULATOR_HOST` | No | Storage emulator. Defaults to `localhost:9199`. |
| `MOCK_AUTH_ENABLED` | No | When `true`, accepts `x-mock-user-id` and `x-mock-user-role` headers. For local dev only. |
| `AI_ENGINE_URL` | No | Base URL of the Python AI Engine. Defaults to `http://127.0.0.1:8000`. |
| `AI_ENGINE_TIMEOUT_MS` | No | Timeout for AI Engine HTTP calls. Defaults to `60000`. |
| `GEMINI_API_KEY` | Yes (for Socratic/upload) | Google Gemini API key used by classAiController and lessonController. |
| `GEMINI_MODEL` | No | Gemini model name. Defaults to `gemini-2.0-flash`. |

### ai_engine/.env

| Variable | Required | Description |
|---|---|---|
| `LLM_PROVIDER` | No | `gemini` or `openai`. Defaults to `gemini`. |
| `GEMINI_API_KEY` | Yes (if provider is gemini) | Google Gemini API key. |
| `GEMINI_MODEL` | No | Gemini model name. Defaults to `gemini-1.5-flash`. |
| `LLM_API_URL` | Conditional | OpenAI-compatible chat completions endpoint. Required if `LLM_PROVIDER` is not `gemini`. |
| `LLM_API_KEY` | Conditional | API key for OpenAI-compatible provider. |
| `LLM_MODEL` | No | Model name for OpenAI-compatible provider. Defaults to `gpt-4o-mini`. |
| `LLM_TIMEOUT_SECONDS` | No | Request timeout for LLM calls. Defaults to `60`. |
| `EMBEDDING_MODEL` | No | Sentence Transformers model. Defaults to `sentence-transformers/all-MiniLM-L6-v2`. |
| `CHROMA_PERSIST_DIR` | No | Directory for ChromaDB persistence. Defaults to `./data/chroma`. |
| `CHROMA_COLLECTION_NAME` | No | ChromaDB collection name. Defaults to `lumi_documents`. |
| `MAX_UPLOAD_MB` | No | Maximum allowed upload size. Defaults to `25`. |

---

## Configuration

### `backend_api/firebase.json`

Defines Firebase Emulator ports for local development. Auth runs on `9099`, Firestore on `8080`, Storage on `9199`, and the Emulator UI on `4000`.

### `backend_api/firestore.rules`

Currently allows all reads and writes in MVP mode. Before going to production, these rules must be tightened to enforce per-user and per-room access.

### `backend_api/firestore.indexes.json`

No composite indexes defined yet. As queries grow (e.g., paginated message history filtered by room and sorted by timestamp), indexes should be added here.

### `docker-compose.yml`

Spins up two containers:
- `lumi-postgres` on port `5432` using Postgres 16 Alpine.
- `lumi-chroma` on port `8001` using the latest ChromaDB image.

Data is persisted in named volumes `postgres_data` and `chroma_data`.

### `lumi_app/lib/core/constants/app_constants.dart`

Controls the base URL and mock auth behavior in the Flutter app. Set `backendBaseUrl` to the correct IP when testing on a physical device. Set `mockAuthEnabled = false` before any production build.

---

## Usage

### Running in development

**Start all services:**

```bash
# Terminal 1 — Infrastructure
docker compose up -d

# Terminal 2 — Backend API
cd backend_api
npm run dev

# Terminal 3 — AI Engine
cd ai_engine
.venv\Scripts\activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Terminal 4 — Flutter
cd lumi_app
flutter run
```

### Health checks

```
GET http://localhost:3000/health          → Node.js backend
GET http://localhost:8000/health          → Python AI Engine
GET http://localhost:8000/api/provider    → Active LLM provider info
```

### Typical user flow

1. Register at `/api/auth/register` with a username, password, and role.
2. Login at `/api/auth/login` to receive a JWT.
3. As a teacher: create a class at `/api/classes`, receive a `joinCode`.
4. As a teacher: upload a PDF at `/api/classes/:classId/upload` to extract knowledge tags and optionally index in the AI Engine.
5. As a student: join a class at `/api/classes/join` using the invite code.
6. Ask the Socratic AI at `/api/classes/:classId/socratic`.
7. For free-form RAG chat, create a session at `/api/chat/session`, then send messages at `/api/chat/message`.

---

## API Documentation

All protected endpoints require a `Authorization: Bearer <token>` header unless `MOCK_AUTH_ENABLED=true`, in which case `x-mock-user-id` and `x-mock-user-role` headers are accepted.

### Authentication

#### POST /api/auth/register

Register a new user.

**Auth:** None

**Request body:**
```json
{ "username": "string", "password": "string (min 6 chars)", "role": "student | teacher" }
```

**Response 201:**
```json
{ "message": "Đăng ký thành công.", "user": { "id": "string", "username": "string", "role": "string" } }
```

---

#### POST /api/auth/login

Authenticate and receive a JWT.

**Auth:** None

**Request body:**
```json
{ "username": "string", "password": "string" }
```

**Response 200:**
```json
{ "message": "Đăng nhập thành công.", "token": "string", "user": { "id": "string", "username": "string", "role": "string" } }
```

---

#### GET /api/auth/me

Return the currently authenticated user from the decoded token.

**Auth:** Required

**Response 200:**
```json
{ "user": { "uid": "string", "role": "string", "source": "local-jwt | firebase | mock" } }
```

---

### Classes

#### POST /api/classes

Create a new class. Auto-generates a unique 6-character `joinCode`.

**Auth:** Required

**Request body:**
```json
{ "name": "string", "description": "string (optional)", "coverImage": "string (optional)" }
```

**Response 201:**
```json
{ "message": "Tạo lớp thành công.", "class": { "id": "...", "name": "...", "joinCode": "ABCDEF", "teacherId": {...}, "students": [] } }
```

---

#### GET /api/classes/mine

List all classes where the user is either the teacher or a student.

**Auth:** Required

**Response 200:**
```json
{ "classes": [ { "id": "...", "name": "...", "joinCode": "...", "teacherId": {...}, "students": [...], "knowledgeTags": [...] } ] }
```

---

#### POST /api/classes/join

Join a class using an invite code.

**Auth:** Required

**Request body:**
```json
{ "joinCode": "ABCDEF" }
```

**Response 200:**
```json
{ "message": "Tham gia lớp thành công.", "class": { ... } }
```

---

#### POST /api/classes/:classId/lessons

Create a lesson record within a class. Teacher only.

**Auth:** Required

**Request body:**
```json
{ "title": "string", "content": "string (optional)", "resourceUrl": "string (optional)" }
```

**Response 201:**
```json
{ "message": "Tạo bài học thành công.", "lesson": { ... } }
```

---

#### POST /api/classes/:classId/upload

Upload a PDF material. Extracts text, calls Gemini to identify knowledge tags, and merges them into the class. Teacher only.

**Auth:** Required

**Content-Type:** `multipart/form-data`

**Request:** Form field `file` containing a PDF.

**Response 200:**
```json
{ "message": "Upload và phân tích thành công.", "fileName": "string", "extractedTags": ["string"], "allTags": ["string"] }
```

---

#### POST /api/classes/:classId/socratic

Submit a question to the Socratic AI tutor for this class.

**Auth:** Required

**Request body:**
```json
{ "message": "string" }
```

**Response 200:**
```json
{ "answer": "string", "classId": "string", "sender": "ai" }
```

---

#### GET /api/classes/:classId/heatmap

Returns a student × knowledge-tag score matrix for the class.

**Auth:** Required

**Response 200:**
```json
{ "tags": ["string"], "students": [{ "id": "string", "username": "string" }], "matrix": { "<studentId>": { "<tag>": 0 } } }
```

---

### Chat Sessions

#### POST /api/chat/session

Create a new AI chat session.

**Auth:** Required

**Request body:**
```json
{ "title": "string (optional)", "classId": "string (optional)" }
```

**Response 201:**
```json
{ "session": { "id": "...", "roomId": "...", "title": "...", "userId": "...", "classId": "..." } }
```

---

#### POST /api/chat/message

Send a message in a chat session. Forwards question to AI Engine and returns both the user message and AI response.

**Auth:** Required (session owner only)

**Request body:**
```json
{ "sessionId": "string", "content": "string" }
```

**Response 200:**
```json
{ "userMessage": { "id": "...", "sender": "user", "content": "..." }, "aiMessage": { "id": "...", "sender": "ai", "content": "...", "metadata": { "sources": [] } } }
```

---

#### GET /api/chat/session/:sessionId

Get all messages for a session.

**Auth:** Required (session owner only)

**Response 200:**
```json
{ "session": { "id": "...", "roomId": "..." }, "messages": [ { "id": "...", "sender": "user | ai", "content": "...", "createdAt": "..." } ] }
```

---

### Groups

#### POST /api/groups

Create a group chat. The creator is automatically added as admin and member.

**Auth:** Required

**Request body:**
```json
{ "name": "string", "memberIds": ["string"] }
```

**Response 201:**
```json
{ "group": { "id": "...", "name": "...", "adminId": "...", "members": [...] } }
```

---

#### GET /api/groups

List all groups the current user belongs to (excludes direct message channels).

**Auth:** Required

**Response 200:**
```json
{ "groups": [ { "id": "...", "name": "...", "members": [...] } ] }
```

---

#### POST /api/groups/direct

Get or create a 1-to-1 direct message group between two users.

**Auth:** Required

**Request body:**
```json
{ "friendId": "string" }
```

**Response 200/201:**
```json
{ "group": { "id": "...", "isDirect": true, "members": [...] } }
```

---

### Friends

#### GET /api/friends/list

Return the current user's confirmed friend list.

**Auth:** Required

**Response 200:**
```json
{ "friends": [ { "_id": "...", "username": "...", "role": "..." } ] }
```

---

#### GET /api/friends/pending

Return incoming friend requests waiting for acceptance.

**Auth:** Required

**Response 200:**
```json
{ "requests": [ { "_id": "...", "username": "...", "role": "..." } ] }
```

---

#### POST /api/friends/request

Send a friend request to another user.

**Auth:** Required

**Request body:**
```json
{ "targetUserId": "string" }
```

**Response 200:**
```json
{ "message": "Đã gửi lời mời kết bạn." }
```

---

#### POST /api/friends/accept

Accept a pending friend request. Adds both users to each other's friend list atomically.

**Auth:** Required

**Request body:**
```json
{ "requesterId": "string" }
```

**Response 200:**
```json
{ "message": "Đã chấp nhận lời mời kết bạn." }
```

---

### AI Engine (Direct)

#### POST /api/upload

Index a PDF file into ChromaDB. Scoped to `room_id` or `user_id`.

**Auth:** Bearer token + role `student` or `room_admin`

**Content-Type:** `multipart/form-data`

**Request:** Field `file` (PDF), optional `room_id`, optional `user_id`.

**Response 200:**
```json
{ "message": "Upload và indexing thành công.", "file_name": "...", "file_hash": "...", "scope_type": "room|user|global", "scope_id": "...", "pages": 5, "chunks": 42, "collection": "lumi_documents" }
```

---

#### POST /api/chat

Proxy to AI Engine chat. Performs RAG retrieval and returns a Socratic response.

**Auth:** Bearer token + role `student` or `room_admin`

**Request body:**
```json
{ "question": "string", "room_id": "string (optional)", "top_k": 5 }
```

**Response 200:**
```json
{ "answer": "string", "scope_type": "...", "scope_id": "...", "sources": [{ "text": "...", "metadata": {...}, "distance": 0.12 }] }
```

---

### Socket.IO (Real-time Group Chat)

Connect to `ws://localhost:3000`.

| Event (emit) | Payload | Description |
|---|---|---|
| `join_group` | `groupId: string` | Join a Socket.IO room to receive messages. |
| `send_message` | `{ groupId, senderId, content }` | Send a message. Persisted to MongoDB and broadcast to the room. |

| Event (listen) | Payload | Description |
|---|---|---|
| `receive_message` | Populated `Message` document | Fired to all members when a new message arrives. |
| `message_error` | `{ message, detail }` | Fired on validation or persistence failure. |

---

## Database

### MongoDB (Primary Store)

Managed via Mongoose. All schemas use `timestamps: true` which adds `createdAt` and `updatedAt` automatically.

#### User

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `username` | String | Required, unique, lowercase, trimmed | Used as login identifier. |
| `password` | String | Required | Stored as bcrypt hash (12 rounds). |
| `role` | String enum | `student`, `teacher`, `admin` | Defaults to `student`. |
| `friends` | ObjectId[] | Ref: `User` | Confirmed mutual friends. |
| `friendRequests` | ObjectId[] | Ref: `User` | Pending incoming requests. |

#### Class

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `name` | String | Required, trimmed | |
| `description` | String | Default `''` | |
| `teacherId` | ObjectId | Required, Ref: `User` | |
| `students` | ObjectId[] | Ref: `User` | Updated on join. |
| `joinCode` | String | Required, unique, uppercase | 6-char alphanumeric. Ambiguous characters excluded. |
| `knowledgeTags` | String[] | | Auto-extracted on PDF upload, deduplicated on merge. |

#### Lesson

| Field | Type | Notes |
|---|---|---|
| `classId` | ObjectId Ref: `Class` | |
| `title` | String Required | |
| `order` | Number | Default `0`. For future ordering. |
| `contentScript` | String | Raw lesson text content. |
| `resources` | String[] | List of resource URLs. |

#### ChatSession

| Field | Type | Notes |
|---|---|---|
| `userId` | ObjectId Ref: `User` | Session owner. |
| `classId` | ObjectId Ref: `Class` | Optional. Scopes RAG retrieval. |
| `roomId` | String | Auto-generated unique room identifier. |
| `title` | String | Defaults to `'Phiên học mới'`. |

#### Message

| Field | Type | Notes |
|---|---|---|
| `senderId` | ObjectId Ref: `User` | |
| `groupId` | ObjectId Ref: `Group` | Used for group chat messages. |
| `sessionId` | ObjectId Ref: `ChatSession` | Used for AI chat session messages. |
| `content` | String Required | |
| `sender` | String enum `user`, `ai` | Distinguishes human vs. AI messages. |
| `metadata` | Mixed | Stores `sources` from RAG responses. |

#### Group

| Field | Type | Notes |
|---|---|---|
| `name` | String Required | |
| `adminId` | ObjectId Ref: `User` | Group creator / admin. |
| `members` | ObjectId[] Ref: `User` | Admin is always included. |
| `isDirect` | Boolean | `true` for 1-to-1 DM channels. Query uses `$size: 2` to enforce uniqueness. |

---

### ChromaDB (Vector Store)

Vectors are stored under a single collection (`lumi_documents` by default). Each vector document carries metadata:

| Metadata field | Source | Purpose |
|---|---|---|
| `file_name` | Upload filename | Display in source citations. |
| `file_hash` | SHA-256 of file bytes | Deduplication — chunk IDs are prefixed with hash. |
| `scope_type` | `room`, `user`, or `global` | Isolates retrieval context. |
| `scope_id` | `room_id` or `user_id` | Specific scope identifier. |
| `page` | PyMuPDF page index | For citation display. |
| `chunk_index` | Position within page | For citation display. |

Queries use a `$and` filter to restrict results to the appropriate scope before computing cosine similarity.

---

## Authentication & Authorization

### Authentication Flow

1. Client sends `POST /api/auth/login` with username and password.
2. Backend looks up the user in MongoDB, compares the provided password against the bcrypt hash.
3. On success, signs a JWT containing `{ id, username, role }` with a 7-day expiry using `JWT_SECRET`.
4. Client stores the token in `SharedPreferences` and attaches it as `Authorization: Bearer <token>` to every subsequent request via a Dio interceptor.
5. On app restart, `AuthService.getStoredUser()` reads the persisted token and user info from SharedPreferences, restoring the session without a network call.
6. If a 401 is returned by any endpoint, the Dio `onError` interceptor clears SharedPreferences and triggers `auth_provider.notifier.logout()`, which redirects to the login screen via GoRouter.

### Token Verification Strategy

The `authenticateRequest` middleware in `authMiddleware.js` applies two strategies in sequence:

1. **Mock auth** — if `MOCK_AUTH_ENABLED=true` and `x-mock-user-id` / `x-mock-user-role` headers are present, skip cryptographic verification entirely. For local development only.
2. **Local JWT** — synchronously verify with `jsonwebtoken.verify()` using `JWT_SECRET`. Faster because no network call is needed.
3. **Firebase ID token** — if local JWT verification fails, call `firebase-admin.auth().verifyIdToken()`. Allows Firebase-authenticated clients to use the same backend.

### Role-Based Access Control

The `requireRole(...roles)` middleware in `rbacMiddleware.js` checks `req.user.role` against an allowed list and returns `403` if the role does not match.

Roles defined in the system:

| Role | Permissions |
|---|---|
| `student` | Chat, view classes, join classes, upload to AI Engine. |
| `teacher` | All student permissions, plus create classes, upload materials to a class, create lessons. |
| `admin` | System-wide administration (not yet fully enforced in MVP). |
| `room_admin` | Used specifically in the `/api/upload` and `/api/chat` proxy routes as an alias for group-scoped upload access. |

Class-level authorization checks (teacher vs. student) are handled inline in controllers by comparing `req.user.uid` against `class.teacherId`.

---

## State Management

The Flutter app uses **Riverpod** with `StateNotifier` for all application state.

### Key Providers

**`authProvider` (`StateNotifierProvider<AuthNotifier, AuthState>`)**  
Holds authentication status (`loading`, `authenticated`, `unauthenticated`), the current `AuthUser`, and any auth error message. `AuthNotifier` restores the session from SharedPreferences on construction. The `GoRouter` observes this provider via a `ChangeNotifier` adapter (`_AuthListenable`) and redirects appropriately.

**`classProvider` (`StateNotifierProvider.autoDispose<ClassNotifier, ClassState>`)**  
Fetches and manages the list of classes for the current user. Auto-disposes when not in use. Exposes `createClass`, `joinClass`, and `load` actions. Updates state optimistically on creation.

**`chatSessionProvider` (`StateNotifierProvider.autoDispose<ChatSessionNotifier, ChatSessionState>`)**  
Creates a new chat session on initialization. Manages the message list with optimistic updates: the user message is appended immediately, then replaced with the server-confirmed version once the AI response returns. Exposes `sendMessage`, `loadHistory`, and `clearError`.

**`authServiceProvider`, `classServiceProvider`, `chatSessionServiceProvider`**  
Simple `Provider<T>` instances that provide service layer singletons to their respective notifiers.

---

## Error Handling

### Backend API

- **Global error middleware** (`errorHandler.js`) catches any unhandled exceptions that reach Express and returns `500` with `{ message, detail }`.
- **404 middleware** (`notFoundHandler`) returns `{ message: "Route not found" }` for any unmatched path.
- **Controller-level try/catch** wraps every async operation. All errors are logged with a prefixed tag (e.g., `[AUTH][LOGIN]`, `[CLASS][CREATE]`) and return a structured `{ message, detail }` response.
- **AI Engine connectivity** — if the backend cannot reach the AI Engine (ECONNREFUSED or ETIMEDOUT), it returns `503` with a human-readable message. The chat controller catches AI Engine failures gracefully and falls back to a placeholder response rather than crashing the request.

### AI Engine

- **FastAPI HTTPException** is used for all validation and client errors (400, 413, 422).
- **Empty or malformed LLM responses** are caught and replaced with a safe fallback question.
- **ChromaDB failures** during upsert or query are caught and re-raised as `HTTPException(500)`.
- **Missing API keys** are detected at request time with clear error messages.

### Flutter

- **DioException** is caught in each service method. Error messages are extracted from `response.data.message` if available, or fall back to a generic string.
- **AuthException** is a typed exception thrown by `AuthService` and caught in `AuthNotifier` to populate `AuthState.error`.
- **Optimistic update rollback** — if `sendMessage` fails, the optimistic message remains visible but an error string is set in state. The UI can surface this to the user.

---

## Security

- **Password hashing** — bcrypt with 12 rounds. Passwords are never stored or returned in plaintext.
- **JWT expiry** — tokens expire after 7 days. No refresh token mechanism in MVP.
- **Mock auth gate** — `MOCK_AUTH_ENABLED` must be explicitly set to `true`; it defaults to `false`. Mock headers are only honored when the flag is active.
- **File validation** — backend rejects any upload that does not have a `.pdf` extension before processing. AI Engine enforces the same check plus a configurable size limit (`MAX_UPLOAD_MB`, default 25 MB).
- **RBAC enforcement** — all class mutation endpoints check that the authenticated user is the teacher of that class before proceeding. Group direct-chat creation validates `friendId` as a valid ObjectId and prevents self-targeting.
- **Input trimming and normalization** — all string inputs from request bodies are trimmed. Usernames are lowercased on write and on lookup.
- **CORS** — currently open on both backend (`cors()`) and AI Engine (`allow_origins=["*"]`). This must be tightened before production deployment.
- **Firestore rules** — currently open for MVP. Must be replaced with proper per-document rules before exposing to the public.
- **No PII in JWT** — the token payload contains only `{ id, username, role }`.

---

## Performance Optimizations

### Backend API

- **Local JWT verification first** — the `authenticateRequest` middleware tries synchronous `jsonwebtoken.verify()` before falling back to the asynchronous Firebase Admin SDK call, avoiding a network round-trip for the common case.
- **Population on demand** — Mongoose `.populate()` is only called on endpoints that need nested user data; list queries that don't need it avoid the extra lookup.
- **Set deduplication** — `knowledgeTags` and group `members` use `new Set([...])` and MongoDB `$addToSet` to prevent duplicate entries without a separate existence query.
- **Join code uniqueness loop** — the `uniqueJoinCode` function retries with a cap of 20 attempts rather than doing a pre-count query, keeping the common case to a single insert.

### AI Engine

- **Lazy model loading** — `SentenceTransformer` and ChromaDB client are initialized on first use and cached in module-level globals, avoiding repeated startup cost per request.
- **Normalized embeddings** — embeddings are L2-normalized before storage (`normalize_embeddings=True`), which allows ChromaDB to use cosine similarity efficiently.
- **Content hashing for upsert** — PDF files are SHA-256 hashed and chunk IDs are prefixed with the hash, enabling idempotent re-uploads without duplicating vectors.
- **Chunk overlap** — 150-character overlap between 1000-character chunks reduces the chance of a relevant answer being split across a chunk boundary.
- **Scoped retrieval** — ChromaDB `where` filters narrow the candidate set before distance computation, improving relevance and reducing noise from unrelated documents.

### Flutter

- **`StateNotifierProvider.autoDispose`** — class and chat providers are auto-disposed when not referenced, freeing memory when navigating away from those screens.
- **Optimistic UI updates** — messages appear immediately without waiting for a round-trip to the server, making the chat feel responsive.
- **Session restore from SharedPreferences** — the auth state is restored locally on startup without a network call, enabling instant navigation to the correct screen.
- **Dio timeout configuration** — `connectTimeout`, `receiveTimeout`, and `sendTimeout` are all set to 30 seconds, preventing hanging requests from blocking the UI.

---

## Deployment

### Local development

See the [Installation](#installation) section. All services run on `localhost` with Docker Compose providing ChromaDB and Postgres.

### Backend API

The backend is a standard Node.js HTTP server. It can be deployed to any platform that runs Node.js:

```bash
cd backend_api
npm start
```

Set all required environment variables (MongoDB URI, JWT secret, Firebase credentials, AI Engine URL) in the deployment environment. Do not commit `.env`.

### AI Engine

The FastAPI service can be started with:

```bash
cd ai_engine
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Ensure `CHROMA_PERSIST_DIR` points to a persistent volume so embeddings survive restarts. If deploying with Docker, mount that directory as a volume.

### Flutter

Build for a target platform:

```bash
cd lumi_app

# Android APK
flutter build apk --release

# iOS (macOS required)
flutter build ios --release

# Web
flutter build web --release
```

Update `AppConstants.backendBaseUrl` to the production backend URL before building.

### Firebase

1. Deploy Firestore rules: `firebase deploy --only firestore:rules`
2. Deploy Firestore indexes: `firebase deploy --only firestore:indexes`

Firestore rules **must** be updated from the open MVP rules to production-grade rules before public deployment.

---

## Testing

### Backend API

ESLint is configured for code quality checks:

```bash
cd backend_api
npm run lint
```

No automated test suite is implemented yet. Manual testing can be performed via Postman using `MOCK_AUTH_ENABLED=true` with `x-mock-user-id` and `x-mock-user-role` headers.

### AI Engine

pytest is configured as the test runner:

```bash
cd ai_engine
.venv\Scripts\activate
pytest
```

The `pytest` dependency is pinned in `requirements.txt`. A `/health` endpoint is available for smoke testing after deployment.

### Flutter

```bash
cd lumi_app
flutter test
flutter analyze
```

The standard `flutter_test` SDK and `flutter_lints` are configured. Widget tests live in `lumi_app/test/`.

---

## Future Improvements

- Replace the open Firestore security rules with per-document access rules enforcing room membership and role checks.
- Add a refresh token mechanism to extend JWT sessions beyond 7 days without forcing re-login.
- Implement `@Lumi` tag detection in group chat: detect the mention, aggregate the last N messages, and route them to the AI Engine with group context.
- Add reverse prompting / mini-quiz generation by tracking topics where users have historically struggled.
- Integrate LaTeX rendering in the Flutter chat UI using `flutter_math_fork` or a WebView-based KaTeX wrapper.
- Replace mock score generation in the heatmap endpoint with real session-derived analytics.
- Add pagination to the message history, class list, and group list endpoints.
- Implement semantic caching in the AI Engine to return identical responses for near-duplicate questions without calling the LLM.
- Per-class Socratic strictness configuration allowing teachers to tune how aggressively the AI withholds answers.
- Firebase Cloud Storage integration for persisting uploaded PDFs alongside their ChromaDB embeddings.
- Add structured logging (e.g., `pino` for Node.js) with request IDs to improve observability.
- Tighten CORS configuration on both backend and AI Engine to specific allowed origins.

---

## Contributing

1. Fork the repository and create a feature branch from `main`.
2. Follow the existing code style — `eslint` and `prettier` for the backend, `ruff` for Python, `dart format` and `flutter analyze` for the Flutter app.
3. Keep commits scoped to a single concern.
4. Write or update tests if your change affects behavior.
5. Open a pull request with a clear description of what changed and why.
6. Do not commit `.env` files or service account credentials.

---

## License

This project does not currently have a license file. All rights reserved by the author until a license is explicitly added.

---

## Author

Developed as an MVP by a solo developer. The project is designed to be maintainable by a single person, with clear module boundaries, minimal service dependencies, and comprehensive inline documentation across all three layers.

For questions or contributions, open an issue on the repository.
