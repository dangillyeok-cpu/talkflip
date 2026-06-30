import Foundation
import Combine

struct CardStats: Codable, Equatable {
    var shown: Int = 0
    var passed: Int = 0
    var favorited: Int = 0
}

final class CardStatsStore: ObservableObject {
    @Published private(set) var stats: [String: CardStats] = [:]
    @Published private(set) var favoriteIDs: Set<String> = []

    private let statsKey = "talkflip.cardStats.v1"
    private let favoritesKey = "talkflip.favoriteIDs.v1"

    init() {
        load()
    }

    func recordShown(_ cardID: String) {
        stats[cardID, default: CardStats()].shown += 1
        saveStats()
    }

    func recordPassed(_ cardID: String) {
        stats[cardID, default: CardStats()].passed += 1
        saveStats()
    }

    @discardableResult
    func toggleFavorite(_ cardID: String) -> Bool {
        if favoriteIDs.contains(cardID) {
            favoriteIDs.remove(cardID)
            saveFavorites()
            return false
        } else {
            favoriteIDs.insert(cardID)
            stats[cardID, default: CardStats()].favorited += 1
            saveStats()
            saveFavorites()
            return true
        }
    }

    func isFavorite(_ cardID: String) -> Bool {
        favoriteIDs.contains(cardID)
    }

    private func load() {
        let decoder = JSONDecoder()

        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decodedStats = try? decoder.decode([String: CardStats].self, from: data) {
            stats = decodedStats
        }

        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decodedFavorites = try? decoder.decode(Set<String>.self, from: data) {
            favoriteIDs = decodedFavorites
        }
    }

    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: statsKey)
        }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteIDs) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
}
