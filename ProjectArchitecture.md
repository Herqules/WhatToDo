# 📐 Project Architecture – WhatToDo (WTD)

---

## 🧭 Overview

**WhatToDo** is a full-stack, cross-platform event discovery platform built to help users explore local events based on interests and locations. It aggregates and normalizes event data from SeatGeek, Ticketmaster, and Eventbrite, and presents it through a clean Flutter UI.

---

## 🧱 Layered Architecture

### 1. **Frontend (Flutter)**
- **Platform:** Web-first (with support for mobile and desktop)
- **Structure:**
  - `screens/`: Core UI screens
  - `widgets/`: Reusable components (inputs, cards, pickers)
  - `models/`: Event model class
  - `services/`: Network layer and backend integration
- **State Management:** `StatefulWidget` + `setState()` (lightweight for MVP)
- **Interaction Flow:**
  - User enters city + selects interests + sort filter
  - Flutter sends API request to backend (`/events/all`)
  - Data is rendered in scrollable list of event cards

---

### 2. **Backend (FastAPI - Python)**

- **Entrypoint:** `backend/main.py`
- **APIs:** Integrated with:
  - SeatGeek (API key)
  - Ticketmaster (API key)
  - Eventbrite (OAuth/Bearer token)
- **Data Flow:**
  - Query params: city, interests, min/max price, radius, sort_by
  - City is converted to `(lat, lon)` via OpenStreetMap
  - Events fetched concurrently and normalized into unified model
  - Filters (price, distance) applied
  - Sorted result returned to frontend

---

## 🔁 Request Lifecycle (E2E)

```
[User Action] --> Flutter UI --> HTTP Request (GET /events/all) -->
--> FastAPI Receives --> Fetch from APIs (async) -->
--> Normalize + Filter + Sort --> JSON Response -->
--> Flutter Renders Event Cards
```

---

## 🧩 File Structure

```
WhatToDo/
├── backend/
│   ├── apis/
│   │   ├── seatgeek.py
│   │   ├── ticketmaster.py
│   │   └── eventbrite.py
│   ├── models/
│   │   └── event.py
│   ├── utils/
│   │   └── env.py
│   └── main.py
├── frontend/
│   └── lib/
│       ├── screens/
│       │   └── home_screen.dart
│       ├── widgets/
│       │   ├── location_input.dart
│       │   ├── interest_picker.dart
│       │   └── event_card.dart
│       ├── services/
│       │   └── api_service.dart
│       ├── models/
│       │   └── event.dart
│       └── main.dart
```

---

## 🔐 Security & Config

- API Keys stored in `.env` file (not pushed to GitHub)
- `.gitignore` excludes:
  - `.env`
  - `__pycache__/`
  - `*.pyc`, `*.pyo`, `.idea/`, `.vscode/`
- CORS is open during development:  
  `allow_origins=["*"]` — change this before production.

---

## 📦 Dependencies Summary

### 🔽 Backend (Python)
- `fastapi`
- `httpx`
- `python-dotenv`
- `geopy`
- `uvicorn`

### 🔽 Frontend (Flutter)
- `http`
- `url_launcher`
- `flutter/material.dart`
- `cupertino_icons`

---

## 🧪 Testing & Dev Tools

