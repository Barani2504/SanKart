import SwiftUI

@main
struct SanKartApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ProductListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
