//
//  MapView.swift
//  TravelTalk
//
//  Created by Cascade on 2025-11-16.
//

import SwiftUI
import MapKit
import CoreLocation

private final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var authorization: CLAuthorizationStatus = .notDetermined
    @Published var lastCoordinate: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        authorization = manager.authorizationStatus
        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func requestPermission() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func requestSingleLocation() {
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            manager.startUpdatingLocation()
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        DispatchQueue.main.async { self.lastCoordinate = coord }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { self.lastCoordinate = nil }
    }
}

private enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case atm = "ATM"
        case hospital = "Hospital"
        case restaurant = "Restaurant"
        case university = "University"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .all: return "globe"
            case .atm: return "banknote"
            case .hospital: return "cross.case.fill"
            case .restaurant: return "fork.knife"
            case .university: return "graduationcap.fill"
            }
        }
        var pluralTitle: String {
            switch self {
            case .all: return "Places"
            case .atm: return "ATMs"
            case .hospital: return "Hospitals"
            case .restaurant: return "Restaurants"
            case .university: return "Universities"
            }
        }
    }
    
private struct Place: Identifiable {
        let id = UUID()
        let title: String
        let coordinate: CLLocationCoordinate2D
        let distance: String
        let rating: String
        let placeId: String?            // Apple Place ID when available
        let alternateIds: [String]      // Apple alternate Place IDs
    }
    
