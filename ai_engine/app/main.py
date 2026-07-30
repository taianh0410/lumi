from __future__ import annotations

import asyncio
import hashlib
import logging
import os
from pathlib import Path
from typing import Any

import chromadb
import fitz
import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from langchain_text_splitters import RecursiveCharacterTextSplitter
from pydantic import BaseModel, Field
from sentence_transformers import SentenceTransformer

try:
    import google.generativeai as genai
except ImportError:  # pragma: no cover - dependency guard
    genai = None


load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("lumi-ai-engine")

app = FastAPI(title="LUMI AI Engine", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    question: str = Field(min_length=1, description="Câu hỏi của người dùng.")
    room_id: str | None = Field(default=None, description="Room scope nếu hỏi theo nhóm.")
    user_id: str | None = Field(default=None, description="User scope nếu hỏi cá nhân.")
    top_k: int = Field(default=5, ge=1, le=10, description="Số chunk cần truy hồi.")


class ChatResponse(BaseModel):
    answer: str
    scope_type: str
    scope_id: str
    sources: list[dict[str, Any]]


def _env_int(name: str, default: int) -> int:
    raw_value = os.getenv(name)
    if not raw_value:
        return default
    try:
        return int(raw_value)
    except ValueError as exc:
        raise RuntimeError(f"Environment variable {name} must be an integer") from exc


def _build_scope(room_id: str | None, user_id: str | None) -> tuple[str, str]:
    if room_id:
        return "room", room_id
    if user_id:
        return "user", user_id
    return "global", "global"


MAX_UPLOAD_BYTES = _env_int("MAX_UPLOAD_MB", 25) * 1024 * 1024
LLM_API_URL = os.getenv("LLM_API_URL", "https://api.openai.com/v1/chat/completions")
LLM_API_KEY = os.getenv("LLM_API_KEY", "").strip()
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-4o-mini")
LLM_TIMEOUT_SECONDS = _env_int("LLM_TIMEOUT_SECONDS", 60)
EMBEDDING_MODEL = os.getenv(
    "EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2"
)
CHROMA_PERSIST_DIR = Path(os.getenv("CHROMA_PERSIST_DIR", "./data/chroma"))
CHROMA_COLLECTION_NAME = os.getenv("CHROMA_COLLECTION_NAME", "lumi_documents")
LLM_PROVIDER = os.getenv("LLM_PROVIDER", "gemini").strip().lower()

SOCRATIC_SYSTEM_PROMPT = """You are LUMI, a strict Socratic tutor.
You must never give the final answer directly.
You must never provide step-by-step solutions, code fixes, or direct calculations.
You must respond in Vietnamese.
You must ask only concise, guiding questions that help the learner think.
You should use at most 3 questions.
If the context is weak, ask the learner what they have already tried and where they are stuck.
If the user explicitly asks for a direct answer, still refuse politely and continue with Socratic questions.
Use the retrieved context only to guide your questions, not to reveal the solution.
"""

_embedder: SentenceTransformer | None = None
_chroma_client: chromadb.PersistentClient | None = None
_chroma_collection: Any | None = None


def get_embedder() -> SentenceTransformer:
    global _embedder
    if _embedder is None:
        logger.info("Loading embedding model: %s", EMBEDDING_MODEL)
        _embedder = SentenceTransformer(EMBEDDING_MODEL)
    return _embedder


def get_chroma_collection() -> Any:
    global _chroma_client, _chroma_collection
    if _chroma_collection is None:
        CHROMA_PERSIST_DIR.mkdir(parents=True, exist_ok=True)
        _chroma_client = chromadb.PersistentClient(path=str(CHROMA_PERSIST_DIR))
        _chroma_collection = _chroma_client.get_or_create_collection(
            name=CHROMA_COLLECTION_NAME,
            metadata={"hnsw:space": "cosine"},
        )
    return _chroma_collection


def extract_pdf_pages(pdf_bytes: bytes, file_name: str) -> list[dict[str, Any]]:
    try:
        document = fitz.open(stream=pdf_bytes, filetype="pdf")
    except Exception as exc:  # pragma: no cover - defensive parsing guard
        raise HTTPException(status_code=400, detail="Tệp tải lên không phải PDF hợp lệ.") from exc

    if document.page_count == 0:
        raise HTTPException(status_code=400, detail="PDF không có trang hợp lệ nào.")

    pages: list[dict[str, Any]] = []
    for page_index in range(document.page_count):
        page = document.load_page(page_index)
        page_text = page.get_text("text").strip()
        if not page_text:
            continue
        pages.append({
            "page": page_index + 1,
            "text": page_text,
            "file_name": file_name,
        })

    if not pages:
        raise HTTPException(status_code=400, detail="Không trích xuất được text từ PDF.")

    return pages


def chunk_pages(pages: list[dict[str, Any]]) -> list[dict[str, Any]]:
    splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=150)
    chunks: list[dict[str, Any]] = []

    for page in pages:
        page_chunks = splitter.split_text(page["text"])
        for chunk_index, chunk_text in enumerate(page_chunks):
            cleaned_text = chunk_text.strip()
            if not cleaned_text:
                continue
            chunks.append({
                "page": page["page"],
                "chunk_index": chunk_index,
                "text": cleaned_text,
                "file_name": page["file_name"],
            })

    if not chunks:
        raise HTTPException(status_code=400, detail="PDF không tạo được chunk nào để lưu RAG.")

    return chunks


