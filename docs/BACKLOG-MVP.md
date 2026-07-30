# BACKLOG MVP - LUMI AI

Tài liệu này tách PRD thành backlog theo giai đoạn để một solo developer có thể triển khai tuần tự, giảm đổi ngữ cảnh và giảm chi phí nghiên cứu.

## Đã Hoàn Thành

- [x] Dựng skeleton `ai_engine` với `/api/upload`, `/api/chat` và Socratic provider switch `mock/gemini/openai`.
- [x] Đồng bộ `backend_api` để forward đúng contract sang `ai_engine` ở cổng `8000`.
- [x] Bổ sung log lỗi kết nối rõ ràng khi Node.js không gọi được Python service.
- [x] Chuẩn hóa file `.env.example` cho cả Node.js và Python.
- [x] Thay mock memory `room/message` của `backend_api` bằng Firestore persistence trực tiếp.
- [x] Bổ sung cấu hình Firebase service account path cho `backend_api`.
- [x] Ghi `userId` và timestamp đầy đủ vào các document Firestore để truy vấn lịch sử chat.
- [x] Cấu hình Firebase Emulator Suite cho `backend_api` để test local không chạm Cloud.

## Phase 1: Setup Infrastructure & Boilerplate

### 1.1. Khởi tạo monorepo và cấu trúc thư mục

**User Story**: Là một solo developer, tôi muốn có một workspace thống nhất để quản lý Flutter, Node.js, Python và docs trong cùng một repo.

**Task**:
- Tạo cấu trúc `apps/`, `services/`, `docs/`, `infra/`.
- Chuẩn hóa naming, env files, README setup.

**Tools / Libraries**:
- Git
- Monorepo tool đơn giản như `pnpm workspaces` hoặc không dùng monorepo manager nếu muốn tối giản.
- `docker compose` nếu muốn local dev đồng nhất.

### 1.2. Dựng Firebase project

**User Story**: Là người dùng, tôi muốn có đăng nhập và realtime sync mà không phải tự xây authentication service.

**Task**:
- Tạo Firebase project.
- Bật Authentication, Firestore, Storage.
- Định nghĩa collections cơ bản: `users`, `rooms`, `messages`, `files`, `jobs`.

**Tools / Libraries**:
- Firebase Console
- `firebase-admin` cho Node.js
- Flutter Firebase plugins

### 1.3. Chuẩn hóa môi trường dev

**User Story**: Là developer, tôi muốn setup local nhanh và tái lập được trên máy mới.

**Task**:
- Thiết lập `.env.example` cho Node.js và Python.
- Chuẩn hóa script chạy dev.
- Nếu cần, dựng Docker cho AI Engine và ChromaDB.

**Tools / Libraries**:
- `dotenv`
- `docker`
- `docker compose`

### 1.4. Thiết lập chất lượng code tối thiểu

**User Story**: Là developer, tôi muốn code dễ maintain và ít lỗi vặt.

**Task**:
- Thiết lập formatter, lint, basic test command.
- Thiết lập conventions cho API response và error format.

**Tools / Libraries**:
- Node.js: `eslint`, `prettier`
- Python: `ruff`, `black`, `pytest`
- Flutter: `flutter analyze`, `dart format`

## Phase 2: Core AI Engine

### 2.1. Ingest PDF và trích xuất text

**User Story**: Là người dùng, tôi muốn tải PDF lên để AI có thể đọc tài liệu của tôi.

**Task**:
- Nhận file URL từ Node.js.
- Tải PDF về.
- Trích text và làm sạch nội dung.

**Tools / Libraries**:
- `FastAPI`
- `pypdf` hoặc `pdfplumber`
- `httpx`

### 2.2. Chunking và metadata hoá tài liệu

**User Story**: Là người dùng, tôi muốn tài liệu được chia nhỏ hợp lý để AI truy hồi chính xác hơn.

**Task**:
- Tách text thành chunks có overlap.
- Gắn metadata: `roomId`, `fileId`, `page`, `chunkIndex`.

**Tools / Libraries**:
- `langchain-text-splitters` hoặc tự viết splitter đơn giản.
- `tiktoken` nếu cần ước lượng token.

### 2.3. Embedding và lưu vector

**User Story**: Là người dùng, tôi muốn AI tìm đúng đoạn tài liệu liên quan khi hỏi.

**Task**:
- Tạo embeddings.
- Upsert vào vector store theo scope user/room.

**Tools / Libraries**:
- `chroma` / `chromadb`
- `sentence-transformers` hoặc embedding API của nhà cung cấp LLM

### 2.4. Retrieval pipeline

**User Story**: Là người dùng, tôi muốn AI chỉ dùng đúng phần tài liệu liên quan.

**Task**:
- Tìm top-k chunks.
- Sắp xếp theo relevance.
- Chuẩn hóa context đầu vào cho LLM.

**Tools / Libraries**:
- `chromadb`
- `numpy` nếu cần scoring phụ trợ

### 2.5. Intent routing và Socratic prompt

**User Story**: Là người dùng, tôi muốn AI trả lời trực tiếp khi hỏi khái niệm cơ bản và gợi mở khi hỏi bài tập hoặc debug.

**Task**:
- Phân loại intent.
- Tạo prompt Socratic theo mode.
- Trả response có cấu trúc.

