//
//  Mugen_Reader_V2App.swift
//  Mugen Reader V2
//
//  Created By Marus on 10/05/2025.
//

import SwiftUI

@main
struct Mugen_Reader_V2App: App {
    @State private var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .phone {
                if isShowingSplash {
                    SplashScreen()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    isShowingSplash = false
                                }
                            }
                        }
                } else {
                    ContentViewListViewOnly()
                }
            } else {
                Text("Ứng dụng chỉ hỗ trợ iPhone")
            }
        }
    }
}

// SplashScreen được tách ra thành một file riêng biệt

class MangaService {
    func fetchHomePageManga() async throws -> [Manga] {
        // Tạm thời trả về mock data
        return [
            Manga(id: "1", title: "Manga 1", description: "Description 1"),
            Manga(id: "2", title: "Manga 2", description: "Description 2")
        ]
    }
    
    func searchManga(query: String) async throws -> [Manga] {
        // Tạm thời trả về mock data
        return [
            Manga(id: "3", title: "Manga 3", description: "Description 3"),
            Manga(id: "4", title: "Manga 4", description: "Description 4")
        ]
    }
}

class MangaViewModel: ObservableObject {
    @Published var mangaResults: [Manga] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    func loadHomePageManga() async {
        isLoading = true
        do {
            mangaResults = try await MangaService().fetchHomePageManga()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct SplashScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Text("Mugen Reader V2")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                Text("Đọc truyện mọi lúc, mọi nơi")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 10)
                Text("Nhóm 10 - Ứng Dụng Đọc Truyện")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 5)
                Text("Thành viên: Lương - Luân - Quốc - Huy")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 5)
            }
            .scaleEffect(1.2)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
