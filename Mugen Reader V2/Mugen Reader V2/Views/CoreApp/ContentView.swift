//
//  ContentView.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import SwiftUI

struct ContentViewGridViewOnly: View {
    
    let seasonId = "77430796-6625-4684-b673-ffae5140f337"
    
    @State private var errorMessage = ""
    @State private var showingErrorAlert = false
    
    @State private var searchText = ""
    @State private var title = "Seasonal"
    
    @State private var mangaResults = [Manga]()
    @State private var homeMangaResults = [Manga]() // Cache cho kết quả trang chủ
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var columns: [GridItem] {
        switch horizontalSizeClass {
        case .compact:
            return Array(repeating: .init(.flexible()), count: 2)
        case .regular:
            return Array(repeating: .init(.flexible()), count: 4)
        default:
            return Array(repeating: .init(.flexible()), count: 2)
        }
    }
    
    var MangaGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(mangaResults) { manga in
                    NavigationLink(destination: MangaDescription(selectedManga: manga)) {
                        MangaView(item: manga)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var body: some View {
        Group {
            if mangaResults.isEmpty {
                VStack {
                    ProgressView()
                    Text("We're trying to get you some manga")
                        .padding()
                    Text("UwU")
                        .padding()
                }
            } else {
                MangaGridView
                    .searchable(text: $searchText)
                    .onChange(of: searchText) { _ in
                        if searchText.isEmpty {
                            mangaResults = homeMangaResults
                            title = "Seasonal"
                        }
                    }
                    .onSubmit(of: .search) {
                        Task { await tryAPICallAgain() }
                    }
                    .navigationTitle(title)
                    .alert(isPresented: $showingErrorAlert) {
                        Alert(
                            title: Text("There was an error :<"),
                            primaryButton: .default(Text("Try Again")) {
                                Task { await tryAPICallAgain() }
                            },
                            secondaryButton: .cancel()
                        )
                    }
            }
        }
        .task { await getHomePageManga() }
    }
    
    // MARK: - API Calls
    
    /// Gọi lại API khi có lỗi hoặc tìm kiếm
    func tryAPICallAgain() async {
        if searchText.isEmpty {
            if homeMangaResults.isEmpty {
                await getHomePageManga()
            } else {
                mangaResults = homeMangaResults
                title = "Seasonal"
            }
        } else {
            await performSearch()
        }
    }
    
    /// Tìm kiếm manga dựa trên từ khóa
    func performSearch() async {
        let searchURL = Manga.buildSearchLink(for: searchText)
        do {
            mangaResults = try await Manga.callMangaDexAPI(for: searchURL)
            title = "Search Results"
        } catch {
            errorMessage = "Failed to fetch search results: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    /// Lấy danh sách manga trang chủ
    func getHomePageManga() async {
        do {
            let builtLink: String
            if let seasonalLink = try await Manga.getCallSeasonalMangaFromAntsylich() {
                builtLink = seasonalLink
            } else {
                builtLink = try await Manga.buildSeasonalMangaCall(seasonListId: seasonId)
            }
            
            homeMangaResults = try await Manga.callMangaDexAPI(for: builtLink)
            withAnimation { mangaResults = homeMangaResults }
            title = "Seasonal"
        } catch {
            errorMessage = "Failed to fetch homepage manga: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

struct ContentViewListViewOnly: View {
    
    let seasonId = "77430796-6625-4684-b673-ffae5140f337"
    
    @State private var errorMessage = ""
    @State private var showingErrorAlert = false
    
    @State private var searchText = ""
    @State private var title = "Seasonal"
    @State private var activeTab: Int = 0
    
    @State private var mangaResults = [Manga]()
    @State private var homeMangaResults = [Manga]()
    
    var body: some View {
        TabView {
            Group {
                if mangaResults.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .shadow(radius: 5)
                        Text("Không tìm thấy manga")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Kéo xuống để làm mới")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                } else {
                    MangaListView
                        .searchable(text: $searchText, prompt: "Tìm kiếm manga...")
                        .onChange(of: searchText) { _ in
                            if searchText.isEmpty {
                                mangaResults = homeMangaResults
                                title = "Seasonal"
                            }
                        }
                        .onSubmit(of: .search) {
                            Task { await tryAPICallAgain() }
                        }
                        .navigationTitle(title)
                        .alert(isPresented: $showingErrorAlert) {
                            Alert(
                                title: Text("Có lỗi xảy ra"),
                                message: Text(errorMessage),
                                primaryButton: .default(Text("Thử lại")) {
                                    Task { await tryAPICallAgain() }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                }
            }
            .tabItem { 
                Label("Seasonal", systemImage: "leaf.fill")
            }
            .tag(0)
            .task { await getHomePageManga() }
            
            Downloads()
                .onAppear { title = "Downloads" }
                .tabItem { 
                    Label("Downloads", systemImage: "arrow.down.circle.fill")
                }
            
            ReadingList()
                .onAppear { title = "Reading List" }
                .tabItem { 
                    Label("Reading List", systemImage: "bookmark.fill")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
    
    var MangaListView: some View {
        List(mangaResults) { manga in
            NavigationLink(destination: MangaDescription(selectedManga: manga)) {
                HStack(spacing: 15) {
                    Manga.getCover(item: manga)
                        .frame(width: 80, height: 120)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(manga.attributes.title.en ?? "No Title")
                            .font(.headline)
                            .lineLimit(2)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text(formattedYear(manga.attributes.year))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(statusColor(manga.attributes.status))
                                .font(.system(size: 8))
                            Text(formattedStatus(manga.attributes.status))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "ongoing": return .green
        case "completed": return .blue
        case "hiatus": return .orange
        default: return .gray
        }
    }
    
    // MARK: - API Calls
    
    func tryAPICallAgain() async {
        if searchText.isEmpty {
            if homeMangaResults.isEmpty {
                await getHomePageManga()
            } else {
                mangaResults = homeMangaResults
                title = "Seasonal"
            }
        } else {
            await performSearch()
        }
    }
    
    func performSearch() async {
        let searchURL = Manga.buildSearchLink(for: searchText)
        do {
            mangaResults = try await Manga.callMangaDexAPI(for: searchURL)
            title = "Search Results"
        } catch {
            errorMessage = "Failed to fetch search results: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    func getHomePageManga() async {
        do {
            let builtLink: String
            if let seasonalLink = try await Manga.getCallSeasonalMangaFromAntsylich() {
                builtLink = seasonalLink
            } else {
                builtLink = try await Manga.buildSeasonalMangaCall(seasonListId: seasonId)
            }
            
            homeMangaResults = try await Manga.callMangaDexAPI(for: builtLink)
            withAnimation { mangaResults = homeMangaResults }
            title = "Seasonal"
        } catch {
            errorMessage = "Failed to fetch homepage manga: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewListViewOnly()
    }
}

