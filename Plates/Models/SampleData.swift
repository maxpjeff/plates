import Foundation
import SwiftData

enum SampleData {
    @MainActor
    static func previewContainer() -> ModelContainer {
        let container = PlatesModelContainer.make(inMemory: true)
        let context = container.mainContext
        SeedDataService.importIfNeeded(context: context)
        try? context.save()
        return container
    }
}
