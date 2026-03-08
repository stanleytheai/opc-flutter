# OPC Feature Gap Analysis

**Original:** OPC-Client (Angular) → **Rebuild:** opc-flutter (Flutter)
**Date:** 2026-03-07

---

## Executive Summary

The Flutter rebuild covers the **core happy path** (search ticker → select options → view profit heatmap) with clean architecture, but is missing ~60% of the Angular app's features. The biggest gaps are: no Web Worker parallelism for calculations, no Firebase/Firestore integration, no PWA/service worker support, no settings system, no strategy detection, no canvas-based visualizer, and several UI polish features.

---

## 1. Feature Comparison by Area

### 1.1 Ticker Search & Selection

| Feature | Angular | Flutter | Status |
|---------|---------|---------|--------|
| Ticker search via Tradier `/lookup` | ✅ | ✅ | **Complete** |
| Ticker quote display (price, change, %) | ✅ | ✅ | **Complete** |
| Ticker overview page (dedicated route) | ✅ `TickerOverviewComponent` | ❌ Embedded in wizard | **Missing** (low priority) |
| Sparkline chart for ticker | ✅ `SparkLineComponent` | ❌ | **Missing** |
| Time sales data (`/timesales`) | ✅ `getTimeSales()` | ❌ | **Missing** |
| Options symbol lookup (`/options/lookup`) | ✅ `lookup()` | ❌ | **Missing** |

### 1.2 Option Chain & Selection

| Feature | Angular | Flutter | Status |
|---------|---------|---------|--------|
| Load expirations | ✅ | ✅ | **Complete** |
| Load option chain with greeks | ✅ | ✅ | **Complete** |
| Calls/Puts tab view | ✅ | ✅ | **Complete** |
| Option card with strike, bid, ask, IV, OI, delta | ✅ | ✅ | **Complete** |
| Buy / Sell toggle per option | ✅ Signal-based `count` (+/-) | ⚠️ Buy-only default; BuyOrSell stored but no sell UI toggle | **Partial** |
| Increment/decrement quantity | ✅ `buy()`, `sell()`, `add()`, `remove()` | ⚠️ Quantity stored but no +/- UI | **Partial** |
| Option details dialog (expanded view) | ✅ `OptionDetailsDialogComponent` | ❌ | **Missing** |
| Per-share vs per-contract display toggle | ✅ via SettingsService | ❌ | **Missing** |
| Number of strikes per expiration (configurable) | ✅ Setting: `numberOfStrikesPerExpiration` | ❌ Shows all | **Missing** |
| Strategy selection pane (Call/Put, Buy/Sell, Naked/Covered) | ✅ `StrategySelectionPaneComponent` | ❌ | **Missing** |
| Selected options list (draggable bottom sheet) | ✅ `SelectedList` with CDK drag | ⚠️ Bottom summary bar only | **Partial** |
| Net cost calculation | ✅ Signal-based `netCost` | ✅ Inline calculation | **Complete** |
| Multi-expiry support (options across different expiries) | ✅ `selectedOptionsByExpiration$` grouping | ⚠️ Can select, but only shortest expiry used for calculation | **Partial** |

### 1.3 Profit Calculation Engine

| Feature | Angular | Flutter | Status |
|---------|---------|---------|--------|
| Black-Scholes call premium | ✅ | ✅ | **Complete** — identical formula |
| Black-Scholes put premium | ✅ | ✅ | **Complete** — identical formula |
| NORMSDIST / erf approximation | ✅ | ✅ | **Complete** |
| Generate price range around underlying | ✅ `generateNearbyStrikeList()` — smart interval scaling | ✅ `generatePriceRange()` — fixed 25% range, 50 steps | **Complete** (simpler) |
| Generate date range to expiry | ✅ `getDatesUntilExpiration()` | ✅ `generateDateRange()` — caps at ~30 points | **Complete** |
| Web Worker pool for parallel computation | ✅ `observable-webworker` pool | ❌ Runs synchronously on main thread | **Missing** (perf concern for large grids) |
| Hypothetical option generation | ✅ `generateHypotheticalOptions()` | ✅ Inline in `ProfitCalculator.calculate()` | **Complete** (different structure) |
| At-expiration intrinsic value fallback | ❌ (uses BS even at T=0, may produce NaN) | ✅ Explicit intrinsic clamp | **Flutter is better** |
| Premium-to-profit conversion (buy/sell/covered/naked) | ✅ `premiumToProfit()` with 5 contract types | ⚠️ Buy and sell only | **Partial** — missing covered call/put |
| Interest rate | ✅ Hardcoded 5% | ✅ Hardcoded 4% | **Divergent** — minor |
| Dividend yield support | ✅ Hardcoded 0 | ✅ Hardcoded 0 | **Complete** |

