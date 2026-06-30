import Foundation
import Combine

final class GameSession: ObservableObject {
    let mode: GameMode
    let deck: Deck
    let language: LanguageMode
    let players: Int
    let isQuickRound: Bool

    private let quickRoundSize = 5
    private var allCards: [TalkCard]
    private var dealOffset = 0

    @Published private(set) var cards: [TalkCard]
    @Published private(set) var currentIndex = 0
    @Published private(set) var shownCount = 0
    @Published private(set) var answeredInHotSeat = 0
    @Published private(set) var hotSeatTurn = 1
    @Published private(set) var score = 0
    @Published private(set) var penalties = 0
    @Published var tabooSecondsLeft = 30
    @Published var showFollow = false

    init(mode: GameMode, deck: Deck, language: LanguageMode, players: Int, cards: [TalkCard], isQuickRound: Bool = false) {
        self.mode = mode
        self.deck = deck
        self.language = language
        self.players = players
        self.isQuickRound = isQuickRound
        self.allCards = cards.shuffled()

        if isQuickRound {
            let slice = allCards.prefix(quickRoundSize)
            self.cards = Array(slice)
            self.dealOffset = self.cards.count
        } else {
            self.cards = allCards
        }
    }

    var currentCard: TalkCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var isComplete: Bool {
        currentCard == nil
    }

    /// In a Quick Round, more cards are available to deal into a fresh 5-card round.
    var canPlayAnotherQuickRound: Bool {
        isQuickRound && allCards.count > quickRoundSize
    }

    var progressText: String {
        "\(min(currentIndex + 1, cards.count)) / \(cards.count)"
    }

    func next() {
        showFollow = false
        resetTabooTimer()
        shownCount += 1
        currentIndex += 1

        if mode == .hotSeat {
            answeredInHotSeat += 1
            if answeredInHotSeat >= 2 {
                // Hot Seat draws 3 per turn, answers 2; the unanswered 3rd
                // goes to the back of the session instead of being consumed.
                answeredInHotSeat = 0
                hotSeatTurn += 1
                deferCurrentCardToBack()
            }
        }
    }

    func pass() {
        showFollow = false
        resetTabooTimer()
        deferCurrentCardToBack()
    }

    /// Moves the card at the current index to the back of the active session.
    private func deferCurrentCardToBack() {
        guard currentIndex < cards.count else { return }
        let card = cards.remove(at: currentIndex)
        cards.append(card)
    }

    func tickTimer() {
        guard mode == .tabooRound, tabooSecondsLeft > 0 else { return }
        tabooSecondsLeft -= 1
    }

    func addPoint() {
        score += 1
        next()
    }

    func addPenalty() {
        penalties += 1
        next()
    }

    func restart() {
        if isQuickRound {
            if dealOffset >= allCards.count {
                allCards.shuffle()
                dealOffset = 0
            }
            let end = min(dealOffset + quickRoundSize, allCards.count)
            cards = Array(allCards[dealOffset..<end])
            dealOffset = end
        } else {
            allCards.shuffle()
            cards = allCards
        }

        currentIndex = 0
        shownCount = 0
        answeredInHotSeat = 0
        hotSeatTurn = 1
        score = 0
        penalties = 0
        tabooSecondsLeft = 30
        showFollow = false
    }

    private func resetTabooTimer() {
        if mode == .tabooRound {
            tabooSecondsLeft = 30
        }
    }
}
