//
//  Downloads.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import SwiftUI

struct Downloads: View {
    
    @State private var downloadsJSON = DownloadedManga.GetDownloads()
    
    var body: some View {
        NavigationView {
            VStack {
                if downloadsJSON.isEmpty {
                    VStack(spacing: 10) {
                        Text("No Downloads Available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("If you've downloaded something and it's not showing up, please pull down to refresh.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                } else {
                    List(downloadsJSON.indices, id: \.self) { mangaIndex in
                        let title = downloadsJSON[mangaIndex].MangaDetail.attributes.title.en ?? "Unknown Title"
                        NavigationLink(title, destination: ChooseChapter(DownManga: downloadsJSON[mangaIndex]))
                    }
                    .refreshable {
                        downloadsJSON = DownloadedManga.GetDownloads()
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ChooseChapter: View {
    @State var DownManga: DownloadedManga
    
    var body: some View {
        let title = DownManga.MangaDetail.attributes.title.en ?? "Unknown Title"
        
        List {
            ForEach(DownManga.chapters.indices, id: \.self) { chapterIndex in
                let chapter = DownManga.chapters[chapterIndex]
                let chapterTitle = chapter.chapterName
                NavigationLink(chapterTitle, destination: ReadDownload(chapterPages: chapter.chapterPages))
            }
            .onDelete(perform: deleteDownloadedChapter)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
    }
    
    /// Deletes a downloaded chapter and updates the UI and storage.
    func deleteDownloadedChapter(at offsets: IndexSet) {
        var allDownloads = DownloadedManga.GetDownloads()
        guard let mangaIndex = allDownloads.firstIndex(where: { $0.MangaDetail.id == DownManga.MangaDetail.id }) else { return }
        
        offsets.sorted(by: >).forEach { index in
            let chapterToDelete = allDownloads[mangaIndex].chapters[index]
            print("Deleting \(chapterToDelete.chapterName)")
            deleteDownChapters(chapterToDelete.chapterPages)
        }
        
        // Update JSON data
        allDownloads[mangaIndex].chapters.remove(atOffsets: offsets)
        if allDownloads[mangaIndex].chapters.isEmpty {
            allDownloads.remove(at: mangaIndex)
        }
        DownloadedManga.updateDownloads(with: allDownloads)
        
        // Update UI
        withAnimation {
            DownManga.chapters.remove(atOffsets: offsets)
        }
    }
}

struct ReadDownload: View {
    
    var chapterPages: [String]
    
    @State private var uiImages = [String: UIImage]()
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(chapterPages, id: \.self) { pageLink in
                    if let uiImage = uiImages[pageLink] {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } else {
                        ProgressView()
                            .frame(height: 200)
                            .onAppear {
                                loadImage(from: pageLink)
                            }
                    }
                }
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Loads an image from the local storage.
    func loadImage(from pageLink: String) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = URL(string: pageLink)?.lastPathComponent ?? ""
        let fileURL = documents.appendingPathComponent(fileName)
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageData = try? Data(contentsOf: fileURL),
               let uiImage = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.uiImages[pageLink] = uiImage
                }
            }
        }
    }
}

struct Downloads_Previews: PreviewProvider {
    static var previews: some View {
        Downloads()
    }
}
