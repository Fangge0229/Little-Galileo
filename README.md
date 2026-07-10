# Little Galileo (小小星官)

A children's astronomy education app that brings traditional Chinese star lore to life on an interactive sky map.

<p align="center">
  <strong>iOS 17+ &nbsp;|&nbsp; SwiftUI &nbsp;|&nbsp; No third-party dependencies</strong>
</p>

---

## Features

### Interactive Sky Map
- Real-time sky rendering based on GPS location using Julian day, sidereal time, and stereographic projection
- Drag to rotate, pinch to zoom
- Switch between **Chinese asterisms** (310 xing guan) and **Western constellations** (89)
- Realistic star colors from B-V color index and magnitude-based sizing

### Tonight's Picks
- Shows which featured asterisms are visible from your location right now
- Horizontally scrollable cards with constellation line preview, compass bearing, altitude, and difficulty rating

### Card Collection
- Collect asterism cards by exploring them on the sky map
- Progress ring tracks your collection (8 featured asterisms)
- Detail pages with cultural stories, science facts, pinyin, and a traditional Chinese scroll aesthetic

### AI Sky Assistant
- Chat with an AI tutor designed for ages 6-12
- Supports multiple Chinese LLM providers (ZhipuAI, DeepSeek, Qwen, SiliconFlow, Moonshot) via OpenAI-compatible API
- Quick-question buttons, text input, and Chinese speech recognition
- Text-to-speech for AI replies

### Guided Onboarding
- 10-step "Star Bird" tutorial walks new users through every feature
- Spotlight highlights, speech bubbles, animated bird guide
- Teaches complete workflows (open, browse, close) rather than just pointing at buttons

---

## Getting Started

### Prerequisites

- Xcode 15+
- iOS 17+ device or simulator

### Build & Run

```bash
git clone https://github.com/Fangge0229/Little-Galileo.git
cd Little-Galileo
open LittleGalileo.xcodeproj
```

Build and run on a simulator or device from Xcode.

### Configure AI Chat (Optional)

The AI assistant requires an API key from a supported provider. Create a local configuration file:

```bash
cat > LittleGalileo/AIProviderConfig.local.json << 'EOF'
{
  "name": "智谱AI",
  "baseURL": "https://open.bigmodel.cn/api/paas/v4",
  "apiKey": "YOUR_API_KEY_HERE",
  "model": "glm-4-flash"
}
EOF
```

This file is git-ignored and will not be committed. The app works without it — the AI chat will show an error prompt if no key is configured.

**Supported providers:**

| Provider | Base URL | Model |
|----------|----------|-------|
| ZhipuAI (智谱) | `https://open.bigmodel.cn/api/paas/v4` | `glm-4-flash` |
| DeepSeek | `https://api.deepseek.com` | `deepseek-chat` |
| Qwen (通义千问) | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen-turbo` |
| SiliconFlow (硅基流动) | `https://api.siliconflow.cn/v1` | `deepseek-ai/DeepSeek-V3` |
| Moonshot (Kimi) | `https://api.moonshot.cn/v1` | `moonshot-v1-8k` |

Any OpenAI-compatible endpoint works.

---

## Architecture

```
LittleGalileo/
├── Models/          Data models (Star, Asterism, ChatMessage, etc.)
├── Views/           SwiftUI views (SkyMap, Cards, Chat, Onboarding)
├── Services/        Business logic (AstroMath, StarCatalog, ChatService, etc.)
└── Assets.xcassets/ Images (star bird, sky background, decorative art)
```

**Key design choices:**

- **Pure SwiftUI** — Canvas API for star rendering, preference keys for cross-view coordination
- **Real astronomy math** — Julian day, GMST, equatorial-to-horizontal coordinate conversion, stereographic projection
- **No third-party dependencies** — uses only Apple frameworks (CoreLocation, Speech, AVFoundation)
- **Protocol-based AI layer** — `ChatServing` protocol allows easy provider switching and test stubbing

---

## Data

| Dataset | Count | Source |
|---------|-------|--------|
| Chinese asterisms | 310 | Traditional San Yuan Er Shi Ba Xiu system |
| Western constellations | 89 | IAU standard |
| Stars | 1,469 (filtered) / 2,848 (full) | HIP catalog |
| Chinese star names | 3,062 | Historical records |
| Featured asterisms | 8 | With complete story and science content |

---

## Testing

```bash
# Run unit tests
xcodebuild test -scheme LittleGalileo -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -scheme LittleGalileo -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LittleGalileoUITests
```

- **26+ unit tests** — astronomy math, data integrity (all 310 asterisms have complete content), AI service, collection persistence, onboarding state machine
- **10 UI tests** — full onboarding flow, spotlight pixel-alignment verification, tonight recommendation panel, chat panel interaction

---

## License

This project is for educational purposes.
