import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            CipherStyle.Colors.background
                .ignoresSafeArea()

            Image("logotype")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(CipherStyle.Colors.primaryText)
                .padding(.horizontal, 100)
        }
    }
}
