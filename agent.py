"""
IBM Granite LLM Agent — Mental Health Agentic AI
Connects to IBM watsonx.ai and orchestrates multi-turn empathetic conversations.
"""

import os
import re
from typing import List, Dict, Any
from dotenv import load_dotenv

load_dotenv()

# ── IBM watsonx.ai SDK ────────────────────────────────────────────────────────
try:
    from ibm_watsonx_ai import Credentials
    from ibm_watsonx_ai.foundation_models import ModelInference
    WATSONX_SDK_AVAILABLE = True
except ImportError:
    WATSONX_SDK_AVAILABLE = False

from rag_engine import retrieve_context, format_context_for_prompt, initialize_rag
from knowledge_base import assess_risk_level

# ─────────────────────────────────────────────────────────────────────────────
WATSONX_URL        = os.getenv("WATSONX_URL", "https://us-south.ml.cloud.ibm.com")
WATSONX_API_KEY    = os.getenv("WATSONX_API_KEY", "")
WATSONX_PROJECT_ID = os.getenv("WATSONX_PROJECT_ID", "")
GRANITE_MODEL_ID   = "ibm/granite-13b-instruct-v2"

GEN_PARAMS = {
    "max_new_tokens": 600,
    "min_new_tokens": 30,
    "temperature": 0.75,
    "top_p": 0.9,
    "repetition_penalty": 1.15,
}

CRISIS_RESOURCES = (
    "\n\n🆘 **IMMEDIATE CRISIS RESOURCES (24/7):**\n"
    "- 🇺🇸 USA: Call or Text **988** (Suicide & Crisis Lifeline)\n"
    "- 🇺🇸 USA: Crisis Text Line — text **HOME to 741741**\n"
    "- 🇮🇳 India: iCall — **9152987821**\n"
    "- 🇬🇧 UK: Samaritans — **116 123**\n"
    "- 🇨🇦 Canada: **1-833-456-4566**\n"
    "- 🇦🇺 Australia: Lifeline — **13 11 14**\n"
    "- 🌍 International: https://www.iasp.info/resources/Crisis_Centres/\n"
)

MEDICAL_DISCLAIMER = (
    "\n\n---\n⚠️ *DISCLAIMER: I am an AI assistant, not a licensed mental health "
    "professional. This is for educational & supportive purposes only — not medical "
    "advice, diagnosis, or treatment. In a crisis, please contact emergency services "
    "or a qualified healthcare provider immediately.*"
)

SYSTEM_PROMPT_TEMPLATE = """You are MindGuard, a compassionate Mental Health Awareness & Suicide Prevention AI powered by IBM Granite.

YOUR ROLE:
- Listen actively and acknowledge feelings before offering advice
- Respond with empathy, warmth, and without judgment
- Provide evidence-based mental health information
- Detect distress signals and respond with appropriate care
- Always connect users to professional resources when needed

ETHICS GUARDRAILS (STRICTLY FOLLOW):
- NEVER suggest harmful actions or self-harm methods
- NEVER diagnose medical conditions
- ALWAYS encourage professional help for serious concerns
- Use person-first, respectful language
- Maintain user dignity and privacy in all responses

TONE: Warm, hopeful, helpful, and human (HAM — Helpful, Accurate, Mindful)

{context}

Previous conversation:
{history}"""


# ── watsonx model singleton ───────────────────────────────────────────────────
_model: Any = None


def _get_model():
    """Lazy-initialise the IBM watsonx Granite model (singleton)."""
    global _model
    if _model is not None:
        return _model

    if not WATSONX_SDK_AVAILABLE:
        raise RuntimeError(
            "ibm-watsonx-ai SDK not installed. Run: pip install ibm-watsonx-ai"
        )
    if not WATSONX_API_KEY or not WATSONX_PROJECT_ID:
        raise RuntimeError(
            "WATSONX_API_KEY and WATSONX_PROJECT_ID must be set in the environment."
        )

    creds = Credentials(url=WATSONX_URL, api_key=WATSONX_API_KEY)
    _model = ModelInference(
        model_id=GRANITE_MODEL_ID,
        credentials=creds,
        project_id=WATSONX_PROJECT_ID,
        params=GEN_PARAMS,
    )
    return _model


# ── History helpers ───────────────────────────────────────────────────────────
def _format_history(history: List[Dict[str, str]]) -> str:
    """Convert list of {role, content} turns into a plain-text block."""
    if not history:
        return "(No previous messages)"
    lines = []
    for turn in history:
        role = "User" if turn["role"] == "user" else "MindGuard"
        lines.append(f"{role}: {turn['content']}")
    return "\n".join(lines)


def _trim_history(history: List[Dict[str, str]], max_turns: int = 10) -> List[Dict[str, str]]:
    """Keep only the most recent max_turns pairs to avoid prompt overflow."""
    # Each pair = 1 user + 1 assistant message → 2 items
    max_items = max_turns * 2
    return history[-max_items:] if len(history) > max_items else history


