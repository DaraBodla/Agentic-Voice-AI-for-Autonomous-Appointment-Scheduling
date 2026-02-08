# 📞 CallPilot — Flutter App

> Agentic Voice AI Receptionist — autonomously schedules appointments by calling providers in parallel, negotiating slots, checking your calendar, and ranking the best options.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.2+ ([install](https://docs.flutter.dev/get-started/install))
- Dart 3.2+

### Run in Demo Mode (no API keys needed)
```bash
cp .env.example .env
flutter pub get
flutter run
```

Demo mode uses simulated receptionists with 12 providers, 20 call scenarios, and a pre-configured calendar — everything works offline.

---

## 📁 Project Structure

```
callpilot_flutter/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/
│   │   └── models.dart                    # All data models (Job, Provider, CallResult, etc.)
│   ├── screens/
│   │   ├── home_screen.dart               # Page navigation shell
│   │   ├── request_screen.dart            # Service type, timeframe, preferences
│   │   ├── progress_screen.dart           # Live call status, transcripts, kill switch
│   │   └── results_screen.dart            # Ranked options, confirm booking
│   ├── services/
│   │   ├── campaign_engine.dart           # Core orchestrator — runs calls, ranks results
│   │   ├── demo_data.dart                 # Providers, scenarios, calendar (offline)
│   │   ├── openai_service.dart            # Structured extraction & ranking via GPT-4o
│   │   ├── elevenlabs_service.dart        # Conversational AI + Agentic Functions
│   │   ├── twilio_service.dart            # Outbound phone calls
│   │   ├── google_places_service.dart     # Real provider search
│   │   └── google_calendar_service.dart   # Real calendar free/busy + event creation
│   ├── providers/
│   │   ├── job_provider.dart              # Main state management (ChangeNotifier)
│   │   └── settings_provider.dart         # App mode & service status
│   └── utils/
│       ├── theme.dart                     # Dark theme, colors, typography
│       └── env_config.dart                # .env reader with service detection
├── .env                                   # Your API keys (git-ignored)
├── .env.example                           # Template for API keys
├── pubspec.yaml                           # Dependencies
└── README.md                              # This file
```

---

## 🔑 Environment Variables

Copy `.env.example` to `.env` and fill in keys as needed:

| Variable | Service | Required for |
|----------|---------|-------------|
| `CALLPILOT_MODE` | — | `demo` or `live` |
| `OPENAI_API_KEY` | OpenAI | LLM transcript extraction, ranking explanations |
| `OPENAI_MODEL` | OpenAI | Model to use (default: `gpt-4o`) |
| `ELEVENLABS_API_KEY` | ElevenLabs | Voice AI conversation agent |
| `ELEVENLABS_AGENT_ID` | ElevenLabs | Conversational AI agent ID |
| `ELEVENLABS_VOICE_ID` | ElevenLabs | Voice for TTS notifications |
| `TWILIO_ACCOUNT_SID` | Twilio | Outbound phone calls |
| `TWILIO_AUTH_TOKEN` | Twilio | Outbound phone calls |
| `TWILIO_PHONE_NUMBER` | Twilio | Caller ID for outbound calls |
| `GOOGLE_PLACES_API_KEY` | Google | Real provider search by location |
| `GOOGLE_CLIENT_ID` | Google | Calendar OAuth2 authentication |
| `GOOGLE_CLIENT_SECRET` | Google | Calendar OAuth2 authentication |
| `BACKEND_URL` | Backend | Optional FastAPI backend URL |

### Service Detection
The app automatically detects which services are available based on your `.env` file:
- **All keys empty** → Full demo mode (everything simulated)
- **OpenAI key set** → LLM-powered transcript extraction and ranking explanations
- **Google Places key set** → Real provider search replaces demo data
- **Google Calendar configured** → Real calendar checking replaces demo slots
- **Twilio + ElevenLabs configured** → Real outbound voice calls
- **All keys set** → Full live mode

---

## 🏗 Architecture

### Data Flow
```
1. User submits request (service, time, preferences)
   └→ JobProvider.startCampaign()

2. Provider Lookup
   ├→ [Live] Google Places API
   └→ [Demo] DemoData.providers

3. Parallel Calls (asyncio-style Future.wait)
   ├→ [Live] Twilio call → ElevenLabs AI → OpenAI extraction
   └→ [Demo] Simulated scenarios with calendar validation

4. Ranking Engine
   └→ score = w₁·earliest + w₂·rating + w₃·distance
      → top results with "why" explanations

5. User Confirms → BookingConfirmation
   ├→ [Live] Google Calendar event created
   └→ [Demo] Confirmation code generated
```

### Key Services

| Service | Demo Mode | Live Mode |
|---------|-----------|-----------|
| **Provider Lookup** | `demo_data.dart` (12 providers) | Google Places API |
| **Phone Calls** | Simulated with scenarios | Twilio + ElevenLabs Conversational AI |
| **Calendar Check** | Pre-configured busy slots | Google Calendar free/busy API |
| **Slot Extraction** | Rule-based from scenarios | OpenAI structured JSON output |
| **Ranking** | Weighted scoring formula | Same + OpenAI explanations |
| **Booking** | In-memory confirmation | Google Calendar event + confirmation |

---

## 🐝 Swarm Mode

Launches N calls concurrently using `Future.wait()`:
- **Demo:** 5 simultaneous calls (configurable up to 15)
- Each call is an independent async Future
- Real-time UI updates via `ChangeNotifier`
- Kill switch stops all pending calls

---

## 🛡 Safety

- ❌ **Never auto-books** — explicit user tap on "Confirm Booking"
- 🛑 **Kill switch** — stop all calls at any time
- 📅 **Calendar validation** — every slot checked for conflicts
- 📊 **Confidence scores** — uncertain results flagged
- 📝 **Full audit trail** — every tool call logged

---

## 🎨 UI Design

Dark theme with:
- **DM Sans** typography
- **JetBrains Mono** for data/codes
- Purple accent (#6C5CE7) with complementary green/red/orange
- Three-screen flow: Request → Progress → Results/Confirm
- Real-time status updates with animated indicators
- Expandable transcripts and event logs

---

## 📋 Demo Flow

1. **Request:** Select dentist, set this week's dates, adjust priority sliders, tap "Start Campaign"
2. **Progress:** Watch 5 providers called simultaneously with live status dots, expand transcripts
3. **Results:** See ranked options with scores and explanations, tap #1, confirm booking
4. **Confirmation:** See confirmation code and appointment details

---

## 🔧 Development

```bash
# Run on device/emulator
flutter run

# Run on Chrome (web)
flutter run -d chrome

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Run tests
flutter test
```

---

## License
MIT — Built for hackathon.
