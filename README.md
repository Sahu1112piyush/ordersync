# OrderSync - Offline-First Order Management App (Flutter)

A production-grade, offline-first Order Management mobile and web application built with **Flutter**, **Riverpod**, and **Local Persistence**.

OrderSync enables logistics managers and delivery teams to manage, search, filter, and transition order statuses seamlessly—even when internet connectivity is completely lost. Offline status updates are cached locally in a sequential FIFO queue and automatically synchronized to the remote server once connectivity is restored, featuring a deterministic conflict resolution engine.

---

## 📌 Project Overview & Deliverables

This repository contains full deliverables for both **Task A** (Offline-First Order App Implementation) and **Task B** (Engineering Audit, Review Framework, Release Pipeline & Performance Budget).

### 🚀 Task A - 4 Core Screens Implementation

1. **Orders List Screen**: Real-time search by ID/Customer/Item, status filter tabs (`All`, `Pending`, `Accepted`, `Packed`, `Shipped`, `Delivered`, `Cancelled`), pull-to-refresh sync, and live network status indicators.
2. **Order Detail Screen**: Full breakdown including Order ID, Customer Details, Delivery Address, Phone (with copy/call actions), Itemized Product List, Payment Status badge, and a visual workflow timeline stepper.
3. **Status Update Screen**: Valid order status transition flow (`Pending ➔ Accepted ➔ Packed ➔ Shipped ➔ Delivered`), update notes, and an offline warning banner.
4. **Settings / Profile Screen**: User profile, Light/Dark mode switcher, **Network Simulation Mode Toggle** (Force Offline for testing), **Server Conflict Testing Tool**, Sync Queue Dashboard, Conflict Resolution Audit Logs, and footer credit.

---

### 📄 Task B - Mobile Engineering Audit & Operations

