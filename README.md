# SanKart — iOS Product List & Ordering App

A modern, production-ready iOS application built with **SwiftUI**, **Combine**, and **Core Data**, following the Clean **MVVM (Model-View-ViewModel)** and **Repository Pattern**. Designed with an offline-first architecture, smooth interactive animations, and robust error handling.

---

## 🚀 Key Features

* **Offline-First Core Data Architecture**: The product catalog and user cart state persist locally. The app functions seamlessly with or without an active internet connection.
* **Master Sync Engine**:
  * Authenticates via API 1 to retrieve and renew the JWT Bearer Token (`Jwt_Token`).
  * Concurrently synchronizes the Product Master list (API 2) and State Retailer Rates (API 3).
  * Reconciles backend rates with products using `Product_Detail_Code == id` and updates Core Data while preserving active user-selected quantities.
* **Interactive Product List**:
  * Real-time search filtering by product name or code.
  * Custom quantity stepper with **Minus (−)** button, **direct numerical TextField** input with number pad, and **Plus (+)** button.
  * Row-level subtotal computation and rate presentation.
* **Persistent Bottom Summary Card**:
  * Real-time computed metrics: **Total Items** (lines with quantity > 0), **Total Quantity**, and **Total Amount** ($\sum \text{rate} \times \text{qty}$).
  * Interactive Save button with disabled state when cart is empty.
* **Save Order Flow with Remarks**:
  * Tapping Save prompts a modal alert with a `TextField` to capture custom order remarks.
  * Dispatches the formatted order payload to API 4 (`SaveSampleIos`).
  * On success, clears active cart quantities, logs the order into local `CDOrder` history, and presents a success feedback toast.

---

## 🛠 Project Structure

```
SanKart/
├── SanKart.xcodeproj/
│   └── project.pbxproj               # Xcode project definition (iOS 16+, SwiftUI lifecycle)
└── SanKart/
    ├── SanKartApp.swift               # Application entry point (@main)
    ├── Info.plist                     # App Transport Security (ATS) HTTP configurations
    ├── SanKart.xcdatamodeld/         # Core Data Managed Object Model
    │   └── SanKart.xcdatamodel/
    │       └── contents               # CDProduct & CDOrder entities
    ├── CoreData/
    │   ├── PersistenceController.swift# Core Data stack, background contexts, and preview store
    │   ├── CDProduct+Extensions.swift # Safe property accessors and fetch requests
    │   └── CDOrder+Extensions.swift   # Order history entity extensions
    ├── Models/
    │   ├── APIModels.swift            # Strongly typed Decodable & Encodable models
    │   └── CartSummary.swift          # Live computed cart metrics
    ├── Services/
    │   ├── NetworkService.swift       # Async/await HTTP client with auto-token management
    │   └── ProductRepository.swift    # Core Data & Network synchronization engine
    ├── ViewModels/
    │   └── ProductListViewModel.swift # Observable state, cart math, and user actions
    └── Views/
        ├── ProductListView.swift      # Main screen with search, list, pull-to-refresh
        ├── ProductRowView.swift       # Product card with name, rate, and stepper
        └── Components/
            ├── QuantityStepperView.swift # Minus, numeric TextField, and Plus buttons
            ├── SummaryCardView.swift     # Docked bottom card with totals and Save CTA
            ├── RemarksAlertView.swift    # Modal dialog capturing order remarks
            └── ToastView.swift           # Animated HUD feedback notification
```

---

## 📡 Live API Endpoints Integrated

| API # | Endpoint | Method | Headers / Auth | Description |
|---|---|---|---|---|
| **API 1** | `/api/ioslogin` | `POST` | `Content-Type: application/json` | Authenticates default credentials (`sjqa-divya` / `ff@123`) and returns `Jwt_Token`. |
| **API 2** | `/api/qc/getmasterSync?Master_Name=Products` | `GET` | `Authorization: Bearer <token>` | Fetches master product items (`id`, `name`, `Code`, `product_unit`, etc.). |
| **API 3** | `/api/qc/getmasterSync?Master_Name=StateRate` | `GET` | `Authorization: Bearer <token>` | Fetches retailer price matrix matching `Product_Detail_Code` to product `id`. |
| **API 4** | `/api/qc/SaveSampleIos` | `POST` | `Authorization: Bearer <token>` | Dispatches completed order with product line items, total metrics, and user remarks. |

---

## 🖥 How to Run on macOS / Xcode

1. Open `SanKart.xcodeproj` in **Xcode 15 or later**.
2. Select an iOS Simulator target (e.g. **iPhone 15 / 16**, iOS 16+).
3. Press **Cmd + R** to build and run the application.

*Note: Since the API server uses HTTP (`http://sjapi.salesjump.in`), `Info.plist` is already configured with App Transport Security exceptions (`NSAllowsArbitraryLoads`) to ensure network operations run smoothly.*
