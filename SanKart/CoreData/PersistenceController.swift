import CoreData

public struct PersistenceController {
    public static let shared = PersistenceController()

    public static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Sample mock data for SwiftUI canvas previews
        let sample1 = CDProduct(context: viewContext)
        sample1.id = "SJQA13607"
        sample1.name = "CAMPA 1"
        sample1.code = "636"
        sample1.productDescription = "COOL DRINKS"
        sample1.unit = "EA"
        sample1.rate = 10.0
        sample1.quantity = 2
        sample1.lastUpdated = Date()

        let sample2 = CDProduct(context: viewContext)
        sample2.id = "SJQA13608"
        sample2.name = "CAMPA 2"
        sample2.code = "637"
        sample2.productDescription = "COOL DRINKS"
        sample2.unit = "EA"
        sample2.rate = 15.5
        sample2.quantity = 0
        sample2.lastUpdated = Date()

        let sample3 = CDProduct(context: viewContext)
        sample3.id = "SJQA13609"
        sample3.name = "ORANGE DELIGHT"
        sample3.code = "638"
        sample3.productDescription = "CITRUS SODA"
        sample3.unit = "Box"
        sample3.rate = 24.0
        sample3.quantity = 5
        sample3.lastUpdated = Date()

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SanKart")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, handle appropriately
                print("Core Data load store failure: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Saves the given managed object context if changes are present
    public func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved Core Data error \(nsError), \(nsError.userInfo)")
        }
    }
}
