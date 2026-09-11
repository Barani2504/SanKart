import Foundation
import CoreData

public protocol ProductRepositoryProtocol {
    func syncMasterData() async throws
    func updateProductQuantity(id: String, quantity: Int32) async throws
    func submitOrder(remarks: String) async throws -> String
    func calculateSummary() -> CartSummary
}

public class ProductRepository: ProductRepositoryProtocol {
    public static let shared = ProductRepository()

    private let persistenceController: PersistenceController
    private let networkService: NetworkServiceProtocol

    public init(
        persistenceController: PersistenceController = .shared,
        networkService: NetworkServiceProtocol = NetworkService.shared
    ) {
        self.persistenceController = persistenceController
        self.networkService = networkService
    }

    // MARK: - Master Sync Engine (API 2 + API 3 -> Core Data)
    public func syncMasterData() async throws {
        // Concurrently fetch Products and Rates
        async let productsTask = networkService.fetchProducts()
        async let ratesTask = networkService.fetchRates()

        let (products, rates) = try await (productsTask, ratesTask)

        // Index rates by Product_Detail_Code for O(1) lookup
        var rateMap = [String: Double]()
        for rate in rates {
            rateMap[rate.Product_Detail_Code] = rate.parsedRate
        }

        // Perform upsert on background Core Data context to keep UI smooth
        let backgroundContext = persistenceController.container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await backgroundContext.perform {
            // Fetch existing products into dictionary to preserve user entered quantity
            let request: NSFetchRequest<CDProduct> = CDProduct.fetchRequest() as! NSFetchRequest<CDProduct>
            let existingProducts = (try? backgroundContext.fetch(request)) ?? []
            var existingMap = [String: CDProduct]()
            for item in existingProducts {
                if let id = item.id {
                    existingMap[id] = item
                }
            }

            for prod in products {
                let entity = existingMap[prod.id] ?? CDProduct(context: backgroundContext)
                entity.id = prod.id
                entity.name = prod.name.trimmingCharacters(in: .whitespacesAndNewlines)
                entity.code = prod.Code
                entity.productDescription = prod.Product_Description
                entity.unit = prod.product_unit
                entity.rate = rateMap[prod.id] ?? 0.0
                entity.lastUpdated = Date()
                // If new product, quantity defaults to 0; if existing, preserved
            }

            if backgroundContext.hasChanges {
                try backgroundContext.save()
            }
        }
    }

    // MARK: - Local Quantity Updates
    public func updateProductQuantity(id: String, quantity: Int32) async throws {
        let viewContext = persistenceController.container.viewContext
        let request: NSFetchRequest<CDProduct> = CDProduct.fetchRequest() as! NSFetchRequest<CDProduct>
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        try await viewContext.perform {
            let results = try viewContext.fetch(request)
            if let product = results.first {
                product.quantity = max(0, quantity)
                self.persistenceController.save(context: viewContext)
            }
        }
    }

    // MARK: - Cart Calculations
    public func calculateSummary() -> CartSummary {
        let viewContext = persistenceController.container.viewContext
        let request: NSFetchRequest<CDProduct> = CDProduct.fetchRequest() as! NSFetchRequest<CDProduct>
        request.predicate = NSPredicate(format: "quantity > 0")

        guard let activeProducts = try? viewContext.fetch(request) else {
            return CartSummary()
        }

        let totalItems = activeProducts.count
        let totalQty = activeProducts.reduce(0) { $0 + Int($1.quantity) }
        let totalAmount = activeProducts.reduce(0.0) { $0 + ($1.rate * Double($1.quantity)) }

        return CartSummary(totalItems: totalItems, totalQty: totalQty, totalAmount: totalAmount)
    }

    // MARK: - API 4: Submit Order Flow
    public func submitOrder(remarks: String) async throws -> String {
        let viewContext = persistenceController.container.viewContext
        let request: NSFetchRequest<CDProduct> = CDProduct.fetchRequest() as! NSFetchRequest<CDProduct>
        request.predicate = NSPredicate(format: "quantity > 0")

        // Build payload on the main thread (viewContext is main-thread-only)
        let (payload, activeProducts) = try await viewContext.perform {
            let activeProducts = try viewContext.fetch(request)
            guard !activeProducts.isEmpty else {
                throw NSError(domain: "ProductRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cart is empty."])
            }

            let totalItems = activeProducts.count
            let totalQty = activeProducts.reduce(0) { $0 + Int($1.quantity) }
            let totalAmount = activeProducts.reduce(0.0) { $0 + ($1.rate * Double($1.quantity)) }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = formatter.string(from: Date())

            let productDetails = activeProducts.map { prod in
                SaveOrderPayload.SaveProductDetail(
                    product_Code: prod.wrappedId,
                    product_Name: prod.wrappedName,
                    qty: "\(prod.quantity)",
                    value: String(format: "%.0f", prod.subtotal)
                )
            }

            let payload = SaveOrderPayload(
                userName: self.networkService.currentUsername,
                createdDate: dateString,
                totalItems: "\(totalItems)",
                totalQty: "\(totalQty)",
                totalAmount: totalAmount,
                remarks: remarks,
                productDetails: productDetails
            )
            return (payload, activeProducts)
        }

        // Submit via API 4 (off main thread is fine here)
        let response = try await networkService.saveOrder(payload: payload)

        // Persist local order history back on main thread
        try await viewContext.perform {
            let cdOrder = CDOrder(context: viewContext)
            cdOrder.id = UUID()
            cdOrder.createdDate = Date()
            cdOrder.totalItems = Int32(Int(payload.totalItems) ?? 0)
            cdOrder.totalQty = Int32(Int(payload.totalQty) ?? 0)
            cdOrder.totalAmount = payload.totalAmount
            cdOrder.remarks = remarks
            cdOrder.isSynced = (response.status == true)

            // Clear active quantities in Cart
            for prod in activeProducts {
                prod.quantity = 0
            }
            self.persistenceController.save(context: viewContext)
        }

        return response.message ?? "Order saved successfully."
    }
}