### 1.4 Visualization

| Feature | Angular | Flutter | Status |
|---------|---------|---------|--------|
| Gradient heatmap table | ✅ `GradientTableComponent` — HTML table | ✅ `HeatmapGrid` — ListView | **Complete** |
| Canvas-based profit visualizer | ✅ `OptionProfitVisualizer` (full HTML5 Canvas rendering) | ❌ | **Missing** |
| Touch scroll on canvas | ✅ `TouchScroll` directive | ❌ | **Missing** |
| Color gradient mapping (red=loss, green=profit) | ✅ 510-color gradient map | ✅ `AppColors.profitColor()` | **Complete** |
| Points of interest overlay (current price line, breakeven) | ✅ Drawn on canvas | ⚠️ Breakeven row detection only | **Partial** |
| Cell tap → detail card | ✅ `tileClick()` emits data | ✅ `ProfitDetailCard` | **Complete** |
| Premium vs Profit toggle | ✅ `PremiumOrProfit` enum in visualizer settings | ❌ Profit only | **Missing** |
| Display as percent toggle | ✅ `showAsPercent` in gradient table | ❌ | **Missing** |
| Axes with formatted dates | ✅ Canvas-rendered axes | ✅ Column headers | **Complete** (simpler) |
| Loading progress indicator | ✅ `loadingProgress$`, `itemsToLoad` | ⚠️ Basic CircularProgressIndicator | **Partial** |

### 1.5 Strategy Detection

| Feature | Angular | Flutter | Status |
|---------|---------|---------|--------|
| Auto-detect strategy name from selected legs | ✅ `getOptionStrategy()` — 13 strategies | ❌ | **Missing** |
| Strategies: Long/Short Call/Put, Straddle, Strangle, Spreads, Butterfly, Iron Condor, Collar | ✅ | ❌ | **Missing** |
| Contract type enum (CallPurchase, CoveredCallSale, NakedCallSale, etc.) | ✅ 5 types | ❌ | **Missing** |

### 1.6 State Management

| Feature | Angular | Flutter | Status |
|---------|---------|---------|--------|
| Centralized state service | ✅ `AppStateService` with Signals | ✅ Riverpod providers | **Complete** (different paradigm) |
| URL query param persistence | ✅ `QueryParamManagerService` — ticker + selections in URL | ❌ | **Missing** |
| Session storage persistence | ✅ (commented out but structured) | ❌ | **Missing** |
| In-memory cache with TTL | ✅ `CacheService` (15-min TTL) | ✅ Simple Map cache in `MarketDataService` (no TTL) | **Partial** |

### 1.7 Backend / Infrastructure

| Feature | Angular | Flutter | Status |
|---------|---------|---------|--------|
| Firebase Functions (premium calc API) | ✅ Cloud Function endpoint | ❌ | **Missing** (not needed — Flutter does client-side calc) |
| Firestore CRUD service | ✅ `FirestoreDataService` | ❌ | **Missing** |
| Firestore rules | ✅ (open read/write) | ❌ | **Missing** |
| Service Worker / PWA | ✅ `AppUpdateService`, `ServiceWorkerManager` | ❌ | **Missing** |
| Firebase hosting config | ✅ `firebase.json` | ❌ | **Missing** |

### 1.8 UI/UX Polish

| Feature | Angular | Flutter | Status |
|---------|---------|---------|--------|
| Dark theme | ✅ | ✅ | **Complete** |
| Animated transitions | ✅ Angular animations | ✅ flutter_animate | **Complete** |
| Settings dialog (full screen) | ✅ `SettingsComponent` via MatDialog | ❌ | **Missing** |
| Notification toasts | ✅ `NotifyUI` service (snackbar) | ❌ | **Missing** |
| Loading overlay ("is busy") | ✅ `IsBusyService`, `IsBusyComponent` | ❌ | **Missing** |
| Material Design components | ✅ Angular Material | ✅ Flutter Material | **Complete** |
| Error handling service | ✅ `ErrorHandlerService` | ❌ | **Missing** |
| Debug decorator | ✅ `@debug()` decorator | ❌ | **Missing** |
| Wizard step navigation | ✅ Router-based with dedicated routes | ✅ `WizardScreen` with `PageView` | **Complete** |
| Strategy editor component | ✅ `StrategyEditorComponent` | ❌ | **Missing** |
| CORS proxy for web | ❌ (uses sandbox directly) | ✅ `corsproxy.io` for web builds | **Flutter is better** |