**Tools / Libraries**:
- `pydantic`
- `FastAPI`
- `LangChain` nếu muốn orchestration nhanh, hoặc prompt template tự viết để giảm phụ thuộc

### 2.6. Mini quiz / reverse prompting

**User Story**: Là người học, tôi muốn AI nhắc lại điểm tôi từng sai để ôn tập chủ động.

**Task**:
- Lưu history các lỗi và chủ đề yếu.
- Sinh câu hỏi ôn tập ngắn.

**Tools / Libraries**:
- Firestore hoặc một bảng lịch sử riêng trong Node.js
- Prompt template đơn giản trong Python

## Phase 3: Backend & API Gateway

### 3.1. Firebase Auth và RBAC

**User Story**: Là người dùng, tôi muốn đăng nhập an toàn và được phân quyền đúng vai trò.

**Task**:
- Tích hợp Firebase Auth.
- Xác thực token ở Node.js.
- Enforce role `member`, `room_admin`, `system_admin`.

**Tools / Libraries**:
- `firebase-admin`
- `jsonwebtoken` nếu cần phụ trợ, nhưng ưu tiên Firebase token verification

### 3.2. Room management API

**User Story**: Là room admin, tôi muốn tạo room và quản lý thành viên.

**Task**:
- CRUD room.
- Thêm/xóa thành viên.
- Gắn quyền access theo room.

**Tools / Libraries**:
- `express` hoặc `fastify`
- Firestore

### 3.3. Message gateway và realtime sync

**User Story**: Là thành viên, tôi muốn chat nhóm realtime và thấy message của AI ngay lập tức.

**Task**:
- Ghi message user.
- Ghi message AI.
- Đồng bộ stream qua Firestore.

**Tools / Libraries**:
- Firestore listeners
- `firebase-admin`

### 3.4. File upload gateway

**User Story**: Là room admin, tôi muốn upload PDF cho workspace của nhóm.

**Task**:
- Nhận file từ Flutter.
- Lưu Cloud Storage.
- Tạo ingest job.
- Gọi AI Engine ingest endpoint.

**Tools / Libraries**:
- `multer` nếu upload qua Node
- Firebase Storage / Cloud Storage SDK

### 3.5. AI orchestration endpoint

**User Story**: Là người dùng, tôi muốn tag `@Lumi` để Node.js chuyển ngữ cảnh sang AI Engine.

**Task**:
- Gom 10-20 tin nhắn gần nhất.
- Gọi AI Engine.
- Lưu response trả về Firestore.

**Tools / Libraries**:
- `axios` hoặc `fetch`
- `firebase-admin`

## Phase 4: Frontend & Integration

### 4.1. Flutter app shell và navigation

**User Story**: Là người dùng, tôi muốn mở app và đi qua các màn hình chính ổn định.

**Task**:
- Tạo app shell.
- Dựng navigation cho login, rooms, chat, upload, profile.

**Tools / Libraries**:
- Flutter SDK
- `go_router`
- `flutter_riverpod` hoặc `provider` nếu muốn nhẹ hơn

### 4.2. Authentication UI

**User Story**: Là người dùng, tôi muốn đăng nhập và giữ session.

**Task**:
- Đăng nhập Firebase.
- Lưu session.
- Đồng bộ role từ backend.

**Tools / Libraries**:
- `firebase_auth`
- `flutter_secure_storage`

### 4.3. Chat UI realtime

**User Story**: Là thành viên, tôi muốn gửi và nhận tin nhắn nhóm ngay lập tức.

**Task**:
- Dựng message list.
- Input composer.
- Hiển thị trạng thái AI typing / job status.

**Tools / Libraries**:
- `cloud_firestore`
- `stream_builder` pattern

### 4.4. Render LaTeX trong chat

**User Story**: Là người học kỹ thuật, tôi muốn đọc công thức toán và kỹ thuật rõ ràng trong chat.

**Task**:
- Parse math snippets.
- Render inline/block formulas.

**Tools / Libraries**:
- `flutter_math_fork` hoặc WebView + KaTeX nếu target web cần đẹp hơn

### 4.5. Upload PDF từ frontend

**User Story**: Là room admin, tôi muốn upload tài liệu ngay trong app.

**Task**:
- Chọn file.
- Upload lên backend.
- Hiển thị tiến trình và trạng thái ingest.

**Tools / Libraries**:
- `file_picker`
- `dio`

### 4.6. Ráp luồng @Lumi end-to-end

**User Story**: Là thành viên, tôi muốn tag AI trong group chat và nhận phản hồi Socratic ngay trong room.

**Task**:
- Detect `@Lumi`.
- Gửi request tới backend.
- Hiển thị câu trả lời theo realtime stream.

**Tools / Libraries**:
- `cloud_firestore`
- `dio` hoặc `http`
- `flutter_math_fork`

### 4.7. Hardening trước khi release MVP

**User Story**: Là developer, tôi muốn hệ thống đủ ổn định để dùng nội bộ.

**Task**:
- Check lỗi upload lớn.
- Check quyền room.
- Check response timeout AI.
- Thêm logging tối thiểu.

**Tools / Libraries**:
- Firebase console logs
- Node.js logger như `pino`
- Python logger chuẩn
