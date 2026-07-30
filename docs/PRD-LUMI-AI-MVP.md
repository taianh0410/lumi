# TÀI LIỆU ĐẶC TẢ YÊU CẦU DỰ ÁN (PRD) - LUMI AI (BẢN MVP)

## I. Tổng quan dự án

- **Tên dự án:** LUMI AI - Gia sư ảo Socratic (MVP Phiên bản Nhóm học tập)
- **Mục tiêu:** Xây dựng hệ thống AI giáo dục sử dụng phương pháp Socratic để gợi mở tư duy thay vì cung cấp đáp án sẵn. Phiên bản này tập trung vào các nhóm học tập nhỏ, cho phép người dùng tự tải lên tài liệu chuyên ngành và tương tác nhóm.
- **Nền tảng mục tiêu:** Ứng dụng đa nền tảng (Mobile/Web)

## II. Hệ thống Phân quyền Người dùng (Role-Based Access Control - RBAC)

Hệ thống áp dụng mô hình phân quyền 3 lớp để đảm bảo tính linh hoạt trong các nhóm học tập tư thục.

### 1. Người dùng cơ bản (Member / Student)

- **Quản lý cá nhân:** Được phép tạo tài khoản, quản lý hồ sơ cá nhân và xem lịch sử chat cá nhân.
- **Tương tác AI:** Chat 1-1 với LUMI AI, sử dụng tính năng tải tài liệu cá nhân (BYOD) để tạo Knowledge Base tạm thời.
- **Không gian nhóm:** Được quyền tham gia các "Private Co-learning Spaces" qua mã mời, tham gia thảo luận, gọi AI (`@Lumi`) trong nhóm chat, và xem (read-only) các tài liệu dùng chung của nhóm.

### 2. Trưởng nhóm (Room Admin)

- Kế thừa toàn bộ quyền của Member.
- **Quản lý thành viên:** Có quyền tạo nhóm (Private Room), thêm/xóa thành viên (ví dụ: cấp quyền truy cập cho Dũng, Vanh, Chuẩn, An tham gia vào chung một không gian dự án).
- **Quản lý tài nguyên nhóm (Shared Workspace):** Upload, quản lý, và xóa các tài liệu chuyên ngành (ví dụ: giáo trình Vật lý, Cơ học lượng tử, Phương trình vi phân) làm dữ liệu RAG chung cho cả nhóm.
- **Quản lý cấu hình AI cấp nhóm:** Tuỳ chỉnh mức độ gợi mở (strictness) của phương pháp Socratic cho riêng nhóm đó.

### 3. Quản trị viên hệ thống (System Admin)

- **Quản lý tài nguyên tổng:** Cấu hình API Keys (LLM), theo dõi tài nguyên server, giới hạn dung lượng lưu trữ Vector Database.
- **Dashboard Giám sát:** Xem Knowledge Gap Heatmap tổng thể để phân tích các lỗ hổng kiến thức phổ biến.
- **Cấu hình System Prompt:** Điều chỉnh các prompt kỹ thuật cốt lõi (Socratic System Prompt, Intent Routing) áp dụng cho toàn hệ thống.

## III. Yêu cầu Tính năng Cốt lõi (Core Features)

### 1. Không gian tương tác AI cốt lõi

- **Xử lý Ngôn ngữ Socratic:** AI phân tích câu hỏi và trả về câu hỏi gợi mở. Hệ thống phải có **Intent Routing** để phân biệt giữa câu hỏi khái niệm cơ bản (đáp ứng trực tiếp) và câu hỏi bài tập/tìm lỗi (chuyển sang Socratic).
- **Socratic Debugging:** Hỗ trợ chẩn đoán lỗi logic.
- **Ví dụ:** Thay vì sửa lỗi lặp vô hạn trong đoạn code MATLAB, AI phải đặt câu hỏi: *"Biến đếm trong vòng lặp while này đã được tính toán lại ở dòng nào chưa?"*
- **Ví dụ:** Thay vì chỉ ra lỗi sai mạch điện, AI sẽ hỏi: *"Bạn hãy kiểm tra lại chiều của nguồn xem diode này đang được phân cực thuận hay phân cực ngược?"*
- **Hiển thị Toán học & Kỹ thuật:** Giao diện bắt buộc tích hợp bộ render LaTeX (MathJax/KaTeX) để hiển thị chuẩn xác các công thức phức tạp, phương trình vi phân và sơ đồ kỹ thuật.
- **Reverse Prompting (Thử thách ngược):** Dựa trên lịch sử hội thoại, AI chủ động tạo các mini-quiz để kiểm tra lại các khái niệm người dùng từng vướng mắc.

### 2. Tính năng Nhóm học tập (Private Co-learning Spaces)

- **Real-time Group Chat:** Giao diện nhắn tin nhóm thời gian thực.
- **AI Tagging (`@Lumi`):** Bất kỳ thành viên nào cũng có thể tag AI vào đoạn chat. AI sẽ đọc context của 10-20 tin nhắn gần nhất để đưa ra định hướng giải quyết vấn đề cho cả nhóm.
- **Shared Knowledge Base (RAG Nhóm):** Hệ thống Vector Database cục bộ băm nhỏ (chunking) và lưu trữ các file PDF do Room Admin tải lên để đảm bảo AI trả lời bám sát tài liệu nội bộ.

## IV. Kiến trúc Kỹ thuật (Technical Architecture)

Để tối ưu chi phí và tốc độ phát triển cho bản MVP, hệ thống sử dụng các công nghệ sau:

| Tầng (Layer) | Công nghệ đề xuất | Trách nhiệm xử lý |
|---|---|---|
| Giao diện (Frontend) | Flutter | App đa nền tảng, tích hợp render LaTeX, giao diện chat nhóm realtime. |
| Backend API & Realtime | Node.js (Express) + Firebase | Quản lý Auth, Role-based (RBAC), chat nhóm thời gian thực (Firestore), lưu trữ file (Cloud Storage). |
| AI Engine Service | Python (Flask / FastAPI) | Xử lý LangChain, Semantic Caching, và Bộ lọc Socratic. |
| Vector Database | ChromaDB / FAISS | Lưu trữ embedding cục bộ cho tính năng BYOD và Shared Workspace. |

## V. Luồng Xử lý Tiêu biểu: Tag AI trong Nhóm

1. Member A nhắn tin trong nhóm: *"Mình tính mãi phương trình này không ra, @Lumi xem giúp hướng đi đúng chưa?"*
2. **Node.js Backend** bắt được sự kiện tag, gom nhóm 15 tin nhắn gần nhất và đẩy sang **Flask AI Engine** qua REST API.
3. **AI Engine** kiểm tra tài liệu RAG của nhóm tương ứng trong **Vector DB**.
4. **AI Engine** áp dụng Socratic System Prompt (được System Admin cấu hình), tạo ra câu trả lời gợi mở (VD: *"Bạn đã thử áp dụng điều kiện biên vào phương trình thuần nhất chưa?"*).
5. Kết quả trả về Node.js, cập nhật lên **Firebase Firestore**.
6. **Flutter Frontend** của tất cả thành viên trong room tự động cập nhật tin nhắn của LUMI AI (có render LaTeX).