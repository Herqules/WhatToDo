# WhatToDo (WTD)

**WhatToDo** is a full-stack, cross-platform event discovery app that helps users find local and relevant events by location, interest, price, and distance radius. Built with Flutter (frontend) and FastAPI (backend), it unifies events from SeatGeek, Ticketmaster, and Eventbrite APIs.

---

## 🧠 Features

- 🔍 Search by **city or address**
- 🎭 Filter by **event interests**: music, comedy, sports, etc.
- 💰 Filter by **price range** ($0 – $1500)
- 📍 Filter by **radius** (0–100 miles)
- ↕️ Sort by **title** or **price**
- 📦 Normalized data from SeatGeek, Ticketmaster, and Eventbrite
- ⚙️ Expandable for mobile and map integration

---

## ⚙️ Technologies Used

| Layer       | Stack                      |
|-------------|----------------------------|
| Frontend    | Flutter (Web/Desktop)      |
| Backend     | Python, FastAPI            |
| APIs        | SeatGeek, Ticketmaster, Eventbrite |
| Mapping     | OpenStreetMap (Nominatim)  |
| Distance    | geopy                      |
| Dev Server  | Uvicorn (with `--reload`)  |

---

## 📁 Project Structure

```
WhatToDo/
├── backend/
│   ├── apis/          # API integrations (SeatGeek, TM, EB)
│   ├── models/        # Normalized event model
│   ├── utils/         # Env + location conversion
│   └── main.py        # FastAPI entrypoint
├── frontend/
│   └── lib/
│       ├── screens/   # Main UI
│       ├── widgets/   # Components (cards, pickers)
│       ├── services/  # API requests
│       └── main.dart  # Flutter entrypoint
```

---

## 🚀 Getting Started

### 🔌 Backend Setup

1. Navigate to backend directory (or root if using virtual env globally):
   ```bash
   cd WhatToDo
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Create a `.env` file inside `/backend`:
   ```
   SEATGEEK_API_KEY=your_seatgeek_api_key
   TICKETMASTER_API_KEY=your_ticketmaster_key
   EVENTBRITE_API_TOKEN=your_eventbrite_token
   ```

4. Launch backend server:
   ```bash
   uvicorn backend.main:app --reload
   ```

5. Visit the Swagger UI to test:  
   http://127.0.0.1:8000/docs

---

### 💻 Frontend Setup

1. Navigate to the frontend:
   ```bash
   cd frontend
   ```

2. Install Flutter packages:
   ```bash
   flutter pub get
   ```

3. Run in browser (Chrome):
   ```bash
   flutter run -d chrome -t lib/main.dart
   ```

4. Open http://localhost:<flutter_port> to test

---

## 🔧 Example Endpoint

```http
GET /events/all
?city=new york
&interest=comedy
&min_price=0
&max_price=1500
&radius=100
&sort_by=price
```

Returns JSON list of filtered, normalized event data.

---

## 🛠️ Known Issues

- API keys are required — otherwise you’ll receive a 500 error
- Duplicate city names (e.g. Athens, GA vs Athens, Greece) can confuse geocoder
- Styling quirks may occur for dropdowns on web
- Not mobile-optimized yet

---

## 🧭 Roadmap

- ✅ Sorting by price/title
- ✅ Dropdown UI with visual highlight
- ⏳ Auto-location detection
- ⏳ Favorites list
- ⏳ Map view with markers
- ⏳ Admin suggestion moderation panel
- ⏳ Native app builds (iOS/Android)

---

## 🧪 Cities for Testing
- New York  
- Austin  
- Los Angeles  
- Chicago  
- San Francisco  
- Atlanta  
- Miami  
- Las Vegas
---

## 📤 Deployment Notes
When ready for production:
- Limit allowed CORS origins
- Add rate limiting / error handling to backend
- Replace test logging with structured logs
- Secure your API keys and tokens