Full detailed documentation for **Task B** is available in [TASK_B_DOCUMENTATION.md](file:///c:/Users/lenovo/StudioProjects/OrderSync/TASK_B_DOCUMENTATION.md).

#### 📦 Task B Deliverables:

- **Review framework**: 7-step checklist for diagnosing app slowness (Folder Structure, Re-render scope, API overhead, Memory leaks, Asset optimization, Bundle size, Crash tracing).
- **Written code review with findings**: Comprehensive analysis of real-world app strengths, anti-patterns, and actionable optimization roadmap.
- **Release process proposal**: Enterprise 8-stage CI/CD delivery pipeline (PR ➔ Linter/Tests ➔ Code Review ➔ Staging/QA ➔ Beta Release ➔ 10%-100% Staged Rollout ➔ Crash Monitoring).
- **Performance budget**: Strict engineering thresholds for APK size (<40 MB), Startup time (<2 sec), Crash rate (<1%), Memory footprint (<200 MB), and UI FPS (>=55).
- **Recommended Architecture Stack**: Production Flutter architecture blueprint combining **Riverpod**, **GoRouter**, **Dio**, **Hive**, **Connectivity Plus**, and **Clean Architecture**.

---

## 🏗️ Architecture & State Management Rationale

### Why Riverpod? (`flutter_riverpod`)

For state management, **Riverpod** was chosen over Provider or BLoC for several fundamental architectural reasons:

1. **Decoupled from `BuildContext`**: Sync engines, network listeners, and repository queues operate asynchronously outside the Widget tree. Riverpod's `Ref` and `Notifier` architecture allows repositories and offline sync managers to listen to connectivity changes without relying on UI context.
2. **Compile-Safe & Immutable State**: Riverpod guarantees compile-time safety and prevents unhandled null states or missing providers at runtime.
3. **Seamless Dependency Overriding for Testing**: Mocking `LocalStorageService`, `MockRemoteDataSource`, or `ConnectivityNotifier` during unit tests is clean and concise using `ProviderScope(overrides: [...])`.
4. **Declarative State Notifiers**: `OrderNotifier` cleanly coordinates order filtering, search queries, offline queue status, and background auto-sync in a single reactive, testable class.

---

## 🔄 Offline-First & Sync Engine Architecture

```
                       [ USER ACTION ]
                              │
                    Is Network Available?
                     /                 \
                 [ YES ]              [ NO ]
                    │                    │
          Post to Server API     Save to Local DB (Hive/Prefs)
                    │                    │
       Check Server Conflicts?    Add to Sequential Sync Queue
         /              \                │
    [ NO ]            [ YES ]     Mark Order: "Pending Sync"
      │                  │               │
  Updated          Apply Conflict        │ (When Network Restores)
                 Resolution Matrix       │
                         │          Auto-Process Queue (FIFO)
                         └───────────────┘
```

### 1. Local Database Persistence

- `LocalStorageService` persists the local order state, pending `SyncAction` queue, conflict audit logs, and theme settings locally using persistent JSON/key-value storage.

### 2. Sequential Queue System (FIFO)

- When offline updates occur, a `SyncAction` object (`actionId`, `orderId`, `previousStatus`, `targetStatus`, `timestamp`, `retryCount`) is stored in the queue.
- Upon connectivity restoration (detected automatically via `connectivity_plus` or triggered manually via "Sync Now"), `OrderRepository.processPendingQueue()` executes queue items **sequentially (one-by-one in FIFO order)**.
- Drained items are safely removed from local storage upon successful server confirmation.

### 3. Conflict Resolution Matrix

When an offline update is synced, the server status might have shifted while the client was disconnected (e.g. Server = `Delivered` vs Offline Client Update = `Cancelled`).

`ConflictResolver` resolves conflicts using a deterministic rule matrix:

| Server Status       | Offline Client Target      | Resolution                 | Strategy / Rationale                                                                                                                        |
| :------------------ | :------------------------- | :------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------ |
| **Delivered** | **Cancelled**        | **Delivered**        | **Terminal Precedence Rule**: Once physically delivered on server, offline cancellation is rejected to protect fulfillment integrity. |
| **Cancelled** | **Delivered**        | **Cancelled**        | **Terminal Precedence Rule**: Server cancellation takes precedence over late offline delivery attempt.                                |
| **Pending**   | **Packed / Shipped** | **Packed / Shipped** | **Progressive Rank Advancement**: Higher workflow rank advances order progress.                                                       |
| **Shipped**   | **Accepted**         | **Shipped**          | **Regressive Update Ignored**: Server is at a more advanced state; regressive client update is discarded.                             |
| *Equal Rank*      | *Equal Rank*             | *Newer Timestamp*        | **Last-Write-Wins Matrix**: Timestamps break ties for equal rank updates.                                                             |

*Every resolved conflict is logged into the **Conflict Resolution Audit History** view in the Settings screen for complete transparency.*

---

## 📊 Performance Budget & Quality Guardrails

| Metric                           | Budget Target | Max Threshold           | Action on Breach                                          |
| :------------------------------- | :------------ | :---------------------- | :-------------------------------------------------------- |
| **Android APK Size**       | `< 25 MB`   | **`< 40 MB`**   | Block PR; audit asset sizes & remove unused dependencies. |
| **App Startup Time (TTI)** | `< 1.2 sec` | **`< 2.0 sec`** | Defer heavy initialization to async background tasks.     |
| **Crash Rate**             | `< 0.1%`    | **`< 1.0%`**    | Immediate hotfix patch release; halt phased rollout.      |
| **Memory Footprint**       | `< 120 MB`  | **`< 200 MB`**  | Audit image cache sizes & dispose active controllers.     |
| **UI Frame Rate**          | `60 FPS`    | **`>= 55 FPS`** | Optimize rebuild scope with`Consumer` / `select`.     |

---

## 🧪 Testing

The repository contains automated unit and integration tests under `test/`:

- `test/conflict_resolver_test.dart`: Validates terminal state rules, precedence ranks, and timestamp resolution.
- `test/sync_logic_test.dart`: Tests offline order saving, sequential queue processing, queue draining, and conflict logging.
- `test/widget_test.dart`: Tests full widget rendering and navigation.

To execute the test suite:

```bash
flutter test
```

To run static code analysis (0 warnings):

```bash
flutter analyze
```

---

## 🚀 How to Run the App

### Prerequisites

- Flutter SDK (v3.19+ or v3.41+)
- Dart SDK (v3.3+)

### Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/Sahu1112piyush/pashuvision.git
   cd OrderSync
   ```
2. Get Flutter dependencies:

   ```bash
   flutter pub get
   ```
3. Run on Web or Mobile:

   ```bash
   flutter run -d chrome
   ```
4. Build Release Bundle:

   ```bash
   flutter build web --release
   ```

   *or for Android APK:*
   ```bash
   flutter build apk --release
   ```

---

## 📜 Credit & Live Verification

This project features the required credit line in the settings footer:

> **Built for Digital Heroes Training Task** — [digitalheroesco.com](https://digitalheroesco.com)
