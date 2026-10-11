import SwiftUI
import SwiftData
import CloudKit

@main
struct OpusMarinaApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RepertoirePiece.self,
        ])

        // CloudKit container identifier must match the entitlements
        let cloudKitContainerID = "iCloud.com.joseespinosa.OpusMarina"

        // Production: use CloudKit sync. Falls back gracefully if iCloud is unavailable.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(cloudKitContainerID)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // In development/simulator without a signed team, CloudKit may fail —
            // fall back to local-only storage so the app still runs.
            print("⚠️ CloudKit ModelContainer failed (\(error.localizedDescription)). Falling back to local storage.")
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
