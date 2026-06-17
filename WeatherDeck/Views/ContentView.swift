import SwiftUI

struct ContentView: View {
    @State private var vm = WeatherViewModel()
    @State private var location = LocationService()
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var searchResults: [LocationService.GeoResult] = []
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                statusBar

                TabView(selection: $selectedTab) {
                    CurrentView(vm: vm)
                        .tag(0)
                        .tabItem { Label("Current", systemImage: "thermometer.medium") }
                    HourlyView(vm: vm)
                        .tag(1)
                        .tabItem { Label("Hourly", systemImage: "clock") }
                    DailyView(vm: vm)
                        .tag(2)
                        .tabItem { Label("7-Day", systemImage: "calendar") }
                    AlertsView(vm: vm)
                        .tag(3)
                        .tabItem { Label("Alerts", systemImage: "exclamationmark.triangle") }
                    RadarView(vm: vm)
                        .tag(4)
                        .tabItem { Label("Radar", systemImage: "antenna.radiowaves.left.and.right") }
                    TidesView(vm: vm)
                        .tag(5)
                        .tabItem { Label("Tides", systemImage: "water.waves") }
                    MoonView(vm: vm)
                        .tag(6)
                        .tabItem { Label("Moon", systemImage: "moon.stars") }
                    CurrentsView(vm: vm)
                        .tag(7)
                        .tabItem { Label("Currents", systemImage: "arrow.left.arrow.right") }
                }
                .tint(Theme.accent)
            }
        }
        .task { await initialLoad() }
        .sheet(isPresented: $showSearch) { searchSheet }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("⛈")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.locationName)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Text(vm.gridInfo)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.accent)
            }
            Button { Task { await vm.loadAll() } } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(vm.isLoading ? Theme.muted : Theme.accent)
            }
            .disabled(vm.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.panel)
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack {
            if vm.isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .scaleEffect(0.7)
            }
            Text(vm.statusMessage)
                .font(.caption2)
                .foregroundStyle(Theme.muted)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Theme.panel2)
    }

    // MARK: - Search sheet

    private var searchSheet: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Theme.muted)
                        TextField("City, ZIP, or lat,lon", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(Theme.text)
                            .autocorrectionDisabled()
                            .onSubmit { Task { await doSearch() } }
                    }
                    .padding(12)
                    .background(Theme.panel2)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Button {
                        Task { await useCurrentLocation() }
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Use Current Location")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Theme.panel2)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    List(searchResults) { result in
                        Button {
                            selectResult(result)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(result.name)
                                    .foregroundStyle(Theme.text)
                                Text("\(String(format: "%.4f", result.lat)), \(String(format: "%.4f", result.lon))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        .listRowBackground(Theme.panel)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSearch = false }
                        .foregroundStyle(Theme.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Actions

    private func initialLoad() async {
        if let coord = await location.requestLocation() {
            vm.lat = coord.latitude
            vm.lon = coord.longitude
            vm.locationName = "Current Location"
        }
        await vm.loadAll()
    }

    private func doSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        let parts = query.split(separator: ",")
        if parts.count == 2,
           let la = Double(parts[0].trimmingCharacters(in: .whitespaces)),
           let lo = Double(parts[1].trimmingCharacters(in: .whitespaces)),
           abs(la) <= 90, abs(lo) <= 180 {
            vm.lat = la; vm.lon = lo
            vm.locationName = String(format: "%.4f, %.4f", la, lo)
            showSearch = false
            Task { await vm.loadAll() }
            return
        }

        searchResults = await location.search(query)
    }

    private func selectResult(_ result: LocationService.GeoResult) {
        vm.lat = result.lat
        vm.lon = result.lon
        vm.locationName = result.name
        showSearch = false
        Task { await vm.loadAll() }
    }

    private func useCurrentLocation() async {
        if let coord = await location.requestLocation() {
            vm.lat = coord.latitude
            vm.lon = coord.longitude
            vm.locationName = "Current Location"
            showSearch = false
            Task { await vm.loadAll() }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
