//
//  Manga.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import Foundation
import SwiftUI

// MARK: - Manga Structs

struct SeasonalMangaListAntsylich: Codable {
    let id: String
    let name: String
    let manga_ids: [String]
}

struct MangaResponse: Codable {
    var result: String
    var response: String
    var data: [Manga]
}

struct Manga: Codable, Identifiable {
    var id: String
    var type: String
    var attributes: MangaAttributes
    var relationships: [MangaRelations]
}

struct MangaAttributes: Codable {
    var title: MangaLang
    var description: MangaLang?
    var year: Int? // Optional vì không phải manga nào cũng có thông tin năm phát hành
    var status: String
}

struct MangaLang: Codable {
    var en: String?
}

struct MangaRelations: Codable {
    var id: String
    var type: String
    var attributes: MangaRelationAttributes?
}

struct MangaRelationAttributes: Codable {
    var fileName: String?
}

// MARK: - Errors

enum MangaCallError: Error {
    case invalidURL(String)
    case decodingError(String)
    case networkError(String)
}

// MARK: - Extensions

extension Manga {
    
    /// Xây dựng URL tìm kiếm manga dựa trên từ khóa.
    static func buildSearchLink(for queryText: String) -> String {
        guard let encodedQuery = queryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return ""
        }
        
        return """
        https://api.mangadex.org/manga?title=\(encodedQuery)&includedTagsMode=AND&excludedTagsMode=OR&availableTranslatedLanguage%5B%5D=en&contentRating%5B%5D=safe&contentRating%5B%5D=suggestive&contentRating%5B%5D=erotica&order%5BlatestUploadedChapter%5D=desc&includes%5B%5D=manga&includes%5B%5D=cover_art
        """
    }
    
    /// Lấy danh sách manga theo mùa từ API của Antsylich.
    static func getCallSeasonalMangaFromAntsylich() async throws -> String {
        guard let url = URL(string: "https://antsylich.github.io/mangadex-seasonal/seasonal-list.json") else {
            throw MangaCallError.invalidURL("Invalid Antsylich URL")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SeasonalMangaListAntsylich.self, from: data)
            
            let idsListString = response.manga_ids.map { "&ids%5B%5D=\($0)" }.joined()
            
            return """
            https://api.mangadex.org/manga?includedTagsMode=AND&excludedTagsMode=OR&availableTranslatedLanguage%5B%5D=en\(idsListString)&contentRating%5B%5D=safe&contentRating%5B%5D=suggestive&contentRating%5B%5D=erotica&order%5BlatestUploadedChapter%5D=desc&includes%5B%5D=manga&includes%5B%5D=cover_art
            """
        } catch {
            throw MangaCallError.networkError("Failed to fetch seasonal manga IDs: \(error.localizedDescription)")
        }
    }
    
    /// Xây dựng URL gọi API manga theo danh sách mùa.
    static func buildSeasonalMangaCall(seasonListId: String) async throws -> String {
        let listURL = "https://api.mangadex.org/list/\(seasonListId)"
        
        guard let apiURL = URL(string: listURL) else {
            throw MangaCallError.invalidURL("Invalid seasonal list URL")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let decodedResponse = try JSONDecoder().decode(SeasonalResponseJSON.self, from: data)
            
            let idsListString = decodedResponse.data.relationships.map { "&ids%5B%5D=\($0.id)" }.joined()
            
            return """
            https://api.mangadex.org/manga?includedTagsMode=AND&excludedTagsMode=OR&availableTranslatedLanguage%5B%5D=en\(idsListString)&contentRating%5B%5D=safe&contentRating%5B%5D=suggestive&contentRating%5B%5D=erotica&order%5BlatestUploadedChapter%5D=desc&includes%5B%5D=manga&includes%5B%5D=cover_art
            """
        } catch {
            throw MangaCallError.decodingError("Failed to decode seasonal manga response: \(error.localizedDescription)")
        }
    }
    
    /// Gọi API MangaDex để lấy danh sách manga.
    static func callMangaDexAPI(for callURL: String) async throws -> [Manga] {
        guard let apiURL = URL(string: callURL) else {
            throw MangaCallError.invalidURL("Invalid MangaDex API URL")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let decodedResponse = try JSONDecoder().decode(MangaResponse.self, from: data)
            return decodedResponse.data
        } catch {
            throw MangaCallError.networkError("Failed to fetch manga data: \(error.localizedDescription)")
        }
    }
    
    /// Lấy ảnh bìa của manga.
    static func getCover(item: Manga) -> some View {
        let coverURL = item.relationships
            .filter { $0.type == "cover_art" }
            .compactMap { $0.attributes?.fileName }
            .first
            .map { "https://uploads.mangadex.org/covers/\(item.id)/\($0).256.jpg" }
        
        return CachedAsyncImage(url: URL(string: coverURL ?? "")) { phase in
            switch phase {
            case .empty:
                ProgressView().padding()
            case .failure:
                Image(systemName: "exclamationmark.icloud")
            case .success(let image):
                image.resizable()
            @unknown default:
                Image(systemName: "exclamationmark.icloud")
            }
        }
    }
    
    /// Tạo một manga mẫu để hiển thị khi không có dữ liệu.
    static func produceExampleManga() -> Manga {
        let dummyLang = MangaLang(en: "Please Try Again")
        let dummyDesc = MangaLang(en: "Either an error happened or we're still loading data")
        let dummyAttributes = MangaAttributes(title: dummyLang, description: dummyDesc, year: 3000, status: "Very Sad")
        return Manga(id: "Blah", type: "manga", attributes: dummyAttributes, relationships: [])
    }
}




