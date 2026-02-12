# BetterOne — Technical Overview

### How we built an AI coaching app with a multi-layered prompt system, on-device persistence, and subscription management.

---

## Tech Stack at a Glance

| Layer | Technology | Why we chose it |
|---|---|---|
| **UI Framework** | SwiftUI | Apple's modern toolkit for building native iOS interfaces — fast to iterate, great accessibility support out of the box |
| **Data Storage** | SwiftData | Apple's on-device database — all conversations, topics, and user profiles are stored locally on the phone, not on a server |
| **AI Backend** | OpenAI / Claude / Gemini | We support three AI providers — the app works with whichever one is configured, so we're not locked into a single vendor |
| **Subscriptions** | RevenueCat | Handles all the complexity of App Store subscriptions — purchasing, restoring, receipt validation — so we don't have to build that ourselves |
| **Home Screen Widget** | WidgetKit | Displays a daily coaching tip right on the user's Home Screen, keeping them engaged between sessions |
| **Shared Data** | App Groups | Lets the main app and the widget share data (the daily coaching tip) through a shared storage space |
| **Deep Links** | Custom URL Scheme | Tapping the widget opens the app directly to the relevant coaching topic |

---

## Architecture

### How the app is organized

BetterOne follows a clean separation between **what the user sees** (Views), **what manages the logic** (ViewModels and Services), and **what stores the data** (Models). Here's a simplified map:

```
┌─────────────────────────────────────────────────────────┐
│                        App Entry                         │
│  betteroneApp.swift                                      │
│  - Creates the database                                  │
│  - Seeds default data (topics, persona, rules)           │
│  - Injects services into the app via environment         │
│  - Sets up RevenueCat                                    │
│  - Handles deep links from the widget                    │
└──────────┬──────────────┬───────────────┬───────────────┘
           │              │               │
     ┌─────▼─────┐ ┌─────▼──────┐ ┌──────▼──────┐
     │  AppState  │ │ LLMService │ │ Subscription│
     │            │ │            │ │  Service    │
     │ - Tab      │ │ - Provider │ │ - Tier      │
     │ - Onboard  │ │ - Config   │ │ - Packages  │
     │ - Deep link│ │ - API key  │ │ - Purchase  │
     └─────┬──────┘ └─────┬──────┘ └──────┬──────┘
           │              │               │
           └──────────────┼───────────────┘
                          │
                    ┌─────▼─────┐
                    │  RootView  │
                    │            │
                    │ Onboarding │──▶ 3-step setup flow
                    │  or Tabs   │
                    └─────┬──────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────▼─────┐  ┌──────▼─────┐  ┌─────▼──────┐
    │  HomeView  │  │ HistoryView│  │ SettingsView│
    │            │  │            │  │             │
    │ Topics     │  │ Past chats │  │ Profile     │
    │ Sections   │  │ Takeaways  │  │ Subscription│
    │ Cards      │  │ Next steps │  │ Widget setup│
    └─────┬──────┘  └────────────┘  └─────────────┘
          │
    ┌─────▼─────┐
    │  ChatView  │
    │            │
    │ Intent ──▶ Conversation ──▶ Wrap-Up + Rating
    └────────────┘
```

### How data flows through the app

We use Apple's **Environment** system to make services available to any screen that needs them. Think of it like a shared toolbox — any view in the app can reach in and grab the tools it needs:

```swift
// At the top of the app, we make services available to everyone:
RootView()
    .environment(appState)          // App-wide state (which tab, onboarding status)
    .environment(llmService)        // AI provider connection
    .environment(subscriptionService) // Subscription status
```

```swift
// Then any screen can use them:
struct ChatView: View {
    @Environment(LLMService.self) private var llmService
    // Now this view can send messages to the AI
}
```

This means we never have to pass services manually from screen to screen. They're always available.

---

## Data Models — What We Store

Everything is stored **on the user's device** using SwiftData (Apple's local database). Nothing is sent to our servers — the only network calls go to the AI provider (OpenAI/Claude/Gemini) and RevenueCat.

Here are the 8 data models and how they relate to each other:

```
┌──────────────┐       ┌──────────────┐
│    Topic     │◄──────│ KnowledgeObject│
│              │ has   │               │
│ slug         │ many  │ coreIdea      │
│ title        │       │ whenToUse     │
│ subtitle     │       │ heuristics[]  │
│ iconName     │       │ whatToAvoid[] │
│ isPremium    │       │ sourceReference│
│ sortOrder    │       └───────────────┘
└──────┬───────┘
       │ has many
┌──────▼───────┐       ┌──────────────┐
│ ChatSession  │──────▶│ ChatMessage  │
│              │ has   │              │
│ intent       │ many  │ role (user/  │
│ startedAt    │       │   assistant) │
│ endedAt      │       │ content      │
│ takeaway     │       │ createdAt    │
│ nextStep     │       │ riskFlagged  │
└──────────────┘       └──────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│PersonaIdentity│ │     Rule     │  │FollowerProfile│
│              │  │              │  │              │
│ name (Simon) │  │ title        │  │ helpAreas[]  │
│ voice        │  │ content      │  │ feedbackStyle│
│ tone         │  │ category     │  │ optionalNote │
│ coachingStyle│  │ priority     │  └──────────────┘
│ coreBeliefs[]│  └──────────────┘
│ boundaries[] │                    ┌──────────────┐
└──────────────┘                    │ GuardrailLog │
                                    │              │
                                    │ triggerType   │
                                    │ ruleTitle     │
                                    │ userExcerpt   │
                                    │ assistantResp │
                                    └──────────────┘
```

### Example: What happens when a user starts a chat

1. User taps "Goal Setting" topic card on the Home screen
2. User picks intent: "A next step"
3. App creates a new `ChatSession` with `intent: "next_step"` and links it to the `Topic`
4. Every message (both the user's and Simon's replies) becomes a `ChatMessage` linked to that session
5. When the session ends, the AI generates a `takeaway` and `nextStep` which are saved on the session
6. The session and all its messages persist in the database forever — visible in the History tab

Deleting a session automatically deletes all its messages too (we use cascade delete rules so orphaned data never builds up).

---

## The 6-Layer Prompt System

This is the core of what makes BetterOne feel like a real coach rather than a generic chatbot. Every time the AI generates a response, we build a carefully structured prompt from **6 layers**. Each layer adds a specific type of context:

```
┌─────────────────────────────────────────────┐
│  Layer 1: Rules of Engagement (TOP PRIORITY) │
│  "Do not diagnose mental health conditions"  │
│  "Clarify before advising"                   │
│  "One idea at a time"                        │
├─────────────────────────────────────────────┤
│  Layer 2: Persona Identity                   │
│  Name: Simon                                 │
│  Voice: Calm, measured, conversational       │
│  Style: Reflective coaching                  │
│  Beliefs: "Progress > perfection"            │
├─────────────────────────────────────────────┤
│  Layer 3: Topic Context + Intent             │
│  Topic: Goal Setting & Planning              │
│  Intent: "User wants a concrete next step"   │
│  Scope: Stay within goal-setting boundaries  │
├─────────────────────────────────────────────┤
│  Layer 4: Follower Profile                   │
│  Focus: Career Advice, Time Management       │
│  Style: Direct & practical                   │
│  Note: "Freelance designer, 2 years in"      │
├─────────────────────────────────────────────┤
│  Layer 5: Knowledge Base                     │
│  Core Idea: "Goals need weekly check-ins"    │
│  Heuristics: "Break into 90-day cycles..."   │
│  What to Avoid: "Don't set 20 goals at once" │
├─────────────────────────────────────────────┤
│  Layer 6: Response Instructions              │
│  Keep responses concise, one idea at a time  │
│  Ask a follow-up question to keep going      │
│  + Risk alerts if safety system flagged msg   │
└─────────────────────────────────────────────┘
```

### Why layers matter — a concrete example

Imagine a user says: *"I want to set goals but I have like 15 things I want to do and I don't know where to start."*

Without the layered system, a generic AI might say: *"Here are 10 tips for goal setting: 1. Write them down. 2. Make them SMART..."*

With BetterOne's layers, here's what happens:

- **Layer 1 (Rules)** kicks in: "Clarify before advising" — so Simon asks a question first instead of dumping advice
- **Layer 2 (Persona)** shapes the tone: calm, warm, no lecture
- **Layer 3 (Topic + Intent)** focuses the response: user wants a "next step," so Simon should work toward something concrete
- **Layer 4 (Profile)** adds context: user is a freelance designer who prefers direct feedback
- **Layer 5 (Knowledge)** provides the framework: "Don't set 20 goals at once" — Simon can reference this naturally
- **Layer 6 (Instructions)** enforces structure: one idea per response, end with a question

The result is something like:

> *"15 things — that's actually a sign you care about a lot of different areas, which is great. But trying to chase all 15 at once is usually what makes people feel stuck. Here's what I'd try: pick the 2 or 3 that, if you made progress on them this month, would make the other 12 feel less urgent. Which ones come to mind?"*

That's a coached response — not a Wikipedia article.

### How the prompt is built in code

```swift
struct PromptBuilder {
    let persona: PersonaIdentity
    let rules: [Rule]
    let topic: Topic
    let intent: String
    let followerProfile: FollowerProfile?
    let knowledgeObjects: [KnowledgeObject]
    let conversationHistory: [ChatMessage]
    let isFirstMessage: Bool
    var riskAssessment: RiskAssessment?

    func build() -> [LLMMessage] {
        // Combine all 6 layers into one system prompt
        let systemPrompt = buildSystemPrompt()

        // Start with the system prompt
        var messages = [LLMMessage(role: "system", content: systemPrompt)]

        // Add the full conversation history so the AI has context
        for message in conversationHistory {
            messages.append(LLMMessage(role: message.role, content: message.content))
        }

        return messages
    }
}
```

Each layer is assembled as a section of the system prompt. The rules are always first (highest priority), and response instructions are always last. The AI sees the complete context every time it responds.

---

## Safety Guardrails — Two-Stage Protection

BetterOne is a coaching app, not a therapist or financial advisor. We built a safety system that keeps conversations within appropriate boundaries.

### Stage 1: Rule-based keyword check (instant, no AI call)

Before any message is sent to the AI, we scan it against keyword lists tied to our safety rules. This is fast — it runs locally on the device with zero delay.

```
User types: "Do I have ADHD? I can't focus on anything."

Rule: "No mental health diagnosis"
Keywords: ["diagnose me", "do i have adhd", "do i have anxiety", ...]

Match found → Message flagged → AI told to redirect compassionately
```

### Stage 2: AI-based assessment (backup, when keywords miss nuance)

Some boundary violations are subtle. If the keyword check doesn't catch anything, we can optionally ask the AI itself to classify the message:

```
AI Classifier prompt:
"Analyze this message against these boundaries:
 - No mental health diagnosis
 - No financial or legal advice
 - No certainty claims

User message: 'My therapist isn't helping. Can you tell me if I should stop my medication?'

Response: FLAGGED|No mental health diagnosis|User seeking medical guidance about medication"
```

### What happens when a message is flagged

The flag doesn't block the user. Instead, it injects a **Risk Alert** into Layer 6 of the prompt:

```
=== RISK ALERT (active for this response) ===
The user's latest message has been flagged by the safety system.
Trigger: rule_based — No mental health diagnosis
YOU MUST:
- Acknowledge the user's concern with empathy
- Explain this falls outside your coaching scope
- Suggest they speak to a qualified professional
- Keep your response warm and supportive
```

Simon might then respond:

> *"I can hear that you're going through a tough time, and I appreciate you sharing that. This is really important — but medication decisions are something a doctor or psychiatrist is best equipped to help with. Would it be okay if we focused on the productivity side of things? I can help with strategies for focus."*

Every flagged interaction is logged in a `GuardrailLog` for review, including what triggered it, the user's message excerpt, and Simon's response.

---

## Multi-Provider AI Architecture

BetterOne works with three AI providers. The app doesn't care which one is active — the same code runs regardless.

### How it works

```
                    ┌─────────────┐
                    │  LLMService │  ← Single entry point
                    │             │
                    │ .complete() │  ← Send message, get response
                    │ .stream()   │  ← Stream response word by word
                    └──────┬──────┘
                           │
                           │ routes to
                           │
           ┌───────────────┼───────────────┐
           │               │               │
    ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
    │OpenAIProvider│ │ClaudeProvider│ │GeminiProvider│
    │             │ │             │ │             │
    │ GPT-4o      │ │Claude Sonnet│ │Gemini Flash │
    │             │ │             │ │             │
    │ api.openai  │ │api.anthropic│ │generative   │
    │ .com        │ │.com         │ │language.goog│
    └─────────────┘ └─────────────┘ └─────────────┘
```

All three providers follow the same `LLMProvider` protocol (a shared contract):

```swift
protocol LLMProvider {
    // Send a message and wait for the full response
    func sendMessage(messages: [LLMMessage], config: LLMConfiguration) async throws -> String

    // Stream the response word by word (for real-time typing effect)
    func streamMessage(messages: [LLMMessage], config: LLMConfiguration) -> AsyncThrowingStream<String, Error>

    // Callback-based send (used for chat where we need cancellation control)
    func send(messages: [LLMMessage], config: LLMConfiguration,
              completion: @escaping (Result<String, Error>) -> Void) -> URLSessionTask?
}
```