- Swagger Docs: [http://localhost:8000/docs](http://localhost:8000/docs)
- Flutter DevTools: automatically available on `flutter run -d chrome`
- Logs: visible in both `uvicorn` terminal and Flutter console
- Sample cities for dev: `new york`, `los angeles`, `chicago`, `atlanta`

---

## 🧰 Dev Notes

- Do not commit `.env`
- Test endpoints with Swagger before full UI
- Future state management should adopt `Riverpod` or `Bloc` if app grows
- Consider integrating SQLite/local caching to persist favorites

---

## 📌 Future Modularization Plan

- Add `auth/` module (Google login + session tokens)
- Add `favorites/` model for user bookmarks
- Add `map/` package (Google Maps or Leaflet for location visualization)
- Admin dashboard for event flagging / moderation

---

## 🤝 Contributor Guidelines

- Fork, branch, and submit pull requests from feature branches
- Use clear commit messages: `feat:`, `fix:`, `refactor:`
- Always test API keys locally before committing backend changes

---

## 🧠 Designed for:

- 🌍 Local explorers
- 🎤 Event seekers
- 🧑‍💻 Cross-platform MVP developers
- 🧪 API normalization testers
# 📐 Project Architecture – WhatToDo (WTD)

---

## 🧭 Overview

**WhatToDo** is a full-stack, cross-platform event discovery platform built to help users explore local events based on interests and locations. It aggregates and normalizes event data from SeatGeek, Ticketmaster, and Eventbrite, and presents it through a clean Flutter UI.

---

## 🧱 Layered Architecture

### 1. **Frontend (Flutter)**
- **Platform:** Web-first (with support for mobile and desktop)
- **Structure:**
  - `screens/`: Core UI screens
  - `widgets/`: Reusable components (inputs, cards, pickers)
  - `models/`: Event model class
  - `services/`: Network layer and backend integration
- **State Management:** `StatefulWidget` + `setState()` (lightweight for MVP)
- **Interaction Flow:**
  - User enters city + selects interests + sort filter
  - Flutter sends API request to backend (`/events/all`)
  - Data is rendered in scrollable list of event cards

---

### 2. **Backend (FastAPI - Python)**

- **Entrypoint:** `backend/main.py`
- **APIs:** Integrated with:
  - SeatGeek (API key)
  - Ticketmaster (API key)
  - Eventbrite (OAuth/Bearer token)
- **Data Flow:**
  - Query params: city, interests, min/max price, radius, sort_by
  - City is converted to `(lat, lon)` via OpenStreetMap
  - Events fetched concurrently and normalized into unified model
  - Filters (price, distance) applied
  - Sorted result returned to frontend

---

## 🔁 Request Lifecycle (E2E)

```
[User Action] --> Flutter UI --> HTTP Request (GET /events/all) -->
--> FastAPI Receives --> Fetch from APIs (async) -->
--> Normalize + Filter + Sort --> JSON Response -->
--> Flutter Renders Event Cards
```

---

## 🧩 File Structure

```
WhatToDo/
├── backend/
│   ├── apis/
│   │   ├── seatgeek.py
│   │   ├── ticketmaster.py
│   │   └── eventbrite.py
│   ├── models/
│   │   └── event.py
│   ├── utils/
│   │   └── env.py
│   └── main.py
├── frontend/
│   └── lib/
│       ├── screens/
│       │   └── home_screen.dart
│       ├── widgets/
│       │   ├── location_input.dart
│       │   ├── interest_picker.dart
│       │   └── event_card.dart
│       ├── services/
│       │   └── api_service.dart
│       ├── models/
│       │   └── event.dart
│       └── main.dart
```

---

## 🔐 Security & Config

- API Keys stored in `.env` file (not pushed to GitHub)
- `.gitignore` excludes:
  - `.env`
  - `__pycache__/`
  - `*.pyc`, `*.pyo`, `.idea/`, `.vscode/`
- CORS is open during development:  
  `allow_origins=["*"]` — change this before production.

---

## 📦 Dependencies Summary

### 🔽 Backend (Python)
- `fastapi`
- `httpx`
- `python-dotenv`
- `geopy`
- `uvicorn`

### 🔽 Frontend (Flutter)
- `http`
- `url_launcher`
- `flutter/material.dart`
- `cupertino_icons`

---
## 🧪 Testing & Dev Tools

- Swagger Docs: [http://localhost:8000/docs](http://localhost:8000/docs)
- Flutter DevTools: automatically available on `flutter run -d chrome`
- Logs: visible in both `uvicorn` terminal and Flutter console


---

## 🧰 Dev Notes

- Do not commit `.env`
- Test endpoints with Swagger before full UI
- Future state management should adopt `Riverpod` or `Bloc` if app grows
- Consider integrating SQLite/local caching to persist favorites

---
## 📌 Future Modularization Plan
- Add `auth/` module (Google login + session tokens)
- Add `favorites/` model for user bookmarks
- Add `map/` package (Google Maps or Leaflet for location visualization)
- Admin dashboard for event flagging / moderation

---
## 🧠 Designed for:

- 🌍 Local explorers
- 🎤 Event seekers
- 🧑‍💻 Cross-platform MVP developers
- 🧪 API normalization testers
