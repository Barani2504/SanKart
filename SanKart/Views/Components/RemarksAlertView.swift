import SwiftUI

public struct RemarksModalView: View {
    @Binding public var isPresented: Bool
    @Binding public var remarks: String
    public let onConfirm: () -> Void

    @FocusState private var isFieldFocused: Bool

    public init(isPresented: Binding<Bool>, remarks: Binding<Bool> = .constant(false), remarksText: Binding<String>, onConfirm: @escaping () -> Void) {
        self._isPresented = isPresented
        self._remarks = remarksText
        self.onConfirm = onConfirm
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header icon & title
            VStack(spacing: 8) {
                Image(systemName: "square.and.pencil.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)

                Text("Order Remarks")
                    .font(.title3.bold())

                Text("Add any special instructions or remarks for this order before saving.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Text Editor or TextField
            VStack(alignment: .leading, spacing: 6) {
                TextField("Enter remarks here (optional)...", text: $remarks, axis: .vertical)
                    .lineLimit(3...5)
                    .focused($isFieldFocused)
                    .padding(12)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            // Buttons
            HStack(spacing: 12) {
                Button(role: .cancel) {
                    isPresented = false
                } label: {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.secondarySystemFill))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }

                Button {
                    isPresented = false
                    onConfirm()
                } label: {
                    Text("Submit Order")
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 24)
        .onAppear {
            isFieldFocused = true
        }
    }
}
