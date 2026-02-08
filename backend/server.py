"""
CallPilot Backend — WebSocket audio relay + location-based provider lookup.

Pipeline: Browser mic → WS → this server → ElevenLabs Conversational AI → AI audio → browser.
One active call at a time. Location-aware provider discovery.
"""

import asyncio
import json
import os
import base64
import time
import math
import pathlib
from contextlib import asynccontextmanager
from typing import Optional

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

load_dotenv()

# ── Config ───────────────────────────────────────────────────────────────────

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY", "")
ELEVENLABS_AGENT_ID = os.getenv("ELEVENLABS_AGENT_ID", "")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
GOOGLE_PLACES_API_KEY = os.getenv("GOOGLE_PLACES_API_KEY", "")

ELEVENLABS_WS_URL = "wss://api.elevenlabs.io/v1/convai/conversation"

# ── Call State (single active call) ──────────────────────────────────────────

class CallState:
    def __init__(self):
        self.active = False
        self.call_id: Optional[str] = None
        self.started_at: Optional[float] = None
        self.provider_name: str = ""
        self.transcript_lines: list[str] = []
        self.error: Optional[str] = None

    def start(self, provider_name: str):
        if self.active:
            raise ValueError("A call is already in progress")
        self.active = True
        self.call_id = f"call-{int(time.time())}"
        self.started_at = time.time()
        self.provider_name = provider_name
        self.transcript_lines = []
        self.error = None

    def stop(self):
        self.active = False

    def to_dict(self):
        elapsed = 0
        if self.started_at and self.active:
            elapsed = round(time.time() - self.started_at, 1)
        return {
            "active": self.active,
            "call_id": self.call_id,
            "provider_name": self.provider_name,
            "elapsed_seconds": elapsed,
            "transcript": self.transcript_lines[-20:],
            "error": self.error,
        }

call_state = CallState()

# ── Demo provider database (location-aware) ─────────────────────────────────

DEMO_PROVIDERS = {
    "dentist": [
        {"name": "SmileCare Dental Clinic", "phone": "+1-555-0101", "rating": 4.8, "address": "123 Health Blvd", "lat": 0, "lng": 0, "hours": "Mon-Sat 9AM-6PM"},
        {"name": "Downtown Dental Associates", "phone": "+1-555-0102", "rating": 4.5, "address": "456 Main Street", "lat": 0, "lng": 0, "hours": "Mon-Fri 8AM-5PM"},
        {"name": "Pearl White Dentistry", "phone": "+1-555-0103", "rating": 4.9, "address": "789 Oak Avenue", "lat": 0, "lng": 0, "hours": "Mon-Fri 9AM-7PM"},
        {"name": "City Smile Center", "phone": "+1-555-0104", "rating": 4.3, "address": "321 Park Lane", "lat": 0, "lng": 0, "hours": "Mon-Sat 10AM-6PM"},
        {"name": "Gentle Touch Dental", "phone": "+1-555-0105", "rating": 4.7, "address": "654 Elm Street", "lat": 0, "lng": 0, "hours": "Tue-Sat 9AM-5PM"},
    ],
    "mechanic": [
        {"name": "QuickFix Auto Repair", "phone": "+1-555-0201", "rating": 4.6, "address": "100 Auto Row", "lat": 0, "lng": 0, "hours": "Mon-Sat 7AM-6PM"},
        {"name": "Mike's Garage & Service", "phone": "+1-555-0202", "rating": 4.4, "address": "200 Mechanic Way", "lat": 0, "lng": 0, "hours": "Mon-Fri 8AM-5PM"},
        {"name": "Elite Auto Works", "phone": "+1-555-0203", "rating": 4.8, "address": "300 Motor Drive", "lat": 0, "lng": 0, "hours": "Mon-Sat 8AM-7PM"},
        {"name": "Precision Auto Care", "phone": "+1-555-0204", "rating": 4.2, "address": "400 Tire Lane", "lat": 0, "lng": 0, "hours": "Mon-Fri 7AM-6PM"},
        {"name": "Speedy Lube & Repair", "phone": "+1-555-0205", "rating": 4.5, "address": "500 Service Blvd", "lat": 0, "lng": 0, "hours": "Mon-Sun 8AM-8PM"},
    ],
    "salon": [
        {"name": "Luxe Hair Studio", "phone": "+1-555-0301", "rating": 4.9, "address": "10 Fashion Ave", "lat": 0, "lng": 0, "hours": "Tue-Sun 10AM-8PM"},
        {"name": "Shear Elegance Salon", "phone": "+1-555-0302", "rating": 4.6, "address": "20 Style Street", "lat": 0, "lng": 0, "hours": "Mon-Sat 9AM-7PM"},
        {"name": "The Cutting Edge", "phone": "+1-555-0303", "rating": 4.7, "address": "30 Beauty Blvd", "lat": 0, "lng": 0, "hours": "Tue-Sat 10AM-6PM"},
        {"name": "Glow Up Hair & Spa", "phone": "+1-555-0304", "rating": 4.4, "address": "40 Glamour Lane", "lat": 0, "lng": 0, "hours": "Mon-Sun 9AM-9PM"},
        {"name": "Urban Roots Salon", "phone": "+1-555-0305", "rating": 4.8, "address": "50 Trend Ave", "lat": 0, "lng": 0, "hours": "Wed-Mon 11AM-7PM"},
    ],
}

