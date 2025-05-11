import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            Text("Mugen Reader V2")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
} 