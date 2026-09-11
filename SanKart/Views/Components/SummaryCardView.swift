import SwiftUI

public struct SummaryCardView: View {
    public let summary: CartSummary
    public let isSaving: Bool
    public let onSaveTapped: () -> Void

    @State private var buttonPressed = false
    @State private var shimmer = false

    private let accent = Color(red: 0.25, green: 0.40, blue: 0.95)
    private let teal   = Color(red: 0.12, green: 0.68, blue: 0.80)
    private let green  = Color(red: 0.10, green: 0.72, blue: 0.46)

    public init(summary: CartSummary, isSaving: Bool = false, onSaveTapped: @escaping () -> Void) {
        self.summary = summary
        self.isSaving = isSaving
        self.onSaveTapped = onSaveTapped
    }

    public var body: some View {
        VStack(spacing: 14) {

            // ── Drag pill ─────────────────────────────────────────────
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.80, green: 0.82, blue: 0.90))
                .frame(width: 36, height: 4)

            // ── Metric pills ──────────────────────────────────────────
            HStack(spacing: 10) {
                MetricPill(icon: "square.grid.2x2.fill",          label: "Items",  value: "\(summary.totalItems)", color: accent)
                MetricPill(icon: "number.circle.fill",             label: "Qty",    value: "\(summary.totalQty)",   color: teal)
                MetricPill(icon: "indianrupeesign.circle.fill",    label: "Amount", value: summary.formattedAmount, color: green)
            }

            // ── Place Order button ────────────────────────────────────
            Button {
                guard summary.hasItems && !isSaving else { return }
                buttonPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    buttonPressed = false
                    onSaveTapped()
                }
            } label: {
                ZStack {
                    // Shimmer sweep
                    if summary.hasItems && !isSaving {
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.30), .clear],
                            startPoint: .init(x: shimmer ? 1.2 : -0.4, y: 0.5),
                            endPoint:   .init(x: shimmer ? 1.6 : 0.0,  y: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    HStack(spacing: 10) {
                        if isSaving {
                            ProgressView().progressViewStyle(.circular).tint(.white)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 17, weight: .bold))
                        }
                        Text(isSaving ? "Submitting..." : "Place Order")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Group {
                        if summary.hasItems && !isSaving {
                            LinearGradient(
                                colors: [accent, Color(red: 0.40, green: 0.60, blue: 1.0)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        } else {
                            LinearGradient(
                                colors: [Color(red: 0.88, green: 0.90, blue: 0.96),
                                         Color(red: 0.88, green: 0.90, blue: 0.96)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: summary.hasItems ? accent.opacity(0.35) : .clear,
                    radius: 14, x: 0, y: 6
                )
                .scaleEffect(buttonPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.62), value: buttonPressed)
            }
            .disabled(!summary.hasItems || isSaving)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: summary.hasItems)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 32)
        .background(
            ZStack {
                // White panel
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white)
                // Subtle border
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color(red: 0.86, green: 0.88, blue: 0.96), lineWidth: 1)
            }
            .shadow(color: Color(red: 0.25, green: 0.40, blue: 0.95).opacity(0.10), radius: 24, x: 0, y: -6)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -2)
        )
        .padding(.horizontal, 12)
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false).delay(1.0)) {
                shimmer = true
            }
        }
    }
}

// MARK: - Metric Pill
private struct MetricPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(red: 0.52, green: 0.55, blue: 0.70))
                    .textCase(.uppercase)
                    .tracking(0.6)
            }
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.10, green: 0.12, blue: 0.28))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: value)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(color.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color(red: 0.95, green: 0.96, blue: 1.0).ignoresSafeArea()
        SummaryCardView(
            summary: CartSummary(totalItems: 5, totalQty: 12, totalAmount: 2485.50),
            isSaving: false,
            onSaveTapped: {}
        )
    }
}
