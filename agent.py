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
{history}