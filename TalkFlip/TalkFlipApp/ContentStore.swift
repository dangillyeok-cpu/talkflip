import Foundation
import Combine

final class ContentStore: ObservableObject {
    @Published private(set) var cards: [TalkCard] = []
    @Published private(set) var decks: [Deck] = []
    @Published private(set) var loadError: String?

    init() {
        load()
    }

    func load() {
        do {
            let cardsFile: CardsFile = try Bundle.main.decode("cards.json")
            let decksFile: DecksFile = try Bundle.main.decode("decks.json")
            cards = cardsFile.cards
            decks = decksFile.decks
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    func cards(for mode: GameMode, deck: Deck, players: Int) -> [TalkCard] {
        cards.filter { card in
            card.deck == deck.id &&
            card.modes.contains(mode.rawValue) &&
            resolvedPlayerRange(for: card, deck: deck).contains(players)
        }
    }

    func availability(for mode: GameMode, players: Int) -> [DeckAvailability] {
        decks.map { deck in
            let pool = cards(for: mode, deck: deck, players: players)
            return DeckAvailability(
                deck: deck,
                cardCount: pool.count,
                verdict: verdict(for: mode, count: pool.count, deck: deck, players: players)
            )
        }
    }

    private func verdict(for mode: GameMode, count: Int, deck: Deck, players: Int) -> AvailabilityVerdict {
        if deck.id == "couple", players != 2 {
            return .disabled(.coupleOnly)
        }

        if mode == .whosMostLikely || mode == .tabooRound, players < 3 {
            return .disabled(.needThreePlus)
        }

        switch mode {
        case .hotSeat:
            if count >= 18 { return .normal }
            if count >= 12 { return .shortRound }
            return .disabled(.notEnoughCards)
        case .thisOrThat:
            if count >= 8 { return .normal }
            if count >= 5 { return .quickRound }
            return .disabled(.notEnoughCards)
        case .classicFlip, .whosMostLikely, .tabooRound:
            if count >= 8 { return .normal }
            if count >= 6 { return .smallDeck }
            return .disabled(.notEnoughCards)
        }
    }

    private func resolvedPlayerRange(for card: TalkCard, deck: Deck) -> ClosedRange<Int> {
        let typeDefault = defaultPlayerRange(for: card.cardType)
        let minPlayers = max(card.minPlayers ?? typeDefault.lowerBound, deck.minPlayers ?? 1)
        let maxPlayers = min(card.maxPlayers ?? typeDefault.upperBound, deck.maxPlayers ?? 8)
        return minPlayers...maxPlayers
    }

    private func defaultPlayerRange(for type: CardType) -> ClosedRange<Int> {
        switch type {
        case .vote, .taboo: 3...8
        case .answer, .choice, .story, .deepLight: 1...8
        }
    }
}

private extension Bundle {
    func decode<T: Decodable>(_ fileName: String) throws -> T {
        guard let url = url(forResource: fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
