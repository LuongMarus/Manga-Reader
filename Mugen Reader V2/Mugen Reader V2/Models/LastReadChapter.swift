//
//  LastReadChapter.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import Foundation

// MARK: - Model

struct LastReadChapter: Codable, Identifiable {
    let id: String
    let MangaDetail: Manga
    var Chapter: FeedChapter
}

// MARK: - Utilities

/// Retrieves the list of last-read chapters from local storage.
func getLastRead() -> [LastReadChapter] {
    do {
        let fileURL = getLastReadFileURL()
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([LastReadChapter].self, from: data)
    } catch {
        print("Failed to retrieve last-read chapters: \(error.localizedDescription)")
        return []
    }
}

/// Appends or updates a last-read chapter in the local storage.
func appendToLastReadChapters(_ lastRead: LastReadChapter) {
    var lastReadChapters = getLastRead()
    
    if let sameMangaIndex = lastReadChapters.firstIndex(where: { $0.id == lastRead.id }) {
        lastReadChapters[sameMangaIndex] = lastRead
    } else {
        lastReadChapters.append(lastRead)
    }
    
    updateLastReadChapters(with: lastReadChapters)
}

/// Updates the list of last-read chapters in local storage.
func updateLastReadChapters(with newLastRead: [LastReadChapter]) {
    do {
        let fileURL = getLastReadFileURL()
        let encodedData = try JSONEncoder().encode(newLastRead)
        try encodedData.write(to: fileURL)
        print("Successfully updated last-read chapters.")
        
        // Debugging: Verify saved data
        let jsonData = try Data(contentsOf: fileURL)
        let finalData = try JSONDecoder().decode([LastReadChapter].self, from: jsonData)
        print("Final saved data: \(finalData)")
    } catch {
        print("Failed to update last-read chapters: \(error.localizedDescription)")
    }
}

// MARK: - Helpers

/// Returns the file URL for storing last-read chapters.
private func getLastReadFileURL() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0].appendingPathComponent("LastReadChapters.json")
}
