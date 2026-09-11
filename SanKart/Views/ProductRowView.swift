import SwiftUI

public struct ProductRowView: View {
    @ObservedObject public var product: CDProduct
    public var onQuantityChanged: (Int32) -> Void

    @State private var isPressed = false

    private let accent   = Color(red: 0.25, green: 0.40, blue: 0.95)
    private let greenBadge = Color(red: 0.10, green: 0.72, blue: 0.46)

    public init(product: CDProduct, onQuantityChanged: @escaping (Int32) -> Void) {
        self.product = product
        self.onQuantityChanged = onQuantityChanged
    }

    private var isActive: Bool { product.quantity > 0 }

    public var body: some View {
        HStack(alignment: .center, spacing: 13) {

            // ── Avatar badge ──────────────────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        isActive
                        ? LinearGradient(
                            colors: [accent, Color(red: 0.40, green: 0.60, blue: 1.0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(
                            colors: [Color(red: 0.90, green: 0.92, blue: 0.98),
                                     Color(red: 0.86, green: 0.89, blue: 0.97)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 46, height: 46)

                Text(String(product.wrappedName.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(isActive ? .white : Color(red: 0.55, green: 0.58, blue: 0.75))
            }
            .shadow(
                color: isActive ? accent.opacity(0.28) : Color.black.opacity(0.04),
                radius: isActive ? 8 : 2, x: 0, y: 3
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isActive)

            // ── Product info ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(product.wrappedName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.10, green: 0.12, blue: 0.28))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    // Rate badge
                    Text(product.formattedRate)
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(greenBadge)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule().fill(greenBadge.opacity(0.10))
                                .overlay(Capsule().stroke(greenBadge.opacity(0.25), lineWidth: 0.8))
                        )

                    if !product.wrappedCode.isEmpty && product.wrappedCode != "-" {
                        Text(product.wrappedCode)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 0.60, green: 0.62, blue: 0.76))
                    }
                }

                if isActive {
                    HStack(spacing: 3) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 10))
                        Text(product.formattedSubtotal)
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(accent)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isActive)

            Spacer(minLength: 4)

            // ── Qty stepper ───────────────────────────────────────────
            QuantityStepperView(
                quantity: Binding(get: { product.quantity }, set: { product.quantity = $0 }),
                onQuantityChanged: onQuantityChanged
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .shadow(
                    color: isActive ? accent.opacity(0.12) : Color.black.opacity(0.05),
                    radius: isActive ? 12 : 4, x: 0, y: isActive ? 5 : 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isActive ? accent.opacity(0.30) : Color(red: 0.88, green: 0.90, blue: 0.97),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isActive)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}