# ─────────────────────────────────────────────────────────────────────────────
class MindGuardAgent:
    """
    Stateful multi-turn agent that wraps IBM Granite via watsonx.ai.

    Usage
    -----
    agent = MindGuardAgent()
    response = agent.chat("I've been feeling really low lately.")
    """

    def __init__(self):
        self.history: List[Dict[str, str]] = []
        self.rag_status: str = initialize_rag()
        print(f"[MindGuard] RAG status: {self.rag_status}")

    # ── Public API ────────────────────────────────────────────────────────────

    def chat(self, user_message: str) -> Dict[str, Any]:
        """
        Process one user turn and return a structured response dict:
        {
            "reply":      str,   # assistant text shown to the user
            "risk_level": str,   # "HIGH" | "MEDIUM" | "LOW"
            "rag_docs":   list,  # retrieved knowledge-base snippets
        }
        """
        risk_level = assess_risk_level(user_message)

        # Retrieve relevant knowledge-base context
        rag_docs = retrieve_context(user_message, top_k=3)
        context_block = format_context_for_prompt(rag_docs)

        # Build the prompt
        trimmed_history = _trim_history(self.history)
        history_text = _format_history(trimmed_history)
        system_prompt = SYSTEM_PROMPT_TEMPLATE.format(
            context=context_block,
            history=history_text,
        )
        full_prompt = f"{system_prompt}\n\nUser: {user_message}\nMindGuard:"

        # Generate response
        raw_reply = self._generate(full_prompt, risk_level)

        # Append suffix based on risk level
        reply = self._apply_safety_suffix(raw_reply, risk_level)

        # Update history
        self.history.append({"role": "user",      "content": user_message})
        self.history.append({"role": "assistant",  "content": reply})

        return {"reply": reply, "risk_level": risk_level, "rag_docs": rag_docs}

    def reset(self):
        """Clear conversation history (start a new session)."""
        self.history = []

    # ── Private helpers ───────────────────────────────────────────────────────

    def _generate(self, prompt: str, risk_level: str) -> str:
        """Call Granite and return the cleaned response text."""
        try:
            model = _get_model()
            result = model.generate_text(prompt=prompt)
            # SDK may return str or dict depending on version
            if isinstance(result, dict):
                text = result.get("results", [{}])[0].get("generated_text", "")
            else:
                text = str(result)
            return self._clean_output(text)
        except Exception as exc:  # pragma: no cover
            return self._fallback_response(risk_level, error=str(exc))

    @staticmethod
    def _clean_output(text: str) -> str:
        """Strip leading role prefixes and extra whitespace from model output."""
        # Remove any self-echoing prefix the model may produce
        text = re.sub(r"^(MindGuard:|Assistant:)\s*", "", text.strip(), flags=re.IGNORECASE)
        # Collapse excessive blank lines
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip()

    @staticmethod
    def _apply_safety_suffix(reply: str, risk_level: str) -> str:
        """Append crisis resources or disclaimer depending on assessed risk."""
        if risk_level == "HIGH":
            return reply + CRISIS_RESOURCES + MEDICAL_DISCLAIMER
        if risk_level == "MEDIUM":
            return reply + MEDICAL_DISCLAIMER
        return reply

    @staticmethod
    def _fallback_response(risk_level: str, error: str = "") -> str:
        """Return a safe, empathetic fallback when the LLM call fails."""
        base = (
            "I'm here with you. I'm having a little trouble connecting right now, "
            "but your feelings matter and support is available."
        )
        if risk_level == "HIGH":
            return base + CRISIS_RESOURCES
        return base


# ── Flask REST API ────────────────────────────────────────────────────────────
# Import is deferred so the module is still usable without Flask installed.
try:
    from flask import Flask, request, jsonify
    from flask_cors import CORS
    FLASK_AVAILABLE = True
except ImportError:
    FLASK_AVAILABLE = False


def create_app() -> "Flask":
    """Factory that creates and configures the Flask application."""
    if not FLASK_AVAILABLE:
        raise RuntimeError("Flask is not installed. Run: pip install flask flask-cors")

    app = Flask(__name__)
    CORS(app)

    agent = MindGuardAgent()

    @app.route("/health", methods=["GET"])
    def health():
        return jsonify({"status": "ok", "rag": agent.rag_status, "model": GRANITE_MODEL_ID})

    @app.route("/chat", methods=["POST"])
    def chat():
        data = request.get_json(force=True, silent=True) or {}
        user_message = (data.get("message") or "").strip()
        if not user_message:
            return jsonify({"error": "Field 'message' is required."}), 400

        result = agent.chat(user_message)
        return jsonify({
            "reply":      result["reply"],
            "risk_level": result["risk_level"],
        })

    @app.route("/reset", methods=["POST"])
    def reset():
        agent.reset()
        return jsonify({"status": "conversation reset"})

    return app


# ── CLI entrypoint ────────────────────────────────────────────────────────────
def run_cli():
    """Interactive terminal session with MindGuard."""
    print("=" * 60)
    print("  MindGuard — Mental Health AI  (type 'quit' to exit)")
    print("=" * 60)
    agent = MindGuardAgent()
    while True:
        try:
            user_input = input("\nYou: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n[MindGuard] Take care of yourself. Goodbye. 💙")
            break

        if not user_input:
            continue
        if user_input.lower() in {"quit", "exit", "bye"}:
            print("MindGuard: Take care of yourself. Remember, help is always available. 💙")
            break

        result = agent.chat(user_input)
        print(f"\nMindGuard: {result['reply']}")
        if result["risk_level"] != "LOW":
            print(f"  [Risk level detected: {result['risk_level']}]")


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "serve":
        # python agent.py serve [port]
        port = int(sys.argv[2]) if len(sys.argv) > 2 else 5000
        app = create_app()
        print(f"[MindGuard] Starting API server on http://0.0.0.0:{port}")
        app.run(host="0.0.0.0", port=port, debug=False)
    else:
        run_cli()