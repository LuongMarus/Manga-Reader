//
//  DownloadingManga.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import AVFoundation
import Foundation

// MARK: - Models

struct DownloadedManga: Codable {
    let MangaDetail: Manga
    var chapters: [DownloadedChapter]
}

struct DownloadedChapter: Codable, Equatable {
    let chapterName: String
    let chapterID: String
    var chapterPages: [String]
}

// MARK: - Utilities

/// Downloads and stores an image from a given URL.
func downloadAndStoreImage(url: String) throws {
    guard let imageUrl = URL(string: url) else {
        throw NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(url)"])
    }
    
    do {
        let imageData = try Data(contentsOf: imageUrl)
        let fileName = imageUrl.lastPathComponent
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documents.appendingPathComponent(fileName)
        try imageData.write(to: fileURL)
    } catch {
        throw NSError(domain: "Download Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to download or save image from URL: \(url)"])
    }
}

/// Deletes downloaded chapter pages.
func deleteDownloadedChapters(_ chapter: [String]) {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    for page in chapter {
        guard let fileName = URL(string: page)?.lastPathComponent else {
            print("Invalid page URL: \(page)")
            continue
        }
        let fileURL = documents.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Removed \(fileURL)")
        } catch {
            print("Failed to remove \(fileURL): \(error.localizedDescription)")
        }
    }
}

// MARK: - Extensions

extension DownloadedManga {
    
    /// Downloads a chapter for a given manga.
    static func downloadChapter(manga: Manga, chapterID: String, chapterName: String) async {
        let existingDownloads = getDownloads()
        let exists = existingDownloads.contains { $0.MangaDetail.id == manga.id && $0.chapters.contains { $0.chapterID == chapterID } }
        if exists {
            print("Chapter already downloaded. Skipping download.")
            return
        }
        
        do {
            let decodedResponse = try await FeedChapter.getChapterPageImageURLs(chapterID: chapterID)
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            var finalUrlArr = [String]()
            for urlString in decodedResponse {
                try downloadAndStoreImage(url: urlString)
                let fileName = URL(string: urlString)!.lastPathComponent
                let fileURL = documents.appendingPathComponent(fileName)
                finalUrlArr.append("\(fileURL)")
            }
            
            var downs = [DownloadedChapter]()
            let downloadedChapter = DownloadedChapter(chapterName: chapterName, chapterID: chapterID, chapterPages: finalUrlArr)
            downs.append(downloadedChapter)
            let newDownload = DownloadedManga(MangaDetail: manga, chapters: downs)
            appendDownloadedChapters(newDownload)
            
        } catch {
            print("Failed to download chapter: \(error.localizedDescription)")
        }
    }
    
    /// Retrieves all downloaded manga.
    static func getDownloads() -> [DownloadedManga] {
        do {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = paths[0].appendingPathComponent("DownloadedChapters.json")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode([DownloadedManga].self, from: data)
            } else {
                return []
            }
        } catch {
            print("Failed to retrieve downloads: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Appends a new downloaded chapter to the list of downloads.
    static func appendDownloadedChapters(_ downMan: DownloadedManga) {
        AudioServicesPlayAlertSound(SystemSoundID(1351)) // Play sound to indicate download completion
        
        var downloadedManga = getDownloads()
        
        if let sameMangaIndex = downloadedManga.firstIndex(where: { $0.MangaDetail.id == downMan.MangaDetail.id }) {
            downloadedManga[sameMangaIndex].chapters.append(downMan.chapters.last!)
        } else {
            downloadedManga.append(downMan)
        }
        
        updateDownloads(with: downloadedManga)
    }
    
    /// Updates the list of downloaded manga.
    static func updateDownloads(with newDownload: [DownloadedManga]) {
        do {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = paths[0].appendingPathComponent("DownloadedChapters.json")
            
            let encodedData = try JSONEncoder().encode(newDownload)
            try encodedData.write(to: fileURL)
            print("Finished encoding and saving downloads.")
            
            // Debugging: Verify saved data
            let jsonData = try Data(contentsOf: fileURL)
            let finalData = try JSONDecoder().decode([DownloadedManga].self, from: jsonData)
            print("Final saved data: \(finalData)")
        } catch {
            print("Failed to update downloads: \(error.localizedDescription)")
        }
    }
}
