import SwiftUI

public struct QuantityStepperView: View {
    @Binding public var quantity: Int32
    public var onQuantityChanged: (Int32) -> Void

    @State private var textValue: String = "0"
    @FocusState private var isFocused: Bool
    @State private var minusPressed = false
    @State private var plusPressed  = false

    private let accent = Color(red: 0.25, green: 0.40, blue: 0.95)

    public init(quantity: Binding<Int32>, onQuantityChanged: @escaping (Int32) -> Void) {
        self._quantity = quantity
        self.onQuantityChanged = onQuantityChanged
    }

    public var body: some View {
        HStack(spacing: 6) {

            // ── Minus ─────────────────────────────────────────────────
            StepButton(
                systemImage: "minus",
                isEnabled: quantity > 0,
                color: Color(red: 0.92, green: 0.28, blue: 0.30),
                isPressed: minusPressed
            ) {
                guard quantity > 0 else { return }
                // Use Binding to avoid capturing inout in escaping closure
                triggerPress($minusPressed)
                let v = quantity - 1
                quantity = v
                textValue = "\(v)"
                onQuantityChanged(v)
            }

            // ── TextField ─────────────────────────────────────────────
            TextField("0", text: $textValue)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.22))
                .frame(width: 44, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isFocused ? accent.opacity(0.08) : Color(red: 0.94, green: 0.95, blue: 0.98))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isFocused ? accent.opacity(0.7) : Color(red: 0.82, green: 0.84, blue: 0.92),
                                    lineWidth: 1.5
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.15), value: isFocused)
                .onChange(of: textValue) { newValue in
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    if filtered != newValue { textValue = filtered }
                    if let parsed = Int32(filtered) {
                        let clamped = min(parsed, 9999)
                        if clamped != quantity { quantity = clamped; onQuantityChanged(clamped) }
                    } else if filtered.isEmpty {
                        quantity = 0; onQuantityChanged(0)
                    }
                }
                .onChange(of: quantity) { newQty in
                    if textValue != "\(newQty)" { textValue = "\(newQty)" }
                }
                .toolbar {
                    if isFocused {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { isFocused = false }
                                .fontWeight(.semibold)
                                .foregroundColor(accent)
                        }
                    }
                }

            // ── Plus ──────────────────────────────────────────────────
            StepButton(
                systemImage: "plus",
                isEnabled: quantity < 9999,
                color: accent,
                isPressed: plusPressed
            ) {
                triggerPress($plusPressed)
                let v = min(quantity + 1, 9999)
                quantity = v
                textValue = "\(v)"
                onQuantityChanged(v)
            }
        }
        .onAppear { textValue = "\(quantity)" }
    }

    // Binding<Bool> avoids the "escaping closure captures inout parameter" error
    private func triggerPress(_ flag: Binding<Bool>) {
        flag.wrappedValue = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            flag.wrappedValue = false
        }
    }
}

// MARK: - Step Button
private struct StepButton: View {
    let systemImage: String
    let isEnabled: Bool
    let color: Color
    let isPressed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isEnabled ? color.opacity(0.10) : Color(red: 0.92, green: 0.93, blue: 0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(isEnabled ? color.opacity(0.30) : Color(red: 0.84, green: 0.86, blue: 0.92), lineWidth: 1)
                    )
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(isEnabled ? color : Color(red: 0.70, green: 0.72, blue: 0.80))
            }
            .frame(width: 30, height: 30)
            .scaleEffect(isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    ZStack {
        Color(red: 0.96, green: 0.97, blue: 1.0).ignoresSafeArea()
        StatefulPreviewWrapper(Int32(3)) { binding in
            QuantityStepperView(quantity: binding) { _ in }
                .padding()
        }
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content
    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }
    var body: some View { content($value) }
}