def _haversine_km(lat1, lng1, lat2, lng2):
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng/2)**2
    return R * 2 * math.asin(math.sqrt(a))

def _scatter_demo_providers(providers, lat, lng):
    """Place demo providers around the user's actual location."""
    import random
    rng = random.Random(42)
    result = []
    for p in providers:
        offset_lat = (rng.random() - 0.5) * 0.06  # ~3km spread
        offset_lng = (rng.random() - 0.5) * 0.06
        p2 = dict(p)
        p2["lat"] = round(lat + offset_lat, 6)
        p2["lng"] = round(lng + offset_lng, 6)
        p2["distance_km"] = round(_haversine_km(lat, lng, p2["lat"], p2["lng"]), 1)
        result.append(p2)
    result.sort(key=lambda x: x["distance_km"])
    return result

# ── App ──────────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("🚀 CallPilot backend starting")
    print(f"   ElevenLabs key:    {'✓' if ELEVENLABS_API_KEY else '✕'}")
    print(f"   Agent ID:          {'✓' if ELEVENLABS_AGENT_ID else '✕'}")
    print(f"   OpenAI key:        {'✓' if OPENAI_API_KEY else '✕'}")
    print(f"   Google Places key: {'✓' if GOOGLE_PLACES_API_KEY else '✕'}")
    yield
    call_state.stop()

app = FastAPI(title="CallPilot", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ── REST endpoints ───────────────────────────────────────────────────────────

@app.get("/api/status")
def get_status():
    return call_state.to_dict()

@app.post("/api/stop")
def stop_call():
    call_state.stop()
    return {"ok": True}

@app.get("/api/config")
def get_config():
    return {
        "has_elevenlabs": bool(ELEVENLABS_API_KEY),
        "has_agent": bool(ELEVENLABS_AGENT_ID),
        "has_openai": bool(OPENAI_API_KEY),
        "has_google_places": bool(GOOGLE_PLACES_API_KEY),
        "demo_mode": not (ELEVENLABS_API_KEY and ELEVENLABS_AGENT_ID),
    }

# ── Location-based provider lookup ───────────────────────────────────────────

@app.get("/api/nearby")
async def nearby_providers(
    service: str = Query(..., description="dentist, mechanic, or salon"),
    lat: float = Query(...),
    lng: float = Query(...),
    radius: int = Query(5000, description="search radius in meters"),
):
    """Find providers near a location. Uses Google Places if key is set, otherwise demo data."""

    # Try Google Places first
    if GOOGLE_PLACES_API_KEY:
        try:
            providers = await _google_places_search(service, lat, lng, radius)
            if providers:
                return {"providers": providers, "source": "google_places"}
        except Exception as e:
            print(f"Google Places error: {e}")

    # Fallback to demo providers scattered around user's location
    service_key = service.lower().strip()
    if service_key not in DEMO_PROVIDERS:
        service_key = "dentist"

    providers = _scatter_demo_providers(DEMO_PROVIDERS[service_key], lat, lng)
    return {"providers": providers, "source": "demo"}


async def _google_places_search(service: str, lat: float, lng: float, radius: int):
    """Search Google Places API for nearby providers."""
    type_map = {
        "dentist": "dentist",
        "mechanic": "car_repair",
        "salon": "hair_care",
    }
    place_type = type_map.get(service.lower(), "establishment")

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
            params={
                "location": f"{lat},{lng}",
                "radius": radius,
                "type": place_type,
                "key": GOOGLE_PLACES_API_KEY,
            },
        )
        data = resp.json()

    results = []
    for place in data.get("results", [])[:8]:
        loc = place.get("geometry", {}).get("location", {})
        p_lat = loc.get("lat", lat)
        p_lng = loc.get("lng", lng)
        results.append({
            "name": place.get("name", "Unknown"),
            "phone": "",  # Requires Place Details call
            "rating": place.get("rating", 0),
            "address": place.get("vicinity", ""),
            "lat": p_lat,
            "lng": p_lng,
            "distance_km": round(_haversine_km(lat, lng, p_lat, p_lng), 1),
            "hours": "Call for hours",
            "place_id": place.get("place_id", ""),
        })

    results.sort(key=lambda x: x["distance_km"])
    return results

