import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
public class ProductListViewModel: ObservableObject {
    @Published public var isLoading: Bool = false
    @Published public var isSaving: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var showErrorAlert: Bool = false
    
    // Remarks Alert state
    @Published public var showRemarksAlert: Bool = false
    @Published public var remarksText: String = ""

    // Success / info feedback
    @Published public var showSuccessToast: Bool = false
    @Published public var successToastMessage: String = ""
    @Published public var isToastError: Bool = false

    // Search filter
    @Published public var searchText: String = ""

    // Summary calculation
    @Published public var summary: CartSummary = CartSummary()

    private let repository: ProductRepositoryProtocol

    public init(repository: ProductRepositoryProtocol = ProductRepository.shared) {
        self.repository = repository
        self.refreshSummary()
    }

    // MARK: - Synchronization

    /// Called on first launch (empty catalog) — shows blocking alert on failure
    public func syncData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await repository.syncMasterData()
            refreshSummary()
        } catch {
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
        isLoading = false
    }

    /// Called by pull-to-refresh — shows a non-blocking toast on failure so the
    /// user isn't blocked by a modal alert when cached data is already visible.
    public func refreshData() async {
        isLoading = true
        do {
            try await repository.syncMasterData()
            refreshSummary()
            isToastError = false
            successToastMessage = "Catalog updated."
            showSuccessToast = true
        } catch {
            isToastError = true
            successToastMessage = "Refresh failed — check your connection."
            showSuccessToast = true
        }
        isLoading = false
    }

    // MARK: - Quantity Controls
    public func incrementQuantity(for product: CDProduct) {
        let newQty = product.quantity + 1
        setQuantity(for: product, to: newQty)
    }

    public func decrementQuantity(for product: CDProduct) {
        guard product.quantity > 0 else { return }
        let newQty = product.quantity - 1
        setQuantity(for: product, to: newQty)
    }

    public func setQuantity(for product: CDProduct, to newQty: Int32) {
        let clamped = max(0, min(newQty, 9999))
        product.quantity = clamped
        
        Task {
            try? await repository.updateProductQuantity(id: product.wrappedId, quantity: clamped)
            refreshSummary()
        }
    }

    public func refreshSummary() {
        self.summary = repository.calculateSummary()
    }

    // MARK: - Save Order Flow
    public func handleSaveButtonTap() {
        guard summary.hasItems else { return }
        remarksText = ""
        showRemarksAlert = true
    }

    public func submitOrderWithRemarks() async {
        isSaving = true
        do {
            let message = try await repository.submitOrder(remarks: remarksText.trimmingCharacters(in: .whitespacesAndNewlines))
            successToastMessage = message
            showSuccessToast = true
            refreshSummary()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isSaving = false
    }
}
