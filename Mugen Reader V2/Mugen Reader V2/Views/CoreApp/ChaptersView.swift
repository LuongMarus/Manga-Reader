//
//  ChaptersView.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import SwiftUI

struct ChaptersView: View {
    
    @State private var selectedChapters = Set<String>()
    @State private var downloadingChapters = [String: Bool]()
    
    let chosenManga: Manga
    
    @State private var chapterResults = [FeedChapter]()
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading chapters...")
                    .navigationTitle(chosenManga.attributes.title.en ?? "No English Title")
            } else if chapterResults.isEmpty {
                Text("No chapters available.")
                    .navigationTitle(chosenManga.attributes.title.en ?? "No English Title")
            } else {
                ChaptersList
                    .toolbar {
                        ToolbarContent
                    }
                    .navigationTitle(chosenManga.attributes.title.en ?? "No English Title")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task {
            await loadChapters()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
    
    var ChaptersList: some View {
        List(chapterResults, selection: $selectedChapters) { item in
            HStack {
                if downloadingChapters[item.id] == true {
                    ProgressView()
                } else if let downloaded = downloadingChapters[item.id], downloaded == false {
                    Text("Downloaded")
                }
                
                NavigationLink(
                    destination: ReadingView(viewChapterID: item.id)
                        .onAppear {
                            let currentLastRead = LastReadChapter(id: chosenManga.id, MangaDetail: chosenManga, Chapter: item)
                            appendToLastReadChapters(currentLastRead)
                        },
                    label: {
                        FeedChapter.buildChapterNameView(item)
                    }
                )
                .id(item.id) // .id for allowing jump scrolling
                .contextMenu {
                    Button("Download") {
                        Task {
                            let chapterName = "\(item.attributes.chapter ?? ""): \(item.attributes.title ?? "")"
                            await downloadChapter(item.id, chapterName: chapterName)
                        }
                    }
                }
            }
        }
    }
    
    var ToolbarContent: some ToolbarContent {
        Group {
            if let index = getLastReadID() {
                Button("Continue") {
                    withAnimation {
                        ScrollViewReader { proxy in
                            proxy.scrollTo(index, anchor: .top)
                        }
                    }
                }
            }
            
            EditButton()
            
            Button("Download Selected") {
                downloadMultiChapter()
            }
        }
    }
    
    func downloadMultiChapter() {
        for chapterID in selectedChapters {
            if let chapter = chapterResults.first(where: { $0.id == chapterID }) {
                let chapterName = "\(chapter.attributes.chapter ?? ""): \(chapter.attributes.title ?? "")"
                downloadingChapters[chapterID] = true
                
                Task {
                    await downloadChapter(chapterID, chapterName: chapterName)
                    downloadingChapters[chapterID] = false
                }
            }
        }
    }
    
    func downloadChapter(_ chapterID: String, chapterName: String) async {
        do {
            await DownloadedManga.downloadChapter(manga: chosenManga, chapterID: chapterID, chapterName: chapterName)
        } catch {
            errorMessage = "Failed to download chapter: \(error.localizedDescription)"
        }
    }
    
    func getLastReadID() -> String? {
        let lastReadChapters = GetLastRead()
        guard let sameManga = lastReadChapters.first(where: { $0.id == chosenManga.id }) else {
            return nil
        }
        return chapterResults.first(where: { $0.id == sameManga.Chapter.id })?.id
    }
    
    func loadChapters() async {
        isLoading = true
        do {
            var apiChapterResults = try await FeedChapter.getMangaChapterFeed(for: chosenManga.id)
            apiChapterResults.sort {
                guard let titleNum0 = $0.attributes.chapter, let titleNum1 = $1.attributes.chapter else { return false }
                return titleNum0.localizedStandardCompare(titleNum1) == .orderedAscending
            }
            withAnimation {
                chapterResults = apiChapterResults
            }
        } catch {
            errorMessage = "Failed to load chapters: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct ReadingView: View {
    var viewChapterID: String
    @State private var messageAlertError = ""
    @State private var showingChapterAlert = false
    @State private var chapterPages = [String]()
    @State private var currentPage = 0
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            // Reading View
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(chapterPages.indices, id: \.self) { index in
                        AsyncImage(url: URL(string: chapterPages[index])) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 300)
                            case .failure:
                                Image(systemName: "exclamationmark.icloud")
                                    .frame(height: 300)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            @unknown default:
                                Image(systemName: "exclamationmark.icloud")
                                    .frame(height: 300)
                            }
                        }
                        .id(index)
                    }
                }
            }
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        withAnimation {
                            showControls.toggle()
                        }
                    }
            )
            
            // Controls Overlay
            if showControls {
                VStack {
                    // Top Bar
                    HStack {
                        Button(action: { /* Back action */ }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("Trang \(currentPage + 1)/\(chapterPages.count)")
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { /* Settings action */ }) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    Spacer()
                    
                    // Bottom Bar
                    HStack {
                        Button(action: { /* Previous page */ }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .disabled(currentPage == 0)
                        
                        Spacer()
                        
                        Button(action: { /* Next page */ }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .disabled(currentPage == chapterPages.count - 1)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Có lỗi xảy ra", isPresented: $showingChapterAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(messageAlertError)
        }
        .task {
            await loadChapterPages()
        }
    }
    
    func loadChapterPages() async {
        do {
            chapterPages = try await FeedChapter.getChapterPageImageURLs(chapterID: viewChapterID)
        } catch {
            showingChapterAlert = true
            messageAlertError = "Không thể tải trang chapter: \(error.localizedDescription)"
        }
    }
}

struct ChaptersView_Previews: PreviewProvider {
    static var previews: some View {
        ChaptersView(chosenManga: Manga.produceExampleManga())
    }
}

