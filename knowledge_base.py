"""
Knowledge Base for Mental Health Agentic AI
RAG source documents covering mental health awareness, coping strategies, and crisis resources.
"""

MENTAL_HEALTH_DOCUMENTS = [
    # ── Depression ──────────────────────────────────────────────────────────
    {
        "id": "mh_001",
        "category": "depression",
        "title": "Understanding Depression",
        "content": (
            "Depression is a common but serious mood disorder that causes persistent feelings of sadness, "
            "hopelessness, and loss of interest. Symptoms include changes in sleep, appetite, energy level, "
            "concentration, and self-esteem. Depression is not a sign of weakness; it is a medical condition "
            "that responds well to treatment including therapy, medication, and lifestyle changes. "
            "Early detection and professional help are critical."
        ),
    },
    {
        "id": "mh_002",
        "category": "depression",
        "title": "Coping Strategies for Depression",
        "content": (
            "Effective coping strategies for depression: 1) Maintain a daily routine and sleep schedule. "
            "2) Exercise regularly — even a 30-minute walk boosts mood-regulating neurotransmitters. "
            "3) Break tasks into small, manageable steps. 4) Connect with trusted friends or family. "
            "5) Avoid alcohol and substance use. 6) Practice gratitude journaling. "
            "7) Seek professional support through therapy or counseling."
        ),
    },
    # ── Anxiety ─────────────────────────────────────────────────────────────
    {
        "id": "mh_003",
        "category": "anxiety",
        "title": "Understanding Anxiety",
        "content": (
            "Anxiety disorders are the most common mental health condition worldwide, affecting over 284 million people. "
            "Symptoms include excessive worry, restlessness, rapid heartbeat, shortness of breath, and avoidance behaviors. "
            "Anxiety exists on a spectrum from normal stress responses to debilitating panic disorder. "
            "Cognitive Behavioral Therapy (CBT) and mindfulness-based approaches are highly effective treatments."
        ),
    },
    {
        "id": "mh_004",
        "category": "anxiety",
        "title": "Breathing Techniques for Anxiety",
        "content": (
            "Immediate anxiety relief techniques: "
            "1) 4-7-8 Breathing: inhale 4 sec, hold 7 sec, exhale 8 sec — activates the parasympathetic nervous system. "
            "2) Box Breathing: inhale 4 sec, hold 4, exhale 4, hold 4 — used by military to reduce combat stress. "
            "3) Diaphragmatic breathing: breathe deeply into the belly, not the chest. "
            "4) Progressive Muscle Relaxation: tense and release each muscle group for 5–10 seconds. "
            "Practice these daily to build resilience."
        ),
    },
    # ── Suicide Prevention ───────────────────────────────────────────────────
    {
        "id": "mh_005",
        "category": "suicide_prevention",
        "title": "Warning Signs of Suicidal Ideation",
        "content": (
            "Warning signs that someone may be thinking about suicide: talking about wanting to die or being a burden, "
            "expressing hopelessness or having no reason to live, withdrawing from friends and family, "
            "giving away prized possessions, dramatic mood changes, increased substance use, "
            "researching methods of self-harm. If you notice these signs, take them seriously. "
            "Ask directly: 'Are you thinking about suicide?' This does not increase risk — it opens the door to help."
        ),
    },
    {
        "id": "mh_006",
        "category": "suicide_prevention",
        "title": "How to Help Someone in Crisis",
        "content": (
            "If someone is in immediate danger: call emergency services (911 or local equivalent) immediately. "
            "Stay with the person until professional help arrives. Remove access to lethal means if safe to do so. "
            "Listen without judgment. Do not promise to keep suicidal thoughts a secret. "
            "Use the ACT model: Acknowledge their pain, Care by listening, Tell a trusted adult or professional. "
            "Follow up after a crisis — connection is protective."
        ),
    },
    {
        "id": "mh_007",
        "category": "crisis_resources",
        "title": "Global Mental Health Crisis Helplines",
        "content": (
            "CRISIS RESOURCES — Available 24/7: "
            "USA: National Suicide Prevention Lifeline — call or text 988. Crisis Text Line — text HOME to 741741. "
            "UK: Samaritans — 116 123. MIND — 0300 123 3393. "
            "India: iCall — 9152987821. Vandrevala Foundation — 1860-2662-345. "
            "Canada: Crisis Services Canada — 1-833-456-4566. "
            "Australia: Lifeline — 13 11 14. "
            "International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres/ "
            "Online chat support: Crisis Chat at https://www.crisischat.org"
        ),
    },
    # ── Mindfulness ──────────────────────────────────────────────────────────
    {
        "id": "mh_008",
        "category": "mindfulness",
        "title": "Introduction to Mindfulness",
        "content": (
            "Mindfulness is the practice of present-moment awareness without judgment. "
            "Research from Harvard Medical School shows mindfulness reduces anxiety by 38%, depression by 30%, "
            "and stress-related physical symptoms significantly. "
            "Starting practices: 5-minute daily breath-focus meditation, body scan meditation before bed, "
            "mindful eating by chewing slowly and savoring each bite, 'STOP' technique — Stop, Take a breath, "
            "Observe your thoughts, Proceed with awareness."
        ),
    },
    {
        "id": "mh_009",
        "category": "mindfulness",
        "title": "5-4-3-2-1 Grounding Technique",
        "content": (
            "The 5-4-3-2-1 grounding technique helps interrupt panic attacks and dissociation by anchoring you to the present: "
            "Name 5 things you can SEE around you. "
            "Name 4 things you can physically FEEL (e.g., your feet on the floor). "
            "Name 3 things you can HEAR right now. "
            "Name 2 things you can SMELL. "
            "Name 1 thing you can TASTE. "
            "This technique works by engaging all five senses and shifting focus from anxious thoughts to present reality."
        ),
    },
    # ── Self-Care ────────────────────────────────────────────────────────────
    {
        "id": "mh_010",
        "category": "self_care",
        "title": "Daily Mental Health Self-Care Checklist",
        "content": (
            "Daily mental wellness habits supported by research: "
            "Sleep 7-9 hours at consistent times (sleep deprivation increases suicide risk by 1.4x). "
            "Exercise 30 min most days (reduces depression symptoms by up to 47%). "
            "Eat balanced meals with omega-3s, whole grains, leafy greens. "
            "Limit social media to <2 hours/day. "
            "Practice one act of kindness — generosity elevates mood. "
            "Spend 20 min in nature — reduces cortisol by 21%. "
            "Connect meaningfully with one person. Write 3 gratitudes at day's end."
        ),
    },
    # ── Stress ───────────────────────────────────────────────────────────────
    {
        "id": "mh_011",
        "category": "stress",
        "title": "Recognizing and Managing Chronic Stress",
        "content": (
            "Chronic stress occurs when the fight-or-flight response is triggered repeatedly without recovery. "
            "Physical symptoms: headaches, muscle tension, fatigue, digestive issues, frequent illness. "
            "Emotional symptoms: irritability, overwhelm, inability to relax, feeling of dread. "
            "Management strategies: time-blocking to reduce decision fatigue, delegating tasks, "
            "setting clear work-life boundaries, saying 'no' without guilt, "
            "using stress journaling to identify triggers, scheduling regular digital detox periods."
        ),
    },
    # ── Trauma ───────────────────────────────────────────────────────────────
    {
        "id": "mh_012",
        "category": "trauma",
        "title": "Understanding PTSD and Trauma",
        "content": (
            "Post-Traumatic Stress Disorder (PTSD) can develop after experiencing or witnessing traumatic events. "
            "Symptoms include flashbacks, nightmares, hypervigilance, emotional numbness, and avoidance. "
            "Trauma is not a character flaw — it is the nervous system's response to overwhelming events. "
            "Evidence-based treatments include EMDR (Eye Movement Desensitization and Reprocessing), "
            "Trauma-Focused CBT, and somatic therapies. Healing is possible with proper professional support."
        ),
    },
    # ── Peer Support ─────────────────────────────────────────────────────────
    {
        "id": "mh_013",
        "category": "peer_support",
        "title": "How to Support a Friend with Mental Health Struggles",
        "content": (
            "Supporting a friend: Listen without trying to fix — simply say 'I hear you, I'm here for you.' "
            "Avoid dismissive phrases like 'cheer up' or 'others have it worse.' "
            "Check in regularly with simple messages: 'Thinking of you, how are you doing today?' "
            "Help with practical tasks (groceries, rides to appointments). "
            "Encourage professional help gently and offer to help find resources. "
            "Set healthy boundaries — you cannot pour from an empty cup. "
            "Know the difference between supporting and enabling avoidance of professional help."
        ),
    },
]

# ── High-risk keywords for triage ────────────────────────────────────────────
HIGH_RISK_PHRASES = [
    "want to die", "end my life", "kill myself", "suicide", "suicidal",
    "no reason to live", "better off dead", "hurt myself", "self harm",
    "self-harm", "cutting myself", "overdose", "can't go on", "give up on life",
    "don't want to exist", "wish i was dead", "thinking about ending it",
    "nobody would miss me", "burden to everyone",
]

MEDIUM_RISK_PHRASES = [
    "hopeless", "worthless", "helpless", "trapped", "can't take it anymore",
    "everything is pointless", "no way out", "so tired of everything",
    "feel nothing", "feel empty", "numb inside", "exhausted by life",
    "don't see the point", "feel like a failure",
]

def assess_risk_level(text: str) -> str:
    """Return 'HIGH', 'MEDIUM', or 'LOW' risk based on keyword scan."""
    text_lower = text.lower()
    for phrase in HIGH_RISK_PHRASES:
        if phrase in text_lower:
            return "HIGH"
    for phrase in MEDIUM_RISK_PHRASES:
        if phrase in text_lower:
            return "MEDIUM"
    return "LOW"
