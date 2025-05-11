//
//  ReadingList.swift
//  Mugen Reader V2
//
//  Created by Carlos Mbendera on 30/11/2022.
//

import SwiftUI

struct ReadingList: View {
    
    @State private var readingListManga = [Manga]()
    @State private var readingListChapters = [FeedChapter]()
    
    var body: some View {
        NavigationView {
            if (!readingListManga.isEmpty) {
                readingMangaListView
                    .navigationTitle("Reading List")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        EditButton()
                    }
            } else {
                VStack(spacing: 10) {
                    Text("You Haven't Started Any Manga")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text(":D")
                        .font(.largeTitle)
                }
                .task {
                    getReadingManga()
                }
            }
        }
    }
    
    var readingMangaListView: some View {
        List {
            ForEach(readingListManga.indices, id: \.self) { index in
                let manga = readingListManga[index]
                let chapter = readingListChapters[index]
                NavigationLink(destination: ReadingView(viewChapterID: chapter.id)) {
                    HStack {
                        VStack(alignment: .leading) {
                            MangaView(item: manga)
                            FeedChapter.buildChapterNameView(chapter)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle()) // Makes the entire row tappable
                }
            }
            .onDelete(perform: deleteItemFromLastRead)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Loads the reading manga and chapters from the last-read list.
    func getReadingManga() {
        let lastRead = GetLastRead()
        readingListManga = lastRead.map { $0.MangaDetail }
        readingListChapters = lastRead.map { $0.Chapter }
    }
    
    /// Deletes an item from the last-read list and updates the UI and storage.
    func deleteItemFromLastRead(at offsets: IndexSet) {
        var listOfRead = GetLastRead()
        
        guard !listOfRead.isEmpty else { return }
        
        withAnimation {
            listOfRead.remove(atOffsets: offsets)
            readingListManga.remove(atOffsets: offsets)
            readingListChapters.remove(atOffsets: offsets)
        }
        
        updateLastReadChapter(with: listOfRead)
    }
}

struct ReadingList_Previews: PreviewProvider {
    static var previews: some View {
        ReadingList()
    }
}
