import Foundation
import CoreData

extension CDOrder {
    public var wrappedId: UUID {
        id ?? UUID()
    }

    public var wrappedCreatedDate: Date {
        createdDate ?? Date()
    }

    public var wrappedRemarks: String {
        remarks ?? ""
    }

    public var formattedAmount: String {
        String(format: "₹%.2f", totalAmount)
    }

    public static func recentOrdersFetchRequest() -> NSFetchRequest<CDOrder> {
        let request: NSFetchRequest<CDOrder> = NSFetchRequest<CDOrder>(entityName: "CDOrder")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDOrder.createdDate, ascending: false)]
        return request
    }
}
