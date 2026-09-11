import Foundation

public struct CartSummary: Equatable {
    public let totalItems: Int
    public let totalQty: Int
    public let totalAmount: Double

    public init(totalItems: Int = 0, totalQty: Int = 0, totalAmount: Double = 0.0) {
        self.totalItems = totalItems
        self.totalQty = totalQty
        self.totalAmount = totalAmount
    }

    public var formattedAmount: String {
        String(format: "₹%.2f", totalAmount)
    }

    public var hasItems: Bool {
        totalQty > 0
    }
}