def build_chat_context(results: dict[str, Any]) -> list[dict[str, Any]]:
    documents = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]
    distances = results.get("distances", [[]])[0]

    sources: list[dict[str, Any]] = []
    for index, document in enumerate(documents):
        metadata = metadatas[index] if index < len(metadatas) else {}
        distance = distances[index] if index < len(distances) else None
        sources.append(
            {
                "text": document,
                "metadata": metadata,
                "distance": distance,
            }
        )
    return sources


def format_sources_for_prompt(sources: list[dict[str, Any]]) -> str:
    if not sources:
        return "Không có ngữ cảnh tài liệu phù hợp."

    blocks: list[str] = []
    for index, source in enumerate(sources, start=1):
        metadata = source.get("metadata", {})
        blocks.append(
            f"[Chunk {index}] file={metadata.get('file_name', 'unknown')} | page={metadata.get('page', '?')} | text={source.get('text', '')}"
        )
    return "\n\n".join(blocks)


def build_scope_where_filter(scope_type: str, scope_id: str) -> dict[str, Any]:
    return {
        "$and": [
            {"scope_type": scope_type},
            {"scope_id": scope_id},
        ]
    }


def ensure_socratic_reply(reply: str, question: str) -> str:
    cleaned_reply = reply.strip()
    if not cleaned_reply:
        logger.warning("LLM returned empty reply for question: %s", question)
        return "Bạn đã thử mô tả rõ phần nào của bài toán hoặc tài liệu đang làm bạn kẹt chưa?"

    # Always return the actual LLM response — do not override with a hardcoded template.
    return cleaned_reply


def get_llm_config() -> tuple[str, str, str]:
    if LLM_PROVIDER == "gemini":
        api_key = os.getenv("GEMINI_API_KEY", "").strip()
        model = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")
        return "gemini", api_key, model

    api_url = os.getenv("LLM_API_URL", "https://api.openai.com/v1/chat/completions")
    api_key = os.getenv("LLM_API_KEY", "").strip()
    model = os.getenv("LLM_MODEL", "gpt-4o-mini")
    return api_url, api_key, model


