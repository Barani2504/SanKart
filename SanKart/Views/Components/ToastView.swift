import SwiftUI

public struct ToastView: View {
    public let message: String
    public let isError: Bool

    public init(message: String, isError: Bool = false) {
        self.message = message
        self.isError = isError
    }

    private var iconName: String { isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill" }
    private var accentColor: Color {
        isError ? Color(red: 0.92, green: 0.38, blue: 0.28) : Color(red: 0.10, green: 0.72, blue: 0.46)
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accentColor.opacity(0.12)).frame(width: 32, height: 32)
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.10, green: 0.12, blue: 0.28))
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.white)
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
                .overlay(Capsule().stroke(accentColor.opacity(0.25), lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        Color(red: 0.95, green: 0.96, blue: 1.0).ignoresSafeArea()
        VStack(spacing: 16) {
            ToastView(message: "Order placed successfully!", isError: false)
            ToastView(message: "Network error. Please try again.", isError: true)
        }
    }
}
