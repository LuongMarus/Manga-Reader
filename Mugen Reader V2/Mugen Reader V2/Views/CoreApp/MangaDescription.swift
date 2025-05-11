//
//  MangaDescription.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import SwiftUI

struct MangaDescription: View {
    let selectedManga: Manga
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Image
                GeometryReader { geometry in
                    Manga.getCover(item: selectedManga)
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: 300)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .frame(height: 300)
                
                VStack(spacing: 20) {
                    // Title
                    Text(selectedManga.attributes.title.en ?? "No Title")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Status and Year
                    HStack(spacing: 20) {
                        StatusBadge(status: selectedManga.attributes.status)
                        YearBadge(year: selectedManga.attributes.year)
                    }
                    
                    // Description
                    if let desc = selectedManga.attributes.description?.en, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    // Read Button
                    NavigationLink(destination: ChaptersView(chosenManga: selectedManga)) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Đọc ngay")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .offset(y: -20)
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(status.capitalized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "ongoing": return .green
        case "completed": return .blue
        case "hiatus": return .orange
        default: return .gray
        }
    }
}

struct YearBadge: View {
    let year: Int?
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
            Text(year.map(String.init) ?? "N/A")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct MangaDescription_Previews: PreviewProvider {
    static let PreviewManga = Manga.produceExampleManga()
    static var previews: some View {
        MangaDescription(selectedManga: PreviewManga)
    }
}