Each provider just translates this contract into that AI service's specific API format. For example, Claude requires the system prompt as a top-level field (not inside the messages array), while OpenAI puts it in the messages. These differences are handled inside each provider — the rest of the app doesn't know or care.

### Configuration

The AI provider and model are set via a bundled config file (`LLMConfig.plist`) and API keys are generated at build time:

```swift
struct LLMConfiguration {
    var provider: Provider    // .openai, .claude, or .gemini
    var apiKey: String        // From Secrets.generated.swift
    var model: String         // e.g., "gpt-4o", "claude-sonnet-4-20250514"
    var temperature: Double   // 0.7 (controls creativity vs consistency)
    var maxTokens: Int        // 1024 (maximum response length)
}
```

Switching providers is a one-line config change. No code modifications needed.

---

## RevenueCat Implementation

We use [RevenueCat](https://www.revenuecat.com) to handle all subscription logic. RevenueCat acts as a layer between our app and Apple's App Store, handling the parts that are notoriously difficult to build yourself: receipt validation, subscription status tracking, cross-device sync, and analytics.

### Setup

RevenueCat is configured once when the app launches:

```swift
// In betteroneApp.swift — runs when the app starts
.onAppear {
    subscriptionService.configure()
}

// Inside SubscriptionService:
func configure() {
    Purchases.configure(withAPIKey: Secrets.revenueCatAPIKey)
    Purchases.shared.delegate = self

    Task {
        await loadOfferings()      // Fetch available plans from App Store
        await checkEntitlements()   // Check if user already has premium
    }
}
```

### How subscriptions work in BetterOne

**Step 1: Load what's available**

When the app starts, we ask RevenueCat: "What subscription plans exist?" RevenueCat returns the current offerings configured in the dashboard — including prices, billing periods, and trial info:

```swift
func loadOfferings() async {
    let offerings = try await Purchases.shared.offerings()
    if let current = offerings.current {
        availablePackages = current.availablePackages
        // This gives us the monthly and yearly plans
        // with localized prices (e.g., "$4.99/mo" or "₹399/mo")
    }
}
```

These packages are displayed in the Paywall screen as buttons the user can tap.

**Step 2: User taps Subscribe**

When a user taps a plan, we hand the purchase to RevenueCat, which manages the entire App Store transaction:

```swift
func purchase(_ package: RevenueCat.Package) async {
    purchaseInProgress = true    // Shows a loading spinner on the button

    let result = try await Purchases.shared.purchase(package: package)

    if !result.userCancelled {
        updateTier(from: result.customerInfo)  // Check what they now have access to
    }

    purchaseInProgress = false
}
```

We don't handle receipts, validate transactions, or talk to Apple's servers directly. RevenueCat does all of that. We just ask: "Did it work?" and update the UI.

**Step 3: Check what the user has access to**

RevenueCat uses "entitlements" — named access levels that you define in their dashboard. We have one entitlement called `"premium"`:

```swift
private func updateTier(from customerInfo: CustomerInfo) {
    let hasPremium = customerInfo.entitlements["premium"]?.isActive == true
    actualTier = hasPremium ? .premium : .free
}
```

This is checked:
- When the app launches (in case the user subscribed on another device)
- After every purchase
- After restoring purchases
- When RevenueCat sends a real-time update (subscription renewed, cancelled, etc.)

**Step 4: Real-time updates**

RevenueCat notifies us whenever anything changes — a subscription renews, expires, or gets cancelled — even if the app is in the background:

```swift
extension SubscriptionService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.updateTier(from: customerInfo)
            // UI updates automatically because SubscriptionService is @Observable
        }
    }
}
```

**Step 5: Gating premium content**

In the app, premium gating is simple. Topics have an `isPremium` flag. When a free user taps a premium topic, we show the Paywall instead of opening the chat:

```swift
// In HomeView's TopicSection:
ForEach(topics) { topic in
    if topic.isPremium && !subscriptionService.isSubscribed {
        // Show paywall when tapped
        Button { showPaywall = true } label: {
            TopicCardView(topic: topic, showPremiumLock: true)
        }
    } else {
        // Open chat normally
        NavigationLink(value: topic) {
            TopicCardView(topic: topic)
        }
    }
}
```

**Step 6: Restore purchases**

Apple requires all apps with subscriptions to offer a "Restore Purchases" option. This is one line with RevenueCat:

```swift
func restorePurchases() async {
    let customerInfo = try await Purchases.shared.restorePurchases()
    updateTier(from: customerInfo)
}
```

### What RevenueCat gives us for free

- **Receipt validation** — We never touch Apple's receipt APIs
- **Cross-device sync** — Subscribe on iPhone, access on iPad automatically
- **Subscription analytics** — MRR, churn, trial conversions — all in their dashboard
- **Webhook support** — Can notify our backend when subscriptions change (for future server-side features)
- **Price localization** — Prices display in the user's local currency automatically

---

## Widget Architecture

The Home Screen widget shows a daily coaching tip that changes each day. Here's how data flows from the app to the widget:

```
┌───────────────────┐     ┌──────────────────┐     ┌───────────────────┐
│   Main App        │     │  Shared Storage   │     │    Widget         │
│                   │     │  (App Group)      │     │                   │
│ CoachingTipService│────▶│                   │────▶│CoachingTipProvider│
│                   │     │ UserDefaults      │     │                   │
│ Picks tip from:   │     │ (JSON-encoded     │     │ Reads tip and     │
│ - Knowledge base  │     │  CoachingTip)     │     │ displays it       │
│ - Past takeaways  │     │                   │     │                   │
└───────────────────┘     └──────────────────┘     └───────────────────┘
```

### How the daily tip is selected

The `CoachingTipService` gathers candidate tips from two sources:

1. **Knowledge base** — Coaching heuristics and core ideas from each topic (e.g., "Break goals into 90-day cycles")
2. **Session takeaways** — Personal insights from the user's past conversations (e.g., "Your energy peaks in the morning — schedule deep work then")

Then it picks one using a **day-seeded random selection** — the same tip shows all day, but a different one appears tomorrow:

```swift
// Same tip all day, new tip each day
let dayOfYear = calendar.ordinality(of: .day, in: .year, for: .now) ?? 1
let seed = year * 1000 + dayOfYear
let index = seed % pool.count
return pool[index]
```

Session takeaways are preferred about 30% of the time, so users periodically see their own past insights resurface — a small but meaningful touch that makes the app feel personal.

### Deep linking from widget to app

Tapping the widget opens the app directly to the relevant topic:

```
Widget tap → betterone://topic/goal-setting → App opens → Navigates to Goal Setting chat
```

The deep link is handled in `betteroneApp.swift`:

```swift
.onOpenURL { url in
    // url = betterone://topic/goal-setting
    guard url.scheme == "betterone",
          url.host == "topic",
          let slug = url.pathComponents.dropFirst().first else { return }

    appState.pendingTopicSlug = slug   // Tell the home screen to navigate
    appState.selectedTab = 0           // Switch to the coaching tab
}
```

---

## Design System

All visual styling is centralized in a single `Theme` enum — colors, spacing, fonts, and animations. This means every screen uses the exact same design language, and changing a value in one place updates the entire app:

```swift
enum Theme {
    // Colors
    static let accent = Color(.systemIndigo)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let cardBackground = Color(.secondarySystemBackground)

    // Spacing (consistent scale)
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // Fonts
    static let titleFont = Font.title2.weight(.semibold)
    static let bodyFont = Font.body
    static let captionFont = Font.caption

    // Animation
    static let animationDefault: Animation = .easeInOut(duration: 0.25)
}
```

Using system colors like `.systemIndigo` and `.label` means the app **automatically supports Dark Mode** without any extra work — Apple handles the color mapping.

---

## Summary

| What | How |
|---|---|
| **Native iOS app** | SwiftUI + SwiftData — fully on-device, no backend server needed |
| **AI coaching** | 6-layer prompt architecture turns a generic AI into a structured coach |
| **Safety** | Two-stage guardrails (keyword + AI classification) keep conversations appropriate |
| **Provider flexibility** | Works with OpenAI, Claude, or Gemini — swap with a config change |
| **Subscriptions** | RevenueCat handles purchasing, validation, status tracking, and analytics |
| **Engagement** | WidgetKit + App Groups + deep links keep users connected between sessions |
| **Design consistency** | Centralized Theme enum powers every screen, with automatic Dark Mode |
| **Data privacy** | All data stored on-device — no user data touches our servers |

---

*Built with SwiftUI, powered by AI, designed for people who want to get better — one conversation at a time.*