# ── Google Place details (get phone) ─────────────────────────────────────────

@app.get("/api/place-details")
async def place_details(place_id: str = Query(...)):
    """Get phone number for a Google Place."""
    if not GOOGLE_PLACES_API_KEY:
        return {"phone": "", "error": "No Google Places API key"}

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            "https://maps.googleapis.com/maps/api/place/details/json",
            params={
                "place_id": place_id,
                "fields": "formatted_phone_number,international_phone_number,opening_hours",
                "key": GOOGLE_PLACES_API_KEY,
            },
        )
        data = resp.json()

    result = data.get("result", {})
    return {
        "phone": result.get("international_phone_number", result.get("formatted_phone_number", "")),
        "hours": ", ".join(result.get("opening_hours", {}).get("weekday_text", [])[:3]),
    }

# ── Reverse geocode (coordinates → address) ──────────────────────────────────

@app.get("/api/geocode")
async def reverse_geocode(lat: float = Query(...), lng: float = Query(...)):
    """Convert coordinates to a human-readable address."""
    if GOOGLE_PLACES_API_KEY:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(
                    "https://maps.googleapis.com/maps/api/geocode/json",
                    params={"latlng": f"{lat},{lng}", "key": GOOGLE_PLACES_API_KEY},
                )
                data = resp.json()
            results = data.get("results", [])
            if results:
                addr = results[0].get("formatted_address", "")
                # Extract city/area from address components
                components = results[0].get("address_components", [])
                city = next((c["long_name"] for c in components if "locality" in c["types"]), "")
                area = next((c["long_name"] for c in components if "sublocality" in c["types"]), "")
                return {"address": addr, "city": city, "area": area or city}
        except Exception:
            pass
    return {"address": f"{lat:.4f}, {lng:.4f}", "city": "", "area": ""}

# ── WebSocket: browser ↔ ElevenLabs relay ────────────────────────────────────

@app.websocket("/ws/call")
async def websocket_call(ws: WebSocket):
    await ws.accept()

    try:
        init_msg = await asyncio.wait_for(ws.receive_text(), timeout=10)
        config = json.loads(init_msg)
        provider_name = config.get("provider_name", "Unknown Provider")
        service_type = config.get("service_type", "appointment")
    except Exception as e:
        await ws.send_json({"type": "error", "message": f"Bad init: {e}"})
        await ws.close()
        return

    if call_state.active:
        await ws.send_json({"type": "error", "message": "Another call is already in progress"})
        await ws.close()
        return

    try:
        call_state.start(provider_name)
    except ValueError as e:
        await ws.send_json({"type": "error", "message": str(e)})
        await ws.close()
        return

    await ws.send_json({"type": "status", "message": "connecting", "call_id": call_state.call_id})

    if not ELEVENLABS_API_KEY or not ELEVENLABS_AGENT_ID:
        await _run_demo_call(ws, provider_name, service_type)
        return

    await _run_live_call(ws, provider_name, service_type)


