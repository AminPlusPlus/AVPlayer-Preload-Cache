import Foundation

struct VideoItem: Decodable, Identifiable {
    let id: UUID
    let name: String
    let thumbnailURL: String
    let videoURL: String
}

extension VideoItem {
    static func loadJson(filename fileName: String) -> [VideoItem]? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode([VideoItem].self, from: data)
                return jsonData
            } catch {
                Logger.logMessage("Error decoding JSON: \(error)", level: .error)
            }
        }
        return nil
    }
}
