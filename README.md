# LUMI AI

LUMI AI là một gia sư ảo theo hướng Socratic cho học nhóm nhỏ. Mục tiêu của MVP là không đưa đáp án ngay, mà gợi mở tư duy, hỗ trợ debug logic, và cho phép nhóm tự tải tài liệu nội bộ để AI trả lời bám sát ngữ cảnh.

## Mục tiêu MVP

- Hỗ trợ chat 1-1 và chat nhóm realtime.
- Cho phép upload PDF để tạo knowledge base tạm thời cho từng user hoặc từng room.
- Dùng cơ chế intent routing để quyết định khi nào trả lời trực tiếp và khi nào chuyển sang Socratic.
- Render công thức toán và kỹ thuật bằng LaTeX.

## Cấu trúc dự án

- `mobile_app/`: Flutter app cho mobile/web.
- `backend_api/`: Node.js/Express API gateway, auth, RBAC, realtime orchestration.
- `ai_engine/`: Python FastAPI service xử lý RAG, chunking, retrieval và Socratic response.
- `docs/`: Tài liệu PRD, kiến trúc và backlog MVP.

## Tài liệu

- [PRD MVP](docs/PRD-LUMI-AI-MVP.md)
- [TECH-ARCHITECTURE](docs/TECH-ARCHITECTURE.md)
- [BACKLOG MVP](docs/BACKLOG-MVP.md)

## Yêu cầu môi trường

- Node.js 20+
- Python 3.11+
- Flutter stable
- Docker Desktop
- Firebase project để dùng Auth, Firestore, Storage

## Setup local

### 1. Khởi động database cục bộ

```bash
docker compose up -d
```

PostgreSQL dùng cho dữ liệu nghiệp vụ cục bộ, còn ChromaDB dùng làm vector store cho luồng RAG.

### 2. Cài backend API

```bash
cd backend_api
npm install
npm run dev
```

### 3. Cài AI Engine

```bash
cd ai_engine
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### 4. Chạy Flutter app

```bash
cd mobile_app
flutter pub get
flutter run
```

## Ghi chú triển khai

- Trong MVP, Node.js là gateway duy nhất để kiểm soát auth, quyền room và ghi Firestore.
- Python service chỉ xử lý ingest, retrieval và sinh phản hồi Socratic.
- Nếu cần đơn giản hơn nữa, có thể giữ toàn bộ vector index ở ChromaDB local thay vì dựng hạ tầng vector riêng.
