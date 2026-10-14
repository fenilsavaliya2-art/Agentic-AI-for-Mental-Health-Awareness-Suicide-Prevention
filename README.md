# 🧠 MindGuard AI — Mental Health Awareness & Suicide Prevention Agent

> Empathetic conversational AI powered by **IBM Granite 13B** · **watsonx.ai** · **FAISS RAG** · **Flask**

---

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/fenilsavaliya2-art/Agentic-AI-for-Mental-Health-Awareness-Suicide-Prevention.git
cd Agentic-AI-for-Mental-Health-Awareness-Suicide-Prevention
```

---

### 2. Create & activate a virtual environment

**Windows**
```bash
python -m venv venv
venv\Scripts\activate
```

**macOS / Linux**
```bash
python3 -m venv venv
source venv/bin/activate
```

---

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

---

### 4. Configure environment variables

Edit the `.env` file in the project root:

```env
WATSONX_API_KEY=<your-ibm-watsonx-api-key>
WATSONX_URL=https://us-south.ml.cloud.ibm.com
WATSONX_PROJECT_ID=<your-watsonx-project-id>
```

> Get your credentials from [IBM watsonx.ai](https://dataplatform.cloud.ibm.com/)

---

### 5. Run the project

#### 🖥️ Option A — Interactive CLI (terminal chat)

```bash
python agent.py
```

Chat directly with MindGuard in your terminal. Type `quit` to exit.

---

#### 🌐 Option B — Flask REST API (web / frontend)

```bash
python agent.py serve
# or on a custom port:
python agent.py serve 8080
```

API runs at `http://localhost:5000`

| Endpoint | Method | Description |
|---|---|---|
| `/health` | GET | Liveness check — returns RAG & model status |
| `/chat` | POST | Send a message, get a response |
| `/reset` | POST | Clear conversation history |

**Example `/chat` request:**
```bash
curl -X POST http://localhost:5000/chat \
     -H "Content-Type: application/json" \
     -d '{"message": "I have been feeling really anxious lately."}'
```

**Example response:**
```json
{
  "reply": "I hear you, and I am really glad you reached out...",
  "risk_level": "MEDIUM"
}
```

---

## 🗂️ Project Structure

```
├── agent.py            # Main agent — watsonx.ai, MindGuardAgent class, Flask API, CLI
├── rag_engine.py       # FAISS semantic retrieval + SentenceTransformer embeddings
├── knowledge_base.py   # 13 curated mental health documents + risk triage (HIGH/MEDIUM/LOW)
├── requirements.txt    # Python dependencies
├── .env                # API credentials (never commit real keys)
├── add_voiceover.ps1   # Windows: generate TTS narration WAVs and embed into PPTX
├── export_video.ps1    # Windows: export PPTX → MP4 via PowerPoint COM
├── save_timings.ps1    # Windows: save slide advance timings into PPTX
├── MindGuard_AI_Presentation.pptx   # Project presentation
└── MindGuard_AI_Presentation.mp4    # Exported walkthrough video
```

---

## ⚙️ How It Works

```
User Message
     │
     ▼
Risk Triage ──────────────────────────────────────────────────────┐
(knowledge_base.py)                                               │
     │                                                            │
     ▼                                                            ▼
RAG Engine                                               HIGH → 988 / crisis lines
(FAISS + SentenceTransformers)                          MEDIUM → disclaimer + care nudge
     │
     ▼
IBM Granite 13B (watsonx.ai)
+ SYSTEM_PROMPT + RAG context + conversation history
     │
     ▼
Empathetic Response + Safety Suffix
```

---

## 🛡️ Safety & Ethics

- **HIGH risk** phrases (e.g. *"want to die"*, *"kill myself"*) → immediate 24/7 crisis helplines appended
- **MEDIUM risk** phrases (e.g. *"hopeless"*, *"feel empty"*) → medical disclaimer + professional referral
- **Never** suggests harmful actions · **Never** diagnoses · **Always** person-first language
- Mandatory medical disclaimer on every response

---

## 📋 Requirements

- Python **3.10+**
- IBM watsonx.ai account with a project ID and API key
- Internet access (watsonx.ai inference API)

---

## ⚠️ Disclaimer

MindGuard is an AI assistant, **not** a licensed mental health professional.  
It is for **educational and supportive purposes only** — not medical advice, diagnosis, or treatment.  
**In a crisis, contact emergency services or a qualified healthcare provider immediately.**

🆘 **USA:** Call / Text **988** &nbsp;|&nbsp; **India:** iCall **9152987821** &nbsp;|&nbsp; **UK:** Samaritans **116 123**
