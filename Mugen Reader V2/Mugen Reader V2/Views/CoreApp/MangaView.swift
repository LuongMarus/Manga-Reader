//
//  MangaView.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import SwiftUI

struct MangaView: View {
    
    let item: Manga
    
    var body: some View {
        HStack {
            // Manga Cover Image
            Manga.getCover(item: item)
                .scaledToFit()
                .frame(width: 75, height: 112.5)
                .cornerRadius(10)
                .shadow(color: .gray, radius: 5, x: 0, y: 2) // Subtle shadow
            
            // Manga Details
            VStack(alignment: .leading, spacing: 5) {
                // Manga Title
                Text(item.attributes.title.en ?? "No Title Available")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                // Manga Status
                Text("Status: \(formattedStatus(item.attributes.status))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Manga Year
                Text("Year: \(formattedYear(item.attributes.year))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Helper Functions
    
    /// Formats the status string to ensure it's capitalized and readable.
    private func formattedStatus(_ status: String) -> String {
        return status.isEmpty ? "Unknown" : status.capitalized
    }
    
    /// Formats the year to display "N/A" if the year is missing or invalid.
    private func formattedYear(_ year: Int?) -> String {
        guard let year = year, year != 0 else { return "N/A" }
        return String(year)
    }
}

struct MangaView_Previews: PreviewProvider {
    static var previews: some View {
        MangaView(item: Manga.produceExampleManga())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

