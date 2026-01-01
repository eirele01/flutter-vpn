# BaganiVPN: Code Execution Flow Detail

This document provides a step-by-step visualization of how the code executes, which files are involved, and how data moves through the system.

---

## 1. Application Startup Flow

**Entry Point:** `lib/main.dart`

```mermaid
sequenceDiagram
    participant M as main() [main.dart]
    participant H as Hive [Local DB]
    participant W as Workmanager [Background]
    participant P as ProviderScope [Riverpod]
    participant UI as HomeScreen [home_screen.dart]

    M->>H: initFlutter() & registerAdapter()
    M->>H: openBox(bagani_vpn_box)
    M->>W: initialize(callbackDispatcher)
    M->>W: registerPeriodicTask(refreshServers)
    M->>P: Wrap app in ProviderScope
    P->>UI: Build HomeScreen
    UI->>UI: Watch vpnControllerProvider
```

---

## 2. Server List Fetching Flow

**Files:** `home_screen.dart` -> `vpn_providers.dart` -> `server_repository_impl.dart` -> `vpn_gate_api_client.dart`

```mermaid
graph LR
    A[HomeScreen] -- watches --> B(serverListProvider)
    B -- calls --> C[ServerRepository.getServers]
    C -- checks --> D{Is Cache valid?}
    D -- Yes --> E[Return List from Hive]
    D -- No --> F[VpnGateApiClient.fetchServers]
    F -- result --> G[VpnGateParser.parseCSV]
    G -- list --> H[Save to Hive]
    H -- return --> E
    E -- emit data --> A
```

---

## 3. VPN Connection Lifecycle

**The "Happy Path" from button click to secure tunnel.**

1. **User Action:** User taps the connect button in `HomeScreen`.
2. **Controller Logic:** `VpnController.connect(server)` is triggered in `vpn_providers.dart`.
3. **Data Prep:** The Base64 configuration from the server is decoded and passed to `_sanitizeConfig`.

```mermaid
flowchart TD
    Start([User Tap Connect]) --> Init[VpnController: Set stage 'connecting']
    Init --> Sanitize[vpn_providers.dart: _sanitizeConfig]

    subgraph Sanitization [Config Cleaning Logic]
        S1[Force dev tun]
        S2[Remove route-method exe]
        S3[Remove block-outside-dns]
        S4[Add mssfix 1200]
    end

    Sanitize --> CALL[VpnEngineImpl.connect]
    CALL --> PLUG[openvpn_flutter plugin]
    PLUG --> NATIVE[Android VpnService]

    NATIVE -- Stream Event --> STAGE[onVpnStageChanged]
    STAGE --> UI_UPD[Update VpnState.stage]
    UI_UPD --> UI_REF[HomeScreen Rebuilds]
```

---

## 4. Real-time Statistics Loop (Powering the UI)

**How the "Download/Upload" numbers move.**

```mermaid
sequenceDiagram
    participant E as Native Engine
    participant P as VpnEngineImpl [vpn_engine_impl.dart]
    participant C as VpnController [vpn_providers.dart]
    participant UI as StatusCard [home_screen.dart]

    Note over E, UI: Recurring every 1-2 seconds
    E->>P: Stream: "{byte_in: 524288, byte_out: 12400}"
    P-->>C: statusStream.listen()
    C->>C: RegEx Match (\d+)
    C->>C: _formatBytes(524288) -> "512.0 KB"
    C->>C: Update state.copyWith(byteInTotal: "512.0 KB")
    C->>UI: Riverpod notifies listener
    UI->>UI: Widget repaints with new value
```

---

## 5. File Responsibilities Summary

| File Path                     | Primary Responsibility                                                  |
| :---------------------------- | :---------------------------------------------------------------------- |
| `main.dart`                   | Bootstrapping, Background task registration.                            |
| `vpn_providers.dart`          | **Core Logic**. Handles the state, cleaning configs, and parsing stats. |
| `vpn_engine_impl.dart`        | **Plugin Wrapper**. Interfaces between Dart and the OpenVPN library.    |
| `vpn_gate_api_client.dart`    | **Networking**. Raw HTTP calls to the server API.                       |
| `vpn_gate_parser.dart`        | **Data Transformation**. Turns raw CSV text into clean Dart Objects.    |
| `home_screen.dart`            | **Main UI**. Reactive display of the connection status and stats.       |
| `server_repository_impl.dart` | **Persistence**. Managing the Hive cache and offline logic.             |