async def call_llm(question: str, context_text: str) -> str:
    api_url, api_key, model = get_llm_config()

    if LLM_PROVIDER == "gemini":
        if genai is None:
            logger.error("google-generativeai is not installed")
            raise HTTPException(
                status_code=500,
                detail="Thiếu thư viện google-generativeai. Hãy cài lại requirements.txt.",
            )

        if not api_key:
            logger.error("Missing Gemini API key")
            raise HTTPException(
                status_code=500,
                detail="Thiếu GEMINI_API_KEY. Hãy điền API key trong ai_engine/.env.",
            )

        genai.configure(api_key=api_key)
        gemini_model = genai.GenerativeModel(
            model_name=model,
            system_instruction=SOCRATIC_SYSTEM_PROMPT,
        )

        prompt = (
            "Ngữ cảnh RAG tham chiếu:\n"
            f"{context_text}\n\n"
            f"Câu hỏi của người dùng:\n{question}"
        )

        try:
            response = await asyncio.to_thread(
                gemini_model.generate_content,
                prompt,
                generation_config={"temperature": 0.2},
            )
        except Exception as exc:  # pragma: no cover - upstream network guard
            logger.exception("Gemini request failed")
            raise HTTPException(status_code=502, detail=f"Gemini API lỗi: {exc}") from exc

        content = getattr(response, "text", None)
        if not content:
            logger.error("Gemini returned empty content: %s", response)
            raise HTTPException(
                status_code=502,
                detail="Gemini trả về nội dung rỗng hoặc không đọc được.",
            )

        return ensure_socratic_reply(content, question)

    if not api_key:
        logger.error("Missing OpenAI-compatible API key for provider %s", LLM_PROVIDER)
        raise HTTPException(
            status_code=500,
            detail=(
                f"Thiếu key cho provider '{LLM_PROVIDER}'. "
                "Hãy copy từ .env.example và điền API key tương ứng."
            ),
        )

    payload = {
        "model": model,
        "temperature": 0.2,
        "messages": [
            {"role": "system", "content": SOCRATIC_SYSTEM_PROMPT},
            {
                "role": "system",
                "content": f"Ngữ cảnh RAG tham chiếu:\n{context_text}",
            },
            {"role": "user", "content": question},
        ],
    }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=LLM_TIMEOUT_SECONDS) as client:
            response = await client.post(api_url, json=payload, headers=headers)
            if response.status_code >= 400:
                logger.error(
                    "OpenAI-compatible API returned %s: %s",
                    response.status_code,
                    response.text[:1000],
                )
                raise HTTPException(
                    status_code=502,
                    detail=(
                        f"LLM API trả về {response.status_code}: "
                        f"{response.text[:1000]}"
                    ),
                )

        response_data = response.json()
        try:
            content = response_data["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError) as exc:
            logger.exception("LLM response format invalid")
            raise HTTPException(
                status_code=502,
                detail="LLM trả về định dạng không hợp lệ. Hãy kiểm tra xem endpoint có đúng OpenAI-compatible không.",
            ) from exc
    except httpx.HTTPError as exc:
        logger.exception("LLM request failed")
        raise HTTPException(status_code=502, detail=f"LLM API lỗi: {exc}") from exc

    return ensure_socratic_reply(content, question)


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok", "service": "ai-engine"}


@app.get("/api/health")
def api_health_check() -> dict[str, str]:
    return health_check()


@app.get("/api/provider")
def provider_info() -> dict[str, str]:
    api_url, _, model = get_llm_config()
    return {
        "provider": LLM_PROVIDER,
        "model": model,
        "api_url": api_url,
    }


@app.post("/api/upload")
async def upload_pdf(
    file: UploadFile = File(...),
    room_id: str | None = Form(default=None),
    user_id: str | None = Form(default=None),
) -> dict[str, Any]:
    # Postman tip: send this endpoint as multipart/form-data with one file field named `file`.
    # Optional fields: `room_id` for group scope, `user_id` for personal scope.
    if not file.filename:
        raise HTTPException(status_code=400, detail="Thiếu tên file upload.")

    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Chỉ chấp nhận file PDF.")

    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="File upload rỗng.")

    if len(file_bytes) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File vượt quá giới hạn {MAX_UPLOAD_BYTES // (1024 * 1024)}MB.",
        )

    scope_type, scope_id = _build_scope(room_id, user_id)
    file_hash = hashlib.sha256(file_bytes).hexdigest()
    pages = extract_pdf_pages(file_bytes, file.filename)
    chunks = chunk_pages(pages)

    embeddings = get_embedder().encode(
        [chunk["text"] for chunk in chunks],
        normalize_embeddings=True,
    )

    collection = get_chroma_collection()
    ids = [f"{file_hash}:{index}" for index in range(len(chunks))]
    metadatas = [
        {
            "file_name": file.filename,
            "file_hash": file_hash,
            "scope_type": scope_type,
            "scope_id": scope_id,
            "page": chunk["page"],
            "chunk_index": chunk["chunk_index"],
        }
        for chunk in chunks
    ]

    try:
        collection.upsert(
            ids=ids,
            documents=[chunk["text"] for chunk in chunks],
            embeddings=embeddings.tolist(),
            metadatas=metadatas,
        )
    except Exception as exc:  # pragma: no cover - external storage guard
        logger.exception("ChromaDB upsert failed")
        raise HTTPException(status_code=500, detail=f"Lưu embedding thất bại: {exc}") from exc

    return {
        "message": "Upload và indexing thành công.",
        "file_name": file.filename,
        "file_hash": file_hash,
        "scope_type": scope_type,
        "scope_id": scope_id,
        "pages": len(pages),
        "chunks": len(chunks),
        "collection": CHROMA_COLLECTION_NAME,
    }


@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    # Postman tip: send this endpoint as application/json.
    # Example body: {"question":"...","room_id":"room-1","top_k":5}
    scope_type, scope_id = _build_scope(request.room_id, request.user_id)
    collection = get_chroma_collection()

    where_filter: dict[str, Any] | None
    if scope_type == "global":
        where_filter = None
    else:
        where_filter = build_scope_where_filter(scope_type, scope_id)

    try:
        query_kwargs: dict[str, Any] = {
            "query_texts": [request.question],
            "n_results": request.top_k,
        }
        if where_filter:
            query_kwargs["where"] = where_filter
        results = collection.query(**query_kwargs)
    except Exception as exc:  # pragma: no cover - external storage guard
        logger.exception("ChromaDB query failed")
        raise HTTPException(status_code=500, detail=f"Truy vấn ChromaDB thất bại: {exc}") from exc

    sources = build_chat_context(results)
    context_text = format_sources_for_prompt(sources)
    answer = await call_llm(request.question, context_text)

    return ChatResponse(
        answer=answer,
        scope_type=scope_type,
        scope_id=scope_id,
        sources=sources,
    )
