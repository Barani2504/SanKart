import SwiftUI
import CoreData

public struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDProduct.name, ascending: true)],
        animation: .default
    )
    private var products: FetchedResults<CDProduct>

    @State private var headerVisible = false
    @State private var listVisible   = false

    private var filteredProducts: [CDProduct] {
        if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Array(products)
        }
        let q = viewModel.searchText.lowercased()
        return products.filter {
            $0.wrappedName.lowercased().contains(q) || $0.wrappedCode.lowercased().contains(q)
        }
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {

            // ── Background ────────────────────────────────────────────
            AppBackground()

            // ── Main content ──────────────────────────────────────────
            VStack(spacing: 0) {
                HeaderView(
                    isLoading: viewModel.isLoading,
                    onSync: { Task { await viewModel.syncData() } }
                )
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -16)

                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .opacity(headerVisible ? 1 : 0)

                if products.isEmpty && viewModel.isLoading {
                    LoadingStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if products.isEmpty && !viewModel.isLoading {
                    EmptyStateView { Task { await viewModel.syncData() } }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(filteredProducts.enumerated()), id: \.element.objectID) { index, product in
                                ProductRowView(product: product) { _ in
                                    viewModel.refreshSummary()
                                }
                                .opacity(listVisible ? 1 : 0)
                                .offset(y: listVisible ? 0 : 24)
                                .animation(
                                    .spring(response: 0.48, dampingFraction: 0.78)
                                        .delay(Double(min(index, 14)) * 0.035),
                                    value: listVisible
                                )
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 185)
                        .padding(.horizontal, 16)
                    }
                    .refreshable { await viewModel.refreshData() }
                }
            }

            // ── Summary card ──────────────────────────────────────────
            SummaryCardView(
                summary: viewModel.summary,
                isSaving: viewModel.isSaving,
                onSaveTapped: { viewModel.handleSaveButtonTap() }
            )

            // ── Toast ─────────────────────────────────────────────────
            if viewModel.showSuccessToast {
                VStack {
                    ToastView(message: viewModel.successToastMessage, isError: viewModel.isToastError)
                        .padding(.top, 56)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.spring()) { viewModel.showSuccessToast = false }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .alert("Save Order", isPresented: $viewModel.showRemarksAlert) {
            TextField("Remarks (optional)...", text: $viewModel.remarksText)
            Button("Cancel", role: .cancel) {}
            Button("Confirm & Save") { Task { await viewModel.submitOrderWithRemarks() } }
        } message: {
            Text("Add remarks before submitting this order.")
        }
        .alert("Something went wrong", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
        .task {
            if products.isEmpty { await viewModel.syncData() } else { viewModel.refreshSummary() }
            withAnimation(.easeOut(duration: 0.45)) { headerVisible = true }
            withAnimation(.easeOut(duration: 0.55).delay(0.12)) { listVisible = true }
        }
        .onChange(of: products.count) { _ in
            if !listVisible { withAnimation(.easeOut(duration: 0.55)) { listVisible = true } }
        }
    }
}

// MARK: - App Background
private struct AppBackground: View {
    var body: some View {
        ZStack {
            // Base cream-white gradient
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.97, blue: 1.00),
                    Color(red: 0.93, green: 0.95, blue: 1.00)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Decorative e-commerce tile pattern
            EcommerceTilePattern()
                .opacity(0.045)

            // Soft top color wash
            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.40, blue: 0.95).opacity(0.08),
                    .clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - E-commerce Tile Pattern
private struct EcommerceTilePattern: View {
    private let icons = ["cart.fill", "bag.fill", "shippingbox.fill", "tag.fill",
                         "giftcard.fill", "star.fill", "heart.fill", "creditcard.fill"]
    private let columns = 5
    private let rows    = 14
    private let spacing: CGFloat = 72

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let font = Font.system(size: 20)
                for row in 0..<rows {
                    for col in 0..<columns {
                        let offsetX: CGFloat = (row % 2 == 0) ? 0 : spacing / 2
                        let x = CGFloat(col) * spacing + offsetX - 10
                        let y = CGFloat(row) * spacing - 20
                        let icon = icons[(row * columns + col) % icons.count]
                        // Draw via resolved text
                        let text = Text(Image(systemName: icon)).font(font)
                        ctx.draw(text, at: CGPoint(x: x, y: y))
                    }
                }
            }
        }
    }
}

// MARK: - Header
private struct HeaderView: View {
    let isLoading: Bool
    let onSync: () -> Void

    private let accent = Color(red: 0.25, green: 0.40, blue: 0.95)

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(accent)
                    Text("SanKart")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.10, green: 0.12, blue: 0.28))
                }
                Text("Product Catalog")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.50, green: 0.54, blue: 0.70))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }

            Spacer()

            Button(action: onSync) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.10))
                        .frame(width: 42, height: 42)
                    Circle()
                        .stroke(accent.opacity(0.18), lineWidth: 1)
                        .frame(width: 42, height: 42)
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(accent)
                            .scaleEffect(0.75)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(accent)
                    }
                }
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 10)
    }
}

// MARK: - Search Bar
private struct SearchBar: View {
    @Binding var text: String
    @FocusState private var focused: Bool
    private let accent = Color(red: 0.25, green: 0.40, blue: 0.95)

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(focused ? accent : Color(red: 0.60, green: 0.62, blue: 0.72))

            TextField("", text: $text,
                      prompt: Text("Search by name or code")
                          .foregroundColor(Color(red: 0.68, green: 0.70, blue: 0.80)))
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.10, green: 0.12, blue: 0.28))
                .tint(accent)
                .focused($focused)

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(red: 0.70, green: 0.72, blue: 0.82))
                        .font(.system(size: 15))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .shadow(
                    color: focused ? accent.opacity(0.18) : Color.black.opacity(0.06),
                    radius: focused ? 8 : 4, x: 0, y: 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(focused ? accent.opacity(0.45) : Color(red: 0.88, green: 0.89, blue: 0.95), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: focused)
    }
}

// MARK: - Loading State
private struct LoadingStateView: View {
    @State private var spin = false
    private let accent = Color(red: 0.25, green: 0.40, blue: 0.95)

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(accent.opacity(0.12), lineWidth: 3)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(colors: [accent, accent.opacity(0.2)],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .onAppear {
                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            spin = true
                        }
                    }
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 22))
                    .foregroundColor(accent)
            }
            Text("Syncing catalog...")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.45, green: 0.48, blue: 0.62))
        }
    }
}

// MARK: - Empty State
private struct EmptyStateView: View {
    let onSync: () -> Void
    @State private var bounce = false
    private let accent = Color(red: 0.25, green: 0.40, blue: 0.95)

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.07))
                    .frame(width: 110, height: 110)
                Image(systemName: "cart.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accent, Color(red: 0.45, green: 0.65, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: bounce ? -5 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                            bounce = true
                        }
                    }
            }
            VStack(spacing: 6) {
                Text("No Products Yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.12, green: 0.14, blue: 0.28))
                Text("Tap Sync to fetch the product catalog from the server.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.50, green: 0.53, blue: 0.68))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button(action: onSync) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 13, weight: .bold))
                    Text("Sync Now").font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [accent, Color(red: 0.40, green: 0.60, blue: 1.0)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: accent.opacity(0.30), radius: 12, x: 0, y: 6)
            }
        }
    }
}

#Preview {
    ProductListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