async def _run_demo_call(ws: WebSocket, provider_name: str, service_type: str):
    import random
    demo_lines = [
        f"Hello, this is {provider_name}. How can I help you today?",
        f"Sure, let me check our schedule for {service_type} appointments...",
        "We have an opening tomorrow at 2:30 PM.",
        "We also have availability on Thursday at 10:00 AM.",
        "Would either of those times work for you?",
        "Great! I'll pencil that in for you. Is there anything else?",
        "Thank you for calling! Have a wonderful day.",
    ]
    await ws.send_json({"type": "status", "message": "connected"})
    call_state.transcript_lines.append(f"[Demo] Call with {provider_name}")

    try:
        for i, line in enumerate(demo_lines):
            if not call_state.active:
                break
            try:
                await asyncio.wait_for(ws.receive(), timeout=3)
            except asyncio.TimeoutError:
                pass

            call_state.transcript_lines.append(f"Receptionist: {line}")
            await ws.send_json({"type": "transcript", "role": "assistant", "text": line})
            silence = base64.b64encode(b'\x00' * 3200).decode()
            await ws.send_json({"type": "audio", "data": silence, "format": "pcm16", "sample_rate": 16000})
            await asyncio.sleep(2 + random.random() * 1.5)

        await ws.send_json({
            "type": "call_ended", "reason": "completed",
            "summary": {
                "slots_offered": [
                    {"datetime": "2025-02-10T14:30:00", "duration": 30},
                    {"datetime": "2025-02-13T10:00:00", "duration": 30},
                ],
                "provider": provider_name,
            },
        })
    except WebSocketDisconnect:
        pass
    finally:
        call_state.stop()


async def _run_live_call(ws: WebSocket, provider_name: str, service_type: str):
    import websockets
    eleven_ws = None
    try:
        url = f"{ELEVENLABS_WS_URL}?agent_id={ELEVENLABS_AGENT_ID}"
        eleven_ws = await websockets.connect(url, additional_headers={"xi-api-key": ELEVENLABS_API_KEY})

        await eleven_ws.send(json.dumps({
            "type": "conversation_initiation_client_data",
            "conversation_config_override": {
                "agent": {
                    "prompt": {
                        "prompt": (
                            f"You are calling {provider_name} to book a {service_type} appointment. "
                            f"Be polite, ask about available time slots, and confirm details."
                        ),
                    },
                },
            },
        }))
        await ws.send_json({"type": "status", "message": "connected"})

        async def browser_to_eleven():
            try:
                while call_state.active:
                    msg = await ws.receive()
                    if msg.get("type") == "websocket.disconnect":
                        break
                    if "bytes" in msg:
                        await eleven_ws.send(json.dumps({"user_audio_chunk": base64.b64encode(msg["bytes"]).decode()}))
                    elif "text" in msg:
                        data = json.loads(msg["text"])
                        if data.get("type") == "stop":
                            break
                        if data.get("type") == "audio" and data.get("data"):
                            await eleven_ws.send(json.dumps({"user_audio_chunk": data["data"]}))
            except (WebSocketDisconnect, Exception):
                pass

        async def eleven_to_browser():
            try:
                async for message in eleven_ws:
                    if not call_state.active:
                        break
                    data = json.loads(message)
                    mt = data.get("type", "")
                    if mt == "audio":
                        await ws.send_json({
                            "type": "audio",
                            "data": data.get("audio_event", {}).get("audio_base_64", ""),
                            "format": "pcm16",
                            "sample_rate": data.get("audio_event", {}).get("sample_rate", 16000),
                        })
                    elif mt == "agent_response":
                        text = data.get("agent_response_event", {}).get("agent_response", "")
                        if text:
                            call_state.transcript_lines.append(f"Agent: {text}")
                            await ws.send_json({"type": "transcript", "role": "assistant", "text": text})
                    elif mt == "user_transcript":
                        text = data.get("user_transcription_event", {}).get("user_transcript", "")
                        if text:
                            call_state.transcript_lines.append(f"User: {text}")
                            await ws.send_json({"type": "transcript", "role": "user", "text": text})
                    elif mt == "conversation_initiation_metadata":
                        conv_id = data.get("conversation_initiation_metadata_event", {}).get("conversation_id", "")
                        await ws.send_json({"type": "status", "message": "session_ready", "conversation_id": conv_id})
                    elif mt in ("error", "internal_error"):
                        err = data.get("message", "ElevenLabs error")
                        call_state.error = err
                        await ws.send_json({"type": "error", "message": err})
                        break
            except Exception as e:
                call_state.error = str(e)

        await asyncio.gather(browser_to_eleven(), eleven_to_browser(), return_exceptions=True)
        await ws.send_json({"type": "call_ended", "reason": "completed", "transcript": call_state.transcript_lines})
    except Exception as e:
        call_state.error = str(e)
        try:
            await ws.send_json({"type": "error", "message": str(e)})
        except Exception:
            pass
    finally:
        call_state.stop()
        if eleven_ws:
            await eleven_ws.close()

# ── Health check ──────────────────────────────────────────────────────────────

@app.get("/")
def health():
    return {"status": "ok", "service": "CallPilot Backend"}