struct MapView: View {
        private static let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
            span: MKCoordinateSpan(latitudeDelta: 5.5, longitudeDelta: 5.5)
        )
        @StateObject private var locationManager = LocationManager()
        @State private var query: String = ""
        @State private var selectedFilter: Filter = .atm
        @State private var region: MKCoordinateRegion = MapView.initialRegion
        @State private var cameraPosition: MapCameraPosition = .region(MapView.initialRegion)
        @State private var places: [Place] = []
        @State private var selectedCoordinate: CLLocationCoordinate2D?
        @State private var locality: String = "Sri Lanka"
        @State private var followUser: Bool = false
        @State private var sheetExpanded: Bool = false
        @State private var dragOffset: CGFloat = 0
        @State private var lastSearchCenter: CLLocationCoordinate2D?
        @State private var lastSearchTime: Date?
        @State private var route: MKRoute? = nil
        @State private var showRouteInputs: Bool = false
        private enum TransportMode { case driving, walking, transit }
        @State private var transportMode: TransportMode = .driving
        @State private var startText: String = ""
        @State private var endText: String = ""
        @State private var startCoordinate: CLLocationCoordinate2D? = nil
        @State private var endCoordinate: CLLocationCoordinate2D? = nil
        @State private var toast: String? = nil
        // Suggestions
        @State private var normalSuggestions: [MKLocalSearchCompletion] = []
        @State private var startSuggestions: [MKLocalSearchCompletion] = []
        @State private var endSuggestions: [MKLocalSearchCompletion] = []
        private let normalCompleter = MKLocalSearchCompleter()
        private let startCompleter = MKLocalSearchCompleter()
        private let endCompleter = MKLocalSearchCompleter()
        @State private var normalCompleterDelegate: MKLocalSearchCompleterDelegateProxy? = nil
        @State private var startCompleterDelegate: MKLocalSearchCompleterDelegateProxy? = nil
        @State private var endCompleterDelegate: MKLocalSearchCompleterDelegateProxy? = nil
        private enum RouteField { case start, end }
        @FocusState private var focusedField: RouteField?
        // Whether any suggestion list is currently visible (for tap-to-dismiss overlay)
        private var areSuggestionsVisible: Bool {
            let hasNormal = (!showRouteInputs && !query.trimmingCharacters(in: .whitespaces).isEmpty && !normalSuggestions.isEmpty)
            let hasRouteStart = (showRouteInputs && focusedField == .start && !startSuggestions.isEmpty)
            let hasRouteEnd = (showRouteInputs && focusedField == .end && !endSuggestions.isEmpty)
            return hasNormal || hasRouteStart || hasRouteEnd
        }
        // Google Places (optional)
        private var googleAPIKey: String? { Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String }
        
        var body: some View {
            ZStack(alignment: .bottom) {
                mapLayer
                    .ignoresSafeArea()

                // Tap-outside-to-dismiss suggestions overlay (must be below suggestions UI)
                if areSuggestionsVisible {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            normalSuggestions = []
                            startSuggestions = []
                            endSuggestions = []
                            focusedField = nil
                        }
                }

                VStack(spacing: 12) {
                    header
                    if showRouteInputs {
                        routeFields
                        routeModeChips
                        routeSuggestionsList
                    } else {
                        searchField
                        normalSuggestionsList
                    }
                    if let r = route { routeSummary(r) }
                    filterChips
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .top)
                
                rightControls
                    .padding(.trailing, 12)
                    .padding(.bottom, sheetExpanded ? 340 : 240)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                
                bottomSheet
                if let msg = toast {
                    VStack { Spacer()
                        Text(msg)
                            .foregroundColor(.white)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.75), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                            .padding(.bottom, 28)
                    }
                    .transition(.opacity)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                locationManager.requestPermission()
                performNearbySearch()
                reverseGeocode(center: region.center)
                cameraPosition = .region(region)
                // Setup completers
                normalCompleter.resultTypes = .address
                startCompleter.resultTypes = .address
                endCompleter.resultTypes = .address
                normalCompleter.region = region
                startCompleter.region = region
                endCompleter.region = region
                normalCompleterDelegate = MKLocalSearchCompleterDelegateProxy(onUpdate: { comps in self.normalSuggestions = comps })
                startCompleterDelegate = MKLocalSearchCompleterDelegateProxy(onUpdate: { comps in self.startSuggestions = comps })
                endCompleterDelegate = MKLocalSearchCompleterDelegateProxy(onUpdate: { comps in self.endSuggestions = comps })
                normalCompleter.delegate = normalCompleterDelegate
                startCompleter.delegate = startCompleterDelegate
                endCompleter.delegate = endCompleterDelegate
            }
            .onChange(of: selectedFilter) { _, _ in performNearbySearch() }
            .onChange(of: region.center.latitude) { _, _ in
                debouncedSearchOnRegionChange()
                normalCompleter.region = region
                startCompleter.region = region
                endCompleter.region = region
            }
            .onChange(of: region.center.longitude) { _, _ in
                debouncedSearchOnRegionChange()
                normalCompleter.region = region
                startCompleter.region = region
                endCompleter.region = region
            }
            .onReceive(locationManager.$lastCoordinate.compactMap { $0 }) { c in
                guard followUser else { return }
                applyRegionChange(center: c, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02), animated: true)
                reverseGeocode(center: c)
                performNearbySearch()
            }
        }
        
        // MARK: - Map
        @ViewBuilder
        private var mapLayer: some View {
            if #available(iOS 17.0, *) {
                Map(position: $cameraPosition) {
                    // User pulsing indicator
                    if let user = locationManager.lastCoordinate {
                        Annotation("", coordinate: user) {
                            ZStack {
                                Circle()
                                    .stroke(Color.blue.opacity(0.35), lineWidth: 3)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .blue.opacity(0.6), radius: 6)
                                Circle().fill(Color.white).frame(width: 14, height: 14)
                                Circle().fill(Color.blue).frame(width: 10, height: 10)
                            }
                        }
                    }
                    
                    // Selected target glow
                    if let target = selectedCoordinate {
                        Annotation("", coordinate: target) {
                            ZStack {
                                Circle().fill(self.colorForCurrentFilter().opacity(0.25)).frame(width: 44, height: 44).blur(radius: 8)
                                Circle().fill(self.colorForCurrentFilter()).frame(width: 16, height: 16)
                            }
                        }
                    }
                    
                    // POI markers
                    ForEach(places) { place in
                        Annotation("", coordinate: place.coordinate) {
                            Circle()
                                .fill(self.colorForCurrentFilter())
                                .frame(width: 10, height: 10)
                                .shadow(color: self.colorForCurrentFilter().opacity(0.5), radius: 6)
                                .onTapGesture {
                                    withAnimation { selectedCoordinate = place.coordinate }
                                    performNearbySearch(center: place.coordinate)
                                }
                        }
                    }

                    // Route polyline
                    if let r = route {
                        MapPolyline(r.polyline)
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .gesture(
                    DragGesture().onChanged { _ in if followUser { followUser = false } }
                )
            } else {
                if let r = route {
                    LegacyRouteMap(region: $region, route: r, user: locationManager.lastCoordinate, destination: selectedCoordinate)
                        .ignoresSafeArea()
                } else {
                    Map(coordinateRegion: $region, annotationItems: places) { place in
                        MapAnnotation(coordinate: place.coordinate) {
                            Circle()
                                .fill(self.colorForCurrentFilter())
                                .frame(width: 10, height: 10)
                                .shadow(color: self.colorForCurrentFilter().opacity(0.5), radius: 6)
                                .onTapGesture {
                                    withAnimation { selectedCoordinate = place.coordinate }
                                    performNearbySearch(center: place.coordinate)
                                }
                        }
                    }
                    .gesture(
                        DragGesture().onChanged { _ in if followUser { followUser = false } }
                    )
                }
            }
        }
        
        // MARK: - Overlays
        private var header: some View {
            HStack(spacing: 12) {
                if showRouteInputs {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showRouteInputs = false
                            focusedField = nil
                            startSuggestions = []
                            endSuggestions = []
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Find Nearby in Sri Lanka")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                    Text(locality)
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 13))
                }
                Spacer()
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
        }
        
        private var searchField: some View {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.8))
                TextField("Search places in Sri Lanka", text: $query)
                    .foregroundColor(.white)
                    .submitLabel(.search)
                    .onSubmit { performSearch() }
                    .onChange(of: query) { _, newVal in
                        normalCompleter.queryFragment = newVal
                    }
                Spacer(minLength: 8)
                Button(action: {
                    withAnimation { showRouteInputs = true }
                    if let c = locationManager.lastCoordinate {
                        startCoordinate = c
                        startText = "Current Location"
                    }
                }) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Plan route between two locations")
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Color.black.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }

        // Suggestions for normal search
        @ViewBuilder
        private var normalSuggestionsList: some View {
            if !showRouteInputs && !query.trimmingCharacters(in: .whitespaces).isEmpty && !normalSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(normalSuggestions.prefix(6).enumerated()), id: \.offset) { _, item in
                        Button(action: { selectNormalCompletion(item) }) {
                            HStack { Text(item.title).foregroundColor(.white).font(.system(size: 14, weight: .semibold)); Spacer() }
                            HStack { Text(item.subtitle).foregroundColor(.white.opacity(0.85)).font(.system(size: 12)); Spacer() }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .buttonStyle(.plain)
                        if item != normalSuggestions.prefix(6).last { Divider().background(Color.white.opacity(0.1)) }
                    }
                }
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
        }
        
        private var filterChips: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Filter.allCases) { f in
                        chip(for: f)
                    }
                }
            }
        }

        private var routeFields: some View {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill").foregroundColor(.white.opacity(0.9))
                    TextField("Start location (address or place)", text: $startText)
                        .foregroundColor(.white)
                        .submitLabel(.next)
                        .onSubmit { if !endText.isEmpty { resolveAndRoute() } }
                        .onChange(of: startText) { _, newVal in startCompleter.queryFragment = newVal }
                        .focused($focusedField, equals: .start)
                    Button(action: {
                        if let c = locationManager.lastCoordinate {
                            startCoordinate = c
                            startText = "Current Location"
                        } else {
                            locationManager.requestSingleLocation()
                        }
                    }) {
                        Image(systemName: "dot.circle.and.hand.point.up.left.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))

                HStack(spacing: 8) {
                    Image(systemName: "flag.checkered").foregroundColor(.white.opacity(0.9))
                    TextField("End location (address or place)", text: $endText)
                        .foregroundColor(.white)
                        .submitLabel(.go)
                        .onSubmit { resolveAndRoute() }
                        .onChange(of: endText) { _, newVal in endCompleter.queryFragment = newVal }
                        .focused($focusedField, equals: .end)
                    Button(action: resolveAndRoute) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }

        // Suggestions for route fields
        @ViewBuilder
        private var routeSuggestionsList: some View {
            if showRouteInputs {
                let items: [MKLocalSearchCompletion] = (focusedField == .start) ? startSuggestions : endSuggestions
                let text = (focusedField == .start) ? startText : endText
                if !text.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(items.prefix(6).enumerated()), id: \.offset) { _, item in
                            Button(action: {
                                selectRouteCompletion(item, for: focusedField ?? .end)
                            }) {
                                HStack { Text(item.title).foregroundColor(.white).font(.system(size: 14, weight: .semibold)); Spacer() }
                                HStack { Text(item.subtitle).foregroundColor(.white.opacity(0.85)).font(.system(size: 12)); Spacer() }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .buttonStyle(.plain)
                            if item != items.prefix(6).last { Divider().background(Color.white.opacity(0.1)) }
                        }
                    }
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
            }
        }

        @ViewBuilder
        private var routeModeChips: some View {
            HStack(spacing: 8) {
                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { transportMode = .driving } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                        Text("Vehicle")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(transportMode == .driving ? Color.blue : Color.black.opacity(0.45))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { transportMode = .walking } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk")
                        Text("Walk")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(transportMode == .walking ? Color.blue : Color.black.opacity(0.45))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { transportMode = .transit } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "tram.fill")
                        Text("Transit")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(transportMode == .transit ? Color.blue : Color.black.opacity(0.45))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        
        private func chip(for filter: Filter) -> some View {
            let isSelected = selectedFilter == filter
            return HStack(spacing: 8) {
                Image(systemName: filter.icon)
                Text(filter.rawValue)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isSelected ? .white : .white.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.black.opacity(0.45))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
            .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = filter } }
        }
        
        private var rightControls: some View {
            VStack(spacing: 10) {
                RoundButton(system: followUser ? "location.fill" : "location") { toggleFollow() }
                RoundButton(system: "plus") { zoomIn() }
                RoundButton(system: "minus") { zoomOut() }
                if route != nil { RoundButton(system: "xmark") { withAnimation { route = nil; showRouteInputs = false } } }
            }
        }
        
        private var bottomSheet: some View {
            GeometryReader { geo in
                let collapsed: CGFloat = 200
                let expanded: CGFloat = min(geo.size.height * 0.62, 520)
                let height = sheetExpanded ? expanded : collapsed
                
                VStack(alignment: .leading, spacing: 14) {
                    Capsule().fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .frame(maxWidth: .infinity)
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(selectedFilter.pluralTitle) in \(locality)")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                        Button("See All") { withAnimation { sheetExpanded = true } }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.blue)
                    }
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(places) { place in
                                placeRow(place)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .frame(height: height + dragOffset)
                .background(Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.22), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.35), radius: 28, x: 0, y: 12)
                .padding(.horizontal, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .gesture(
                    DragGesture()
                        .onChanged { v in dragOffset = max(-40, min(40, -v.translation.height)) }
                        .onEnded { v in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                if v.translation.height < -60 { sheetExpanded = true }
                                else if v.translation.height > 60 { sheetExpanded = false }
                                dragOffset = 0
                            }
                        }
                )
            }
        }
        
        private func placeRow(_ place: Place) -> some View {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15)).frame(width: 46, height: 46)
                    Image(systemName: selectedFilter.icon).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.title).foregroundColor(.white).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                    Text(place.distance).foregroundColor(.white.opacity(0.85)).font(.system(size: 13))
                }
                Spacer()
                if !place.rating.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text(place.rating).foregroundColor(.white).font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.20), in: Capsule())
                }
                Button(action: {
                    // Reveal input fields and prefill destination
                    withAnimation { showRouteInputs = true }
                    endCoordinate = place.coordinate
                    endText = place.title
                    if let startC = (startCoordinate ?? locationManager.lastCoordinate) {
                        // Auto-route when start is known
                        buildRoute(from: startC, to: place.coordinate)
                    }
                }) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(6)
                        .background(Color.white.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture {
                selectedCoordinate = place.coordinate
                applyRegionChange(center: place.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03), animated: true)
                performNearbySearch(center: place.coordinate)
            }
        }
        
        // MARK: - Actions & Helpers
        private func zoomIn() {
            let newLat = max(region.span.latitudeDelta * 0.7, 0.005)
            let newLon = max(region.span.longitudeDelta * 0.7, 0.005)
            applyRegionChange(center: region.center, span: MKCoordinateSpan(latitudeDelta: newLat, longitudeDelta: newLon), animated: true)
        }
        private func zoomOut() {
            let newLat = min(region.span.latitudeDelta / 0.7, 20.0)
            let newLon = min(region.span.longitudeDelta / 0.7, 20.0)
            applyRegionChange(center: region.center, span: MKCoordinateSpan(latitudeDelta: newLat, longitudeDelta: newLon), animated: true)
        }
        private func toggleFollow() {
            followUser.toggle()
            if followUser {
                if let c = locationManager.lastCoordinate {
                    applyRegionChange(center: c, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02), animated: true)
                } else {
                    locationManager.requestSingleLocation()
                }
            }
        }
        
        private func performSearch() {
            let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            // Prefer a completion result when present
            if let comp = normalSuggestions.first { selectNormalCompletion(comp); return }

            searchLocation(text) { item in
                guard let item else { return }
                let c = item.placemark.coordinate
                DispatchQueue.main.async {
                    applyRegionChange(center: c, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03), animated: true)
                    selectedCoordinate = c
                    reverseGeocode(center: c)
                    performNearbySearch()
                }
            }
        }

        private func selectNormalCompletion(_ comp: MKLocalSearchCompletion) {
            let req = MKLocalSearch.Request(completion: comp)
            MKLocalSearch(request: req).start { resp, _ in
                if let item = resp?.mapItems.first {
                    let c = item.placemark.coordinate
                    DispatchQueue.main.async {
                        query = comp.title
                        // Hide suggestions after selection
                        normalSuggestions = []
                        applyRegionChange(center: c, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03), animated: true)
                        selectedCoordinate = c
                        reverseGeocode(center: c)
                        performNearbySearch()
                    }
                } else {
                    // Fallback to textual search strategies
                    searchLocation(comp.title) { item in
                        guard let item else { return }
                        let c = item.placemark.coordinate
                        DispatchQueue.main.async {
                            query = comp.title
                            // Hide suggestions after selection
                            normalSuggestions = []
                            applyRegionChange(center: c, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03), animated: true)
                            selectedCoordinate = c
                            reverseGeocode(center: c)
                            performNearbySearch()
                        }
                    }
                }
            }
        }

        private func selectRouteCompletion(_ comp: MKLocalSearchCompletion, for field: RouteField) {
            let req = MKLocalSearch.Request(completion: comp)
            MKLocalSearch(request: req).start { resp, _ in
                guard let item = resp?.mapItems.first else { return }
                let c = item.placemark.coordinate
                DispatchQueue.main.async {
                    switch field {
                    case .start:
                        startText = comp.title
                        startCoordinate = c
                        // Hide suggestions after selection
                        startSuggestions = []
                        focusedField = .end
                    case .end:
                        endText = comp.title
                        endCoordinate = c
                        // Hide suggestions after selection
                        endSuggestions = []
                        focusedField = nil
                    }
                    if let s = startCoordinate, let e = endCoordinate {
                        buildRoute(from: s, to: e)
                    }
                }
            }
        }

        
        
        private func performNearbySearch() {
            performNearbySearch(center: region.center)
        }
        
        private func performNearbySearch(center: CLLocationCoordinate2D) {
            // Build a clamped query region around the center to avoid very distant results
            let radiusMeters = estimatedRadiusMeters(from: region)
            let metersPerDegreeLat: CLLocationDistance = 111_000
            let latDelta = max(0.002, min(0.6, (radiusMeters / metersPerDegreeLat) * 2.0))
            let lonDelta = max(0.002, min(0.6, (radiusMeters / (metersPerDegreeLat * cos(center.latitude * .pi / 180))) * 2.0))
            let targetRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))

            // If Google Places API key is available, prefer it for POI accuracy
            if let apiKey = googleAPIKey, !apiKey.isEmpty {
                performGooglePlacesSearch(center: center, radiusMeters: radiusMeters, apiKey: apiKey)
                return
            }

            // Multi-query for ATMs and Universities, single query for others
            if selectedFilter == .all {
                let queries = [
                    "Restaurant",
                    "Hotel",
                    "Tourist attraction",
                    "Fuel",
                    "Hospital",
                    "Pharmacy",
                    "Supermarket",
                    "ATM",
                    "Bus station",
                    "Train station"
                ]
                let group = DispatchGroup()
                var collected: [MKMapItem] = []
                for q in queries {
                    group.enter()
                    let req = MKLocalSearch.Request()
                    req.region = targetRegion
                    req.naturalLanguageQuery = q
                    MKLocalSearch(request: req).start { resp, _ in
                        if let items = resp?.mapItems { collected.append(contentsOf: items) }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    var seen = Set<String>()
                    let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
                    let filtered = collected.filter { mi in
                        let c = mi.placemark.coordinate
                        let d = centerLoc.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
                        return d <= radiusMeters * 1.2 // small slack
                    }
                    let mapped = filtered.compactMap { (mi) -> Place? in
                        let c = mi.placemark.coordinate
                        let key = String(format: "%.5f,%.5f", c.latitude, c.longitude)
                        guard !seen.contains(key) else { return nil }
                        seen.insert(key)
                        return Place(
                            title: mi.name ?? "Place",
                            coordinate: c,
                            distance: distanceString(to: c),
                            rating: "",
                            placeId: mi.identifier?.rawValue,
                            alternateIds: mi.alternateIdentifiers.map { $0.rawValue }
                        )
                    }
                    .prefix(120)
                    .reduce(into: [Place]()) { arr, p in arr.append(p) }
                    self.places = mapped
                }
            } else if selectedFilter == .atm {
                let queries = [
                    "ATM",
                    "BOC ATM",
                    "HNB ATM",
                    "Sampath Bank ATM",
                    "Commercial Bank ATM",
                    "Peoples Bank ATM",
                    "Seylan ATM",
                    "Nations Trust ATM"
                ]
                let group = DispatchGroup()
                var collected: [MKMapItem] = []
                for q in queries {
                    group.enter()
                    let req = MKLocalSearch.Request()
                    req.region = targetRegion
                    req.naturalLanguageQuery = q
                    MKLocalSearch(request: req).start { resp, _ in
                        if let items = resp?.mapItems { collected.append(contentsOf: items) }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    var seen = Set<String>()
                    let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
                    let filtered = collected.filter { mi in
                        let c = mi.placemark.coordinate
                        let d = centerLoc.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
                        return d <= radiusMeters * 1.2
                    }
                    let mapped = filtered.compactMap { mi in
                        let c = mi.placemark.coordinate
                        let key = String(format: "%.5f,%.5f", c.latitude, c.longitude)
                        guard !seen.contains(key) else { return nil }
                        seen.insert(key)
                        return Place(
                            title: mi.name ?? selectedFilter.rawValue,
                            coordinate: c,
                            distance: distanceString(to: c),
                            rating: "",
                            placeId: mi.identifier?.rawValue,
                            alternateIds: mi.alternateIdentifiers.map { $0.rawValue }
                        )
                    }
                    .prefix(60)
                    .reduce(into: [Place]()) { arr, p in arr.append(p) }
                    self.places = mapped
                }
            } else if selectedFilter == .university {
                let queries = [
                    "SLIIT",
                    "NSBM Green University",
                    "IIT Sri Lanka",
                    "CINEC Campus",
                    "NIBM",
                    "Horizon Campus",
                    "APIIT",
                    "ICBT Campus",
                    "ACBT",
                    "ESOFT Metro Campus",
                    "BCAS Campus",
                    "Saegis Campus",
                    "Royal Institute of Colombo",
                    "University",
                    "Private University",
                    "Institute"
                ]
                let group = DispatchGroup()
                var collected: [MKMapItem] = []
                for q in queries {
                    group.enter()
                    let req = MKLocalSearch.Request()
                    req.region = targetRegion
                    req.naturalLanguageQuery = q
                    MKLocalSearch(request: req).start { resp, _ in
                        if let items = resp?.mapItems { collected.append(contentsOf: items) }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    var seen = Set<String>()
                    let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
                    let filtered = collected.filter { mi in
                        let c = mi.placemark.coordinate
                        let d = centerLoc.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
                        return d <= radiusMeters * 1.2
                    }
                    let mapped = filtered.compactMap { (mi) -> Place? in
                        let c = mi.placemark.coordinate
                        let key = String(format: "%.5f,%.5f", c.latitude, c.longitude)
                        guard !seen.contains(key) else { return nil }
                        seen.insert(key)
                        return Place(
                            title: mi.name ?? selectedFilter.rawValue,
                            coordinate: c,
                            distance: distanceString(to: c),
                            rating: "",
                            placeId: mi.identifier?.rawValue,
                            alternateIds: mi.alternateIdentifiers.map { $0.rawValue }
                        )
                    }
                    .prefix(80)
                    .reduce(into: [Place]()) { arr, p in arr.append(p) }
                    self.places = mapped
                }
            } else {
                let req = MKLocalSearch.Request()
                req.region = targetRegion
                req.naturalLanguageQuery = selectedFilter.rawValue
                MKLocalSearch(request: req).start { resp, _ in
                    guard let items = resp?.mapItems else { return }
                    let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
                    let filtered = items.filter { mi in
                        let c = mi.placemark.coordinate
                        let d = centerLoc.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
                        return d <= radiusMeters * 1.2
                    }
                    let mapped: [Place] = filtered.prefix(30).map { mi in
                        let c = mi.placemark.coordinate
                        return Place(
                            title: mi.name ?? selectedFilter.rawValue,
                            coordinate: c,
                            distance: distanceString(to: c),
                            rating: "",
                            placeId: mi.identifier?.rawValue,
                            alternateIds: mi.alternateIdentifiers.map { $0.rawValue }
                        )
                    }
                    DispatchQueue.main.async { self.places = mapped }
                }
            }
        }

        
        
        private func debouncedSearchOnRegionChange() {
            let now = Date()
            let center = region.center
            let minTime: TimeInterval = 0.8
            let minMeters: CLLocationDistance = 300
            defer { lastSearchCenter = center; lastSearchTime = now }
            guard let prevCenter = lastSearchCenter, let prevTime = lastSearchTime else { return }
            let a = CLLocation(latitude: prevCenter.latitude, longitude: prevCenter.longitude)
            let b = CLLocation(latitude: center.latitude, longitude: center.longitude)
            if now.timeIntervalSince(prevTime) > minTime && a.distance(from: b) > minMeters {
                performNearbySearch()
                reverseGeocode(center: center)
            }
        }
        
        private func reverseGeocode(center: CLLocationCoordinate2D) {
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: center.latitude, longitude: center.longitude)) { pm, _ in
                let name = pm?.first?.locality ?? pm?.first?.subLocality ?? pm?.first?.administrativeArea
                if let name, !name.isEmpty { DispatchQueue.main.async { self.locality = name } }
            }
        }
        
        private func colorForCurrentFilter() -> Color {
            switch selectedFilter {
            case .all: return Color.blue
            case .restaurant: return Color(red: 59/255.0, green: 130/255.0, blue: 246/255.0)
            case .hospital: return Color(red: 239/255.0, green: 68/255.0, blue: 68/255.0)
            case .atm: return Color(red: 16/255.0, green: 185/255.0, blue: 129/255.0)
            case .university: return Color(red: 147/255.0, green: 51/255.0, blue: 234/255.0)
            }
        }
        
        private func categoriesForFilter(_ filter: Filter) -> Set<MKPointOfInterestCategory> {
            switch filter {
            case .all:
                return [
                    .restaurant,
                    .hotel,
                    .museum,
                    .gasStation,
                    .hospital,
                    .pharmacy,
                    .foodMarket,
                    .atm,
                    .park,
                    .university
                ]
            case .restaurant: return [.restaurant]
            case .hospital: return [.hospital]
            case .atm: return [.atm]
            case .university: return [.university]
            }
        }
        
        private func estimatedRadiusMeters(from region: MKCoordinateRegion) -> CLLocationDistance {
            let metersPerDegreeLat: CLLocationDistance = 111_000
            return max(500, min(20_000, (region.span.latitudeDelta * metersPerDegreeLat) / 2.0))
        }

        // MARK: - Google Places integration (optional)
        private func performGooglePlacesSearch(center: CLLocationCoordinate2D, radiusMeters: CLLocationDistance, apiKey: String) {
            // Clamp radius to Google limits (max 50,000)
            let radius = Int(min(max(radiusMeters, 200), 50000))
            let base = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

            struct Query {
                let keyword: String?
                let type: String?
            }
            let queries: [Query]
            switch selectedFilter {
            case .all:
                queries = [
                    Query(keyword: nil, type: "restaurant"),
                    Query(keyword: nil, type: "cafe"),
                    Query(keyword: nil, type: "tourist_attraction"),
                    Query(keyword: nil, type: "gas_station"),
                    Query(keyword: nil, type: "hospital"),
                    Query(keyword: nil, type: "pharmacy"),
                    Query(keyword: nil, type: "supermarket"),
                    Query(keyword: nil, type: "atm"),
                    Query(keyword: nil, type: "bus_station"),
                    Query(keyword: nil, type: "train_station")
                ]
            case .atm:
                queries = [Query(keyword: nil, type: "atm")]
            case .hospital:
                queries = [Query(keyword: nil, type: "hospital")]
            case .restaurant:
                queries = [Query(keyword: nil, type: "restaurant")]
            case .university:
                queries = [
                    Query(keyword: nil, type: "university"),
                    Query(keyword: "private", type: "university"),
                    Query(keyword: "campus", type: "university")
                ]
            }

            let group = DispatchGroup()
            var collected: [[String: Any]] = []
            for q in queries {
                group.enter()
                var comps = URLComponents(string: base)!
                var items: [URLQueryItem] = [
                    URLQueryItem(name: "location", value: "\(center.latitude),\(center.longitude)"),
                    URLQueryItem(name: "radius", value: String(radius)),
                    URLQueryItem(name: "key", value: apiKey)
                ]
                if let type = q.type { items.append(URLQueryItem(name: "type", value: type)) }
                if let kw = q.keyword { items.append(URLQueryItem(name: "keyword", value: kw)) }
                comps.queryItems = items
                guard let url = comps.url else { group.leave(); continue }
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    defer { group.leave() }
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let results = json["results"] as? [[String: Any]] else { return }
                    collected.append(contentsOf: results)
                }.resume()
            }
            group.notify(queue: .main) {
                var seen = Set<String>()
                let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
                let mapped = collected.compactMap { (dict) -> Place? in
                    guard
                        let geometry = dict["geometry"] as? [String: Any],
                        let loc = geometry["location"] as? [String: Any],
                        let lat = loc["lat"] as? CLLocationDegrees,
                        let lng = loc["lng"] as? CLLocationDegrees
                    else { return nil }
                    let name = (dict["name"] as? String) ?? selectedFilter.rawValue
                    let ratingStr: String = {
                        if let rating = dict["rating"] as? Double { return String(format: "%.1f", rating) }
                        return ""
                    }()
                    let c = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    let d = centerLoc.distance(from: CLLocation(latitude: lat, longitude: lng))
                    guard d <= Double(radius) * 1.2 else { return nil }
                    let key = String(format: "%.5f,%.5f", lat, lng)
                    guard !seen.contains(key) else { return nil }
                    seen.insert(key)
                    return Place(
                        title: name,
                        coordinate: c,
                        distance: distanceString(to: c),
                        rating: ratingStr,
                        placeId: nil,
                        alternateIds: []
                    )
                }
                let limit = (self.selectedFilter == .all ? 120 : (self.selectedFilter == .atm ? 60 : 30))
                self.places = Array(mapped.prefix(limit))
            }
        }
        
        private func applyRegionChange(center: CLLocationCoordinate2D, span: MKCoordinateSpan, animated: Bool) {
            let apply = {
                region.center = center
                region.span = span
                if #available(iOS 17.0, *) {
                    cameraPosition = .region(region)
                }
            }
            if animated { withAnimation(.easeInOut(duration: 0.25)) { apply() } } else { apply() }
        }
        
        private func distanceString(to coord: CLLocationCoordinate2D) -> String {
            let ref = locationManager.lastCoordinate ?? region.center
            let d = CLLocation(latitude: ref.latitude, longitude: ref.longitude).distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
            return d >= 1000 ? String(format: "%.1f km", d/1000) : String(format: "%.0f m", d)
        }

        private func geocode(_ text: String, near region: MKCoordinateRegion, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { completion(nil); return }
            if trimmed.lowercased() == "current location" || trimmed.lowercased() == "my location" {
                completion(locationManager.lastCoordinate ?? self.region.center)
                return
            }
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = trimmed
            req.region = region
            MKLocalSearch(request: req).start { resp, _ in
                if let c = resp?.mapItems.first?.placemark.coordinate {
                    completion(c)
                } else {
                    // Fallback: try without a region constraint (global search)
                    let req2 = MKLocalSearch.Request()
                    req2.naturalLanguageQuery = trimmed
                    MKLocalSearch(request: req2).start { resp2, _ in
                        if let c2 = resp2?.mapItems.first?.placemark.coordinate {
                            completion(c2)
                        } else {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.2)) { toast = "Couldn't find \(trimmed)" }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { withAnimation(.easeOut(duration: 0.2)) { toast = nil } }
                            }
                            completion(nil)
                        }
                    }
                }
            }
        }

        // MARK: - Textual search fallbacks
        private func searchLocation(_ text: String, completion: @escaping (MKMapItem?) -> Void) {
            let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { completion(nil); return }
            let terms = [
                t,
                "\(t), Sri Lanka",
                "\(t), Western Province, Sri Lanka",
                "\(t) bus stand Sri Lanka"
            ]
            searchNext(terms: terms) { item in
                if let item { completion(item); return }
                searchOSM(t) { coord in
                    if let c = coord {
                        completion(MKMapItem(placemark: MKPlacemark(coordinate: c)))
                    } else {
                        CLGeocoder().geocodeAddressString(t) { pms, _ in
                            if let loc = pms?.first?.location {
                                completion(MKMapItem(placemark: MKPlacemark(coordinate: loc.coordinate)))
                            } else {
                                completion(nil)
                            }
                        }
                    }
                }
            }
        }

        private func searchNext(terms: [String], completion: @escaping (MKMapItem?) -> Void) {
            var remaining = terms
            guard let term = remaining.first else { completion(nil); return }
            remaining.removeFirst()
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = term
            req.region = region
            MKLocalSearch(request: req).start { resp, _ in
                if let item = resp?.mapItems.first {
                    completion(item)
                } else {
                    searchNext(terms: remaining, completion: completion)
                }
            }
        }

        private struct OSMPlace: Codable { let lat: String; let lon: String; let display_name: String }

        private func searchOSM(_ query: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://nominatim.openstreetmap.org/search?q=\(encoded)&format=json&limit=1"
            guard let url = URL(string: urlString) else { completion(nil); return }
            var request = URLRequest(url: url)
            request.setValue("TravelTalk/1.0 (support@traveltalk.local)", forHTTPHeaderField: "User-Agent")
            URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data,
                      let places = try? JSONDecoder().decode([OSMPlace].self, from: data),
                      let first = places.first,
                      let lat = Double(first.lat),
                      let lon = Double(first.lon) else {
                    completion(nil)
                    return
                }
                completion(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }.resume()
        }

        private func resolveAndRoute() {
            // Prefer already selected coordinates if present
            let startR = startCoordinate
            let endR = endCoordinate
            let currentRegion = region
            if let s = startR, let e = endR {
                buildRoute(from: s, to: e)
                return
            }
            // Resolve both texts; chain searches to keep it simple
            let endTrim = endText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !endTrim.isEmpty else {
                withAnimation(.easeInOut(duration: 0.2)) { toast = "Enter an end location" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.easeOut(duration: 0.2)) { toast = nil } }
                return
            }
            geocode(startText.isEmpty ? "Current Location" : startText, near: currentRegion) { sCoord in
                let s = sCoord ?? self.locationManager.lastCoordinate ?? currentRegion.center
                geocode(endTrim, near: currentRegion) { eCoord in
                    guard let e = eCoord else { return }
                    // Persist resolved coordinates for downstream logic/centering
                    self.startCoordinate = s
                    self.endCoordinate = e
                    buildRoute(from: s, to: e)
                }
            }
        }

        private func buildRoute(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
            computeRoute(start: start, dest: destination)
        }

        private func buildRoute(to destination: CLLocationCoordinate2D) {
            let start = locationManager.lastCoordinate ?? region.center
            computeRoute(start: start, dest: destination)
        }

        private func computeRoute(start: CLLocationCoordinate2D, dest: CLLocationCoordinate2D) {
            // Debug logs for diagnosis
            print("Routing Start:", start.latitude, start.longitude)
            print("Routing End:", dest.latitude, dest.longitude)

            // Basic validation
            func isValid(_ c: CLLocationCoordinate2D) -> Bool {
                c.latitude.isFinite && c.longitude.isFinite && abs(c.latitude) <= 90 && abs(c.longitude) <= 180 && !(abs(c.latitude) < 0.0001 && abs(c.longitude) < 0.0001)
            }
            guard isValid(start), isValid(dest) else {
                withAnimation(.easeInOut(duration: 0.2)) { toast = "Invalid coordinates for routing" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.easeOut(duration: 0.2)) { toast = nil } }
                return
            }

            let src = MKMapItem(placemark: MKPlacemark(coordinate: start))
            let dst = MKMapItem(placemark: MKPlacemark(coordinate: dest))
            // If same point, bail out with a toast
            if abs(start.latitude - dest.latitude) < 0.00001 && abs(start.longitude - dest.longitude) < 0.00001 {
                withAnimation(.easeInOut(duration: 0.2)) { toast = "Start and End are the same" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.easeOut(duration: 0.2)) { toast = nil } }
                return
            }
            func requestRoute(transport: MKDirectionsTransportType, completion: @escaping (MKRoute?) -> Void) {
                let req = MKDirections.Request()
                req.source = src
                req.destination = dst
                req.transportType = transport
                req.requestsAlternateRoutes = true
                MKDirections(request: req).calculate { resp, _ in
                    completion(resp?.routes.sorted(by: { $0.expectedTravelTime < $1.expectedTravelTime }).first)
                }
            }

            // Heuristics: Avoid transit first in Sri Lanka (transit not supported)
            let center = region.center
            let inSriLanka = (center.latitude >= 5.0 && center.latitude <= 10.0 && center.longitude >= 79.0 && center.longitude <= 82.5)
            let startCL = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let endCL = CLLocation(latitude: dest.latitude, longitude: dest.longitude)
            let distanceKm = startCL.distance(from: endCL) / 1000.0

            var requestedMode = transportMode
            if requestedMode == .walking && distanceKm > 50 {
                // Too far to walk — auto switch to driving
                requestedMode = .driving
            }

            let order: [MKDirectionsTransportType]
            switch requestedMode {
            case .driving: order = inSriLanka ? [.automobile, .walking, .transit] : [.automobile, .walking, .transit]
            case .walking: order = inSriLanka ? [.walking, .automobile, .transit] : [.walking, .automobile, .transit]
            case .transit: order = inSriLanka ? [.automobile, .walking, .transit] : [.transit, .walking, .automobile]
            }

            if transportMode == .transit && inSriLanka {
                withAnimation(.easeInOut(duration: 0.2)) { toast = "Transit unavailable here — using Vehicle" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.easeOut(duration: 0.2)) { toast = nil } }
            }

            func tryIndex(_ idx: Int) {
                if idx >= order.count {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.2)) { toast = "No route found for selected mode" }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { withAnimation(.easeOut(duration: 0.2)) { toast = nil } }
                    }
                    return
                }
                requestRoute(transport: order[idx]) { r in
                    if let r { self.apply(route: r) } else { tryIndex(idx + 1) }
                }
            }
            tryIndex(0)
        }

        private func apply(route r: MKRoute) {
            DispatchQueue.main.async {
                self.route = r
                let rect = r.polyline.boundingMapRect
                var center: CLLocationCoordinate2D
                var span: MKCoordinateSpan
                if rect.isNull || rect.size.width.isNaN || rect.size.height.isNaN || rect.size.width == 0 || rect.size.height == 0 {
                    // Fallback to a small span around destination if rect invalid
                    let dest = self.endCoordinate ?? self.selectedCoordinate ?? self.locationManager.lastCoordinate ?? self.region.center
                    center = dest
                    span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                } else {
                    let reg = MKCoordinateRegion(rect)
                    let lat = reg.span.latitudeDelta.isFinite && reg.span.latitudeDelta > 0 ? reg.span.latitudeDelta : 0.02
                    let lon = reg.span.longitudeDelta.isFinite && reg.span.longitudeDelta > 0 ? reg.span.longitudeDelta : 0.02
                    center = reg.center
                    span = MKCoordinateSpan(
                        latitudeDelta: min(max(lat * 1.25, 0.005), 60.0),
                        longitudeDelta: min(max(lon * 1.25, 0.005), 60.0)
                    )
                }
                applyRegionChange(center: center, span: span, animated: true)
            }
        }

        // MARK: - Route summary UI
        @ViewBuilder
        private func routeSummary(_ r: MKRoute) -> some View {
            let km = r.distance / 1000.0
            let mins = Int((r.expectedTravelTime / 60.0).rounded())
            HStack(spacing: 8) {
                Image(systemName: "map")
                Text(String(format: "%.1f km", km))
                Text("•")
                Text("\(mins)m")
            }
            .foregroundColor(.white)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.55))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private struct RoundButton: View {
        let system: String
        var action: () -> Void
        var body: some View {
            Button(action: action) {
                Image(systemName: system)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
    
    // iOS 16 fallback renderer using MKMapView
    struct LegacyRouteMap: UIViewRepresentable {
        @Binding var region: MKCoordinateRegion
        let route: MKRoute
        let user: CLLocationCoordinate2D?
        let destination: CLLocationCoordinate2D?

        func makeCoordinator() -> Coordinator { Coordinator() }

        func makeUIView(context: Context) -> MKMapView {
            let map = MKMapView(frame: .zero)
            map.delegate = context.coordinator
            map.isRotateEnabled = true
            map.isPitchEnabled = true
            map.showsCompass = false
            map.pointOfInterestFilter = .includingAll
            map.region = region
            map.addOverlay(route.polyline)
            addAnnotations(to: map)
            zoomToRoute(on: map)
            return map
        }

        func updateUIView(_ map: MKMapView, context: Context) {
            if map.region.center.latitude != region.center.latitude || map.region.center.longitude != region.center.longitude {
                map.setRegion(region, animated: false)
            }
            map.removeOverlays(map.overlays)
            map.addOverlay(route.polyline)
            map.removeAnnotations(map.annotations)
            addAnnotations(to: map)
            zoomToRoute(on: map)
        }

        private func addAnnotations(to map: MKMapView) {
            if let u = user {
                let ann = MKPointAnnotation()
                ann.coordinate = u
                ann.title = "Start"
                map.addAnnotation(ann)
            }
            if let d = destination {
                let ann = MKPointAnnotation()
                ann.coordinate = d
                ann.title = "End"
                map.addAnnotation(ann)
            }
        }

        private func zoomToRoute(on map: MKMapView) {
            let rect = route.polyline.boundingMapRect
            let insets = UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40)
            map.setVisibleMapRect(rect, edgePadding: insets, animated: true)
        }

        final class Coordinator: NSObject, MKMapViewDelegate {
            func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
                if let poly = overlay as? MKPolyline {
                    let r = MKPolylineRenderer(polyline: poly)
                    r.strokeColor = UIColor.systemBlue
                    r.lineWidth = 5
                    r.lineJoin = .round
                    r.lineCap = .round
                    return r
                }
                return MKOverlayRenderer(overlay: overlay)
            }
        }
    }
    
#if DEBUG
    #Preview("Map") {
        MapView()
    }
#endif

// Proxy delegate to surface MKLocalSearchCompleter results into SwiftUI state
final class MKLocalSearchCompleterDelegateProxy: NSObject, MKLocalSearchCompleterDelegate {
    private let onUpdate: ([MKLocalSearchCompletion]) -> Void
    init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) { self.onUpdate = onUpdate }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate(completer.results)
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Intentionally noop; MapView shows its own toasts when needed
    }
}

// MARK: - Utilities
private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

