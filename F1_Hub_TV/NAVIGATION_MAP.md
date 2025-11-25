# F1 Race Hub TV 2.0 - Complete Navigation Map

## App Structure Overview

```
SPLASH SCREEN (Auto-transition after 2s)
    ↓
CONTENT VIEW (Main Menu)
    ├─→ Race Weekend Hub Card → RACE OVERVIEW VIEW
    └─→ F1 Legends Archive Card → DRIVER GALLERY VIEW

RACE OVERVIEW VIEW
    ├─→ Driver Standings Button → DRIVER STANDINGS VIEW
    └─→ View Sessions Button → SESSION SCHEDULE VIEW

DRIVER STANDINGS VIEW
    ├─→ Home Button → CONTENT VIEW (Main Menu)
    └─→ Constructor Standing Button → CONSTRUCTOR STANDINGS VIEW

CONSTRUCTOR STANDINGS VIEW
    ├─→ Back Button → Previous Screen
    └─→ Driver Standing Button → DRIVER STANDINGS VIEW

DRIVER GALLERY VIEW
    └─→ Back Button → CONTENT VIEW (Main Menu)

SESSION SCHEDULE VIEW
    └─→ Back Button → RACE OVERVIEW VIEW

WEATHER FORECAST VIEW
    └─→ Sidebar Navigation Menu
```

## Detailed Screen Navigation

### 1. SplashView
- **No navigation buttons** (auto-transitions to ContentView)
- **Route**: Entry point

### 2. ContentView (Main Menu)
- **Race Weekend Hub** card → `router.push(.raceOverview)`
- **F1 Legends Archive** card → `router.push(.driverGallery)`
- **Routes Available**: All routes accessible from here

### 3. RaceOverviewView
- **Driver Standings** button → `router.push(.driverStandings)`
- **View Sessions** button → `router.push(.sessionSchedule)`
- **No back button** (navigate via route from main menu)

### 4. DriverStandingsView
- **Home Button** (blue circle icon) → `router.reset()` → ContentView
- **Constructor Standing** (red text button) → `router.push(.constructorStandings)`
- **ScrollView**: Yes, for driver list

### 5. ConstructorStandingsView
- **Back Button** (white circle with chevron) → `router.pop()`
- **Driver Standing** (blue text button) → `router.push(.driverStandings)`
- **Standalone view**: Can navigate between standings

### 6. DriverGalleryView
- **Back Button** → `router.pop()` → ContentView
- **Grid of F1 Legends**: Display only (no navigation)

### 7. SessionScheduleView
- **Back Button** → `router.pop()` → RaceOverviewView
- **Session Cards**: Display only (no individual navigation)

### 8. WeatherForecastView
- **Sidebar Navigation**: Multiple menu items
- **Full featured screen**: Weather data display

## Navigation Methods

1. **`router.push(.route)`** - Navigate forward to new screen
2. **`router.pop()`** - Go back to previous screen  
3. **`router.reset()`** - Clear stack, return to main menu

## Routes Definition

```swift
enum Route: Hashable {
    case sessionSchedule
    case raceOverview
    case driverStandings
    case constructorStandings
    case weatherForecast
    case driverGallery
}
```

## Complete Navigation Paths

### Path 1: Race Weekend Flow
ContentView → RaceOverviewView → DriverStandingsView → ConstructorStandingsView
(Can return to ContentView via Home button at any standings screen)

### Path 2: Session Schedule Flow  
ContentView → RaceOverviewView → SessionScheduleView → Back → RaceOverviewView

### Path 3: Legends Archive Flow
ContentView → DriverGalleryView → Back → ContentView

### Path 4: Circular Standings Navigation
DriverStandingsView ↔ ConstructorStandingsView
(Can switch between both standings screens freely)

## Button Types Used

1. **Enhanced Home Button** - Circular blue button with house icon
2. **Enhanced Back Button** - Circular white button with chevron
3. **Text Navigation Buttons** - Text with underline (Constructor/Driver Standing)
4. **Card Buttons** - Large image cards on main menu
5. **Action Buttons** - Rectangular buttons with custom styling

## Current Status

✅ All screens have navigation buttons
✅ All routes properly defined in Router
✅ All destinations mapped in App file
✅ Navigation flow is complete and circular
✅ Build succeeds without errors
