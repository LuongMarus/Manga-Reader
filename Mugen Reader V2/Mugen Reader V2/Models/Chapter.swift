//
//  Chapter.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import Foundation
import SwiftUI

// MARK: - Models

struct ReadChapterResponse: Codable {
    var result: String
    var baseUrl: String
    var chapter: ChapterPages
}

struct ChapterPages: Codable {
    var hash: String
    var data: [String]
    var dataSaver: [String]
}

struct ChapterFeedResponse: Codable {
    var result: String
    var response: String
    var data: [FeedChapter]
}

struct FeedChapter: Codable, Identifiable {
    var id: String
    var attributes: ChapterDetails
}

struct ChapterDetails: Codable {
    var volume: String?
    var chapter: String?
    var title: String?
}

// MARK: - Errors

enum FeedChapterErrors: Error {
    case badURL(String)
    case decodingError(String)
    case unknownError(String)
}

// MARK: - Extensions

extension FeedChapter {
    
    /// Builds a SwiftUI view displaying the chapter name and title.
    static func buildChapterNameView(_ chapter: FeedChapter) -> some View {
        VStack(alignment: .leading) {
            Text(chapter.attributes.chapter.map { "Chapter \($0)" } ?? "Unknown Chapter")
            if let title = chapter.attributes.title, !title.isEmpty {
                Text(title)
                    .padding(.leading, 10)
            }
        }
    }
    
    /// Fetches the manga chapter feed for a given manga ID.
    static func getMangaChapterFeed(for mangaID: String) async throws -> [FeedChapter] {
        let rawURL = """
        https://api.mangadex.org/manga/\(mangaID)/feed?limit=500&translatedLanguage%5B%5D=en&contentRating%5B%5D=safe&contentRating%5B%5D=suggestive&contentRating%5B%5D=erotica&contentRating%5B%5D=pornographic&includeFutureUpdates=1&order%5BcreatedAt%5D=asc&order%5BupdatedAt%5D=asc&order%5BpublishAt%5D=asc&order%5BreadableAt%5D=asc&order%5Bvolume%5D=asc&order%5Bchapter%5D=asc
        """
        
        guard let apiURL = URL(string: rawURL) else {
            throw FeedChapterErrors.badURL("Invalid URL: \(rawURL)")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let decodedResponse = try JSONDecoder().decode(ChapterFeedResponse.self, from: data)
            return decodedResponse.data
        } catch {
            throw FeedChapterErrors.decodingError("Failed to decode chapter feed response for manga ID: \(mangaID)")
        }
    }
    
    /// Fetches the image URLs for a given chapter ID.
    static func getChapterPageImageURLs(chapterID: String) async throws -> [String] {
        let decodedResponse = try await getReadingChapterURLS(chapterID: chapterID)
        return decodedResponse.chapter.dataSaver.map { page in
            "\(decodedResponse.baseUrl)/data-saver/\(decodedResponse.chapter.hash)/\(page)"
        }
    }
    
    /// Fetches the reading chapter URLs for a given chapter ID.
    static func getReadingChapterURLS(chapterID: String) async throws -> ReadChapterResponse {
        let getReadChaptersURL = "https://api.mangadex.org/at-home/server/\(chapterID)"
        
        guard let callURL = URL(string: getReadChaptersURL) else {
            throw FeedChapterErrors.badURL("Invalid URL: \(getReadChaptersURL)")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: callURL)
            let decodedResponse = try JSONDecoder().decode(ReadChapterResponse.self, from: data)
            return decodedResponse
        } catch {
            throw FeedChapterErrors.decodingError("Failed to decode reading chapter response for chapter ID: \(chapterID)")
        }
    }
}

