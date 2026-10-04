import Foundation
import Observation

struct OpenOpusResponse: Decodable {
    let results: [OpenOpusResult]?
}

struct OpenOpusResult: Decodable, Identifiable {
    let work: OpenOpusWork?
    let composer: OpenOpusComposer?
    
    var id: String {
        return "\(work?.id ?? "")-\(composer?.id ?? "")"
    }
}

struct OpenOpusWork: Decodable {
    let title: String
    let subtitle: String?
    let id: String
}

struct OpenOpusComposer: Decodable {
    let complete_name: String
    let epoch: String?
    let id: String
    let name: String
}

@Observable
class OpenOpusService {
    var searchResults: [OpenOpusResult] = []
    var isSearching = false
    var errorMessage: String? = nil
    
    func search(query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else {
            DispatchQueue.main.async { self.searchResults = [] }
            return
        }
        
        guard let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.openopus.org/omnisearch/\(encodedQuery)/0.json") else {
            return
        }
        
        DispatchQueue.main.async {
            self.isSearching = true
            self.errorMessage = nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(OpenOpusResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.searchResults = response.results ?? []
                self.isSearching = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error al buscar: \(error.localizedDescription)"
                self.searchResults = []
                self.isSearching = false
            }
        }
    }
    
    static func mapEpochToMusicEra(epoch: String?) -> MusicEra {
        guard let epoch = epoch?.lowercased() else { return .contemporary }
        if epoch.contains("baroque") { return .baroque }
        if epoch.contains("classical") || epoch.contains("classic") { return .classical }
        if epoch.contains("romantic") { return .romantic }
        if epoch.contains("impressionist") || epoch.contains("impressionism") { return .impressionist }
        return .contemporary
    }
}
