import SwiftUI
import SwiftData
import CloudKit

@main
struct OpusMarinaApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RepertoirePiece.self,
            AudioRecording.self,
        ])

        // CloudKit container identifier must match the entitlements
        let cloudKitContainerID = "iCloud.com.joseespinosa.OpusMarina"

        #if targetEnvironment(simulator)
        // In simulator without an active Apple Developer team and logged-in iCloud account,
        // CloudKit triggers assertions in CKContainer. Use local disk storage directly.
        let primaryConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        #else
        let primaryConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(cloudKitContainerID)
        )
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [primaryConfig])
        } catch {
            print("⚠️ Primary ModelContainer failed: \(error.localizedDescription). Falling back to local disk storage.")
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                print("⚠️ Local disk ModelContainer failed (schema migration / corrupt store): \(error.localizedDescription). Falling back to in-memory storage.")
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                do {
                    return try ModelContainer(for: schema, configurations: [memoryConfig])
                } catch {
                    print("⚠️ In-memory ModelContainer failed: \(error.localizedDescription)")
                    return (try? ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]))
                        ?? (try! ModelContainer(for: schema))
                }
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
