# SanKart — iOS Technical Assessment

**Submission for:** SANeForce (San-e-force)  
**Role:** iOS Developer Technical Assessment  
**Platform:** iOS 16.0+ | SwiftUI | Combine | Core Data | Swift Concurrency  

---

## 📋 Overview

This repository contains the completed iOS technical assessment for **SANeForce**. The solution implements a production-grade product listing, real-time cart computation, and order dispatch workflow with offline-first local persistence, built using the **MVVM (Model-View-ViewModel)** pattern and **Repository Pattern**.

---

## 🚀 Assessment Requirements & Implementation

* **Offline-First Core Data Persistence**:
  * Product catalog and cart state persist locally using Core Data.
  * Preserves user-entered cart quantities during catalog synchronizations.
* **Master Synchronization Engine**:
  * **API 1 (Authentication)**: Automatically retrieves and renews the JWT Bearer Token (`Jwt_Token`) with concurrency protection.
  * **API 2 (Products Master)** & **API 3 (State Rates)**: Fetched concurrently using Swift Concurrency (`async let`), indexed by `Product_Detail_Code`, and upserted into Core Data on a background context.
* **Interactive Product List & Stepper**:
  * Real-time search filtering by product name or code.
  * Custom quantity stepper supporting **Minus (−)**, **Direct Numerical Input** via number pad `TextField`, and **Plus (+)**.
  * Dynamic subtotal calculations per row.
* **Live Bottom Summary Card**:
  * Real-time computation of **Total Items**, **Total Quantity**, and **Total Amount** ($\sum \text{rate} \times \text{qty}$).
  * Interactive Save button with disabled state when cart is empty.
* **Order Submission Flow with Remarks**:
  * Prompts an alert with a text field to capture custom order remarks.
  * Dispatches the structured order payload to **API 4** (`SaveSampleIos`).
  * On success, clears active cart quantities, stores the order locally in `CDOrder`, and displays animated toast feedback.

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
    │   ├── PersistenceController.swift# Core Data stack, background contexts, and store setup
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

## 📡 Assessment APIs Integrated

| API # | Endpoint | Method | Headers / Auth | Description |
|---|---|---|---|---|
| **API 1** | `/api/ioslogin` | `POST` | `Content-Type: application/json` | Authenticates user credentials via login payload and returns `Jwt_Token`. |
| **API 2** | `/api/qc/getmasterSync?Master_Name=Products` | `GET` | `Authorization: Bearer <token>` | Fetches master product items (`id`, `name`, `Code`, `product_unit`, etc.). |
| **API 3** | `/api/qc/getmasterSync?Master_Name=StateRate` | `GET` | `Authorization: Bearer <token>` | Fetches retailer price matrix matching `Product_Detail_Code` to product `id`. |
| **API 4** | `/api/qc/SaveSampleIos` | `POST` | `Authorization: Bearer <token>` | Dispatches completed order with product line items, total metrics, and user remarks. |

---

## 🖥 How to Run on macOS / Xcode

1. Open `SanKart.xcodeproj` in **Xcode 15 or later**.
2. Select an iOS Simulator target (e.g. **iPhone 15 / 16 Pro**, iOS 16+).
3. Press **Cmd + R** to build and run the assessment application.

*Note: Since the backend API server uses HTTP (`http://sjapi.salesjump.in`), `Info.plist` includes App Transport Security exceptions (`NSAllowsArbitraryLoads`) to ensure smooth network communication.*