---

## 2. What Flutter Has That Angular Doesn't

1. **Cleaner at-expiration handling** — intrinsic value fallback instead of BS at T=0
2. **CORS proxy** for web builds built-in
3. **Riverpod** state management (more modern than RxJS + Signals hybrid)
4. **Cross-platform** potential (iOS, Android, web from single codebase)
5. **Simpler, more maintainable** profit calculator (single pass, no worker overhead)

---

## 3. Prioritized Gap List

### P0 — Core Functionality Gaps

| # | Gap | Effort | Impact |
|---|-----|--------|--------|
| 1 | **Buy/Sell UI toggle** — users can't sell options (short positions) | S | Critical — half of all strategies require selling |
| 2 | **Quantity increment/decrement UI** | S | Needed for multi-contract positions |
| 3 | **Covered call/put profit calculation** | M | Needed for accurate P&L on covered strategies |
| 4 | **Multi-expiry calculation support** | M | Currently only uses shortest expiry; calendar spreads broken |
| 5 | **Premium vs Profit display toggle** | S | Users need to see both views |

### P1 — Important Features

| # | Gap | Effort | Impact |
|---|-----|--------|--------|
| 6 | **Strategy auto-detection** | M | Shows users what strategy they've built (13 strategies) |
| 7 | **Display as percent toggle** | S | Essential for comparing different-priced options |
| 8 | **Cache TTL** — current cache never expires | S | Data freshness |
| 9 | **Settings screen** | M | Per-share display, strikes count, debug mode |
| 10 | **URL/deep link state persistence** | M | Shareable links, back-button support |

### P2 — Nice to Have

| # | Gap | Effort | Impact |
|---|-----|--------|--------|
| 11 | **Canvas-based visualizer** (alternative to heatmap table) | L | Original app's signature feature |
| 12 | **Web Worker / Isolate for calculations** | M | Performance for large grids |
| 13 | **Sparkline component** | S | Visual flair on ticker info |
| 14 | **Loading progress bar** (items calculated / total) | S | Better UX for heavy calculations |
| 15 | **Points of interest** (current price line, today line) | M | Helps users orient in the heatmap |
| 16 | **Error handling & toast notifications** | M | Better error UX |
| 17 | **Selected options list** (expandable bottom sheet) | M | Better review of positions |

### P3 — Infrastructure (only if deploying to web/production)

| # | Gap | Effort | Impact |
|---|-----|--------|--------|
| 18 | **Firebase hosting** | S | Deployment |
| 19 | **PWA / Service Worker** | M | Offline support, install prompt |
| 20 | **Firestore integration** | M | Persist user trades/watchlists |
| 21 | **Option details dialog** | S | Deep dive into individual contracts |
| 22 | **Time sales API integration** | S | Historical price data |

**Effort key:** S = Small (< 1 day), M = Medium (1-3 days), L = Large (3+ days)

---

## 4. Codebase Size Comparison

| Metric | Angular | Flutter |
|--------|---------|--------|
| Source files (non-test) | ~50 .ts files | ~30 .dart files |
| Total lines | ~7,500 | ~2,000 |
| Services | 14 | 3 |
| Components/Screens | 15+ | 3 screens + 8 widgets |
| Models | 1 large file (464 lines) | 4 files (~300 lines total) |

---

## 5. Architecture Notes

**Angular app** uses a hybrid of RxJS Observables and Angular Signals (recent migration). State flows through `AppStateService` → URL query params → services. Calculations are parallelized via Web Worker pool (`observable-webworker`). Complex but powerful.

**Flutter app** uses Riverpod with `FutureProvider`/`StateNotifierProvider`. Clean unidirectional data flow. Calculations run synchronously in `ProfitCalculator.calculate()`. Simpler and more maintainable, but may need Isolates for large option grids.

**Both apps** use the Tradier sandbox API with the same bearer token and identical Black-Scholes formulas (with minor interest rate differences: 5% Angular vs 4% Flutter).
