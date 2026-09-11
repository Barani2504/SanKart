import Foundation
import CoreData

extension CDProduct {
    public var wrappedId: String {
        id ?? UUID().uuidString
    }

    public var wrappedName: String {
        name ?? "Unknown Product"
    }

    public var wrappedCode: String {
        code ?? "-"
    }

    public var wrappedUnit: String {
        unit ?? "Unit"
    }

    public var subtotal: Double {
        rate * Double(quantity)
    }

    public var formattedRate: String {
        String(format: "₹%.2f", rate)
    }

    public var formattedSubtotal: String {
        String(format: "₹%.2f", subtotal)
    }

    public static func allProductsFetchRequest() -> NSFetchRequest<CDProduct> {
        let request: NSFetchRequest<CDProduct> = NSFetchRequest<CDProduct>(entityName: "CDProduct")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDProduct.name, ascending: true)]
        return request
    }
}
