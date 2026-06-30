import Foundation
import UIKit

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case classicFlip = "classic_flip"
    case thisOrThat = "this_or_that"
    case whosMostLikely = "whos_most_likely"
    case hotSeat = "hot_seat"
    case tabooRound = "taboo_round"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicFlip: "Classic Flip"
        case .thisOrThat: "This or That"
        case .whosMostLikely: "Who's Most Likely"
        case .hotSeat: "Hot Seat"
        case .tabooRound: "Taboo Round"
        }
    }

    var koTitle: String {
        switch self {
        case .classicFlip: "클래식"
        case .thisOrThat: "밸런스"
        case .whosMostLikely: "누가 제일"
        case .hotSeat: "핫시트"
        case .tabooRound: "금지어"
        }
    }

    /// A representative mode for a card type, used when sharing a card outside an
    /// active session (e.g. from the Favorites screen).
    static func representative(for type: CardType) -> GameMode {
        switch type {
        case .taboo: .tabooRound
        case .vote: .whosMostLikely
        case .choice: .thisOrThat
        case .answer, .story, .deepLight: .classicFlip
        }
    }
}

enum CardType: String, Codable {
    case answer
    case choice
    case vote
    case story
    case deepLight = "deep_light"
    case taboo
}

enum LanguageMode: String, CaseIterable, Identifiable {
    case ko
    case en
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ko: "KR"
        case .en: "EN"
        case .both: "KR + EN"
        }
    }
}

struct CardsFile: Decodable {
    let version: String
    let cards: [TalkCard]
}

struct DecksFile: Decodable {
    let version: String
    let decks: [Deck]
}

struct LocalizedName: Decodable {
    let en: String
    let ko: String
}

struct Deck: Decodable, Identifiable {
    let id: String
    let name: LocalizedName
    let description: LocalizedName
    let minPlayers: Int?
    let maxPlayers: Int?
}

struct FollowText: Decodable {
    let en: String
    let ko: String
}

struct TalkCard: Decodable, Identifiable {
    let id: String
    let deck: String
    let cardType: CardType
    let modes: [String]
    let minPlayers: Int?
    let maxPlayers: Int?
    let tone: String?
    let en: String
    let ko: String
    let follow: FollowText?
    let bannedEn: [String]?
    let bannedKo: [String]?
}

struct DeckAvailability: Identifiable {
    let deck: Deck
    let cardCount: Int
    let verdict: AvailabilityVerdict

    var id: String { deck.id }
}

enum AvailabilityVerdict: Equatable {
    case normal
    case smallDeck
    case quickRound
    case shortRound
    case disabled(DisabledReason)

    enum DisabledReason: Equatable {
        case coupleOnly
        case needThreePlus
        case notEnoughCards
    }

    var isPlayable: Bool {
        switch self {
        case .normal, .smallDeck, .quickRound, .shortRound: true
        case .disabled: false
        }
    }

    func label(korean: Bool) -> String? {
        switch self {
        case .normal:
            return nil
        case .smallDeck:
            return korean ? "카드가 적은 덱" : "Small deck"
        case .quickRound:
            return korean ? "짧은 라운드" : "Quick Round"
        case .shortRound:
            return korean ? "짧은 라운드" : "Short round"
        case .disabled(let reason):
            switch reason {
            case .coupleOnly: return korean ? "2명 전용" : "2 players only"
            case .needThreePlus: return korean ? "3명 이상" : "3+ players"
            case .notEnoughCards: return korean ? "카드 부족" : "Not enough cards"
            }
        }
    }
}

// MARK: - UI Localization

/// Localized chrome strings for the UI. The app is Korean-first, so the combined
/// `KR + EN` mode also uses Korean for buttons and labels; only the explicit
/// English display mode switches the UI to English.
struct UIText {
    let language: LanguageMode
    private var ko: Bool { language != .en }

    var korean: Bool { ko }

    // Setup screen
    var heroTitle: String { ko ? "방을 뒤집어 봐." : "Flip the room." }
    var heroSubtitle: String { ko ? "한 장 넘기면 바로 리액션이 나오는 대화 게임." : "Flip a card and the reactions start." }
    var heroKicker: String { ko ? "오늘 한 장만 뽑는다면" : "If you flip just one" }
    var heroFooter: String { ko ? "시작을 눌러봐. 안 맞으면 패스. 리액션은 계속." : "Tap Start. Pass if it misses. Keep the reactions." }
    var shuffle: String { ko ? "셔플" : "Shuffle" }
    var sectionLanguage: String { ko ? "언어" : "Language" }
    var sectionPlayers: String { ko ? "인원" : "Players" }
    var sectionMode: String { ko ? "모드" : "Mode" }
    var sectionDeck: String { ko ? "덱" : "Deck" }
    var start: String { ko ? "시작" : "Start" }
    var favorites: String { ko ? "즐겨찾기" : "Favorites" }
    func playersCount(_ n: Int) -> String { ko ? "\(n)명" : "\(n) players" }

    // Session screen
    var close: String { ko ? "닫기" : "Close" }
    var pass: String { ko ? "패스" : "Pass" }
    var showFollow: String { ko ? "추가 질문 보기" : "Show follow-up" }
    var hideFollow: String { ko ? "추가 질문 숨기기" : "Hide follow-up" }
    var save: String { ko ? "저장" : "Save" }
    var saved: String { ko ? "저장됨" : "Saved" }
    var share: String { ko ? "공유" : "Share" }
    var scoreLabel: String { ko ? "점수" : "Score" }
    var penaltyLabel: String { ko ? "벌점" : "Penalty" }
    var caught: String { ko ? "걸림" : "Caught" }
    var cleared: String { ko ? "통과" : "Cleared" }
    var bannedWords: String { ko ? "금지어" : "Banned words" }
    var timesUp: String { ko ? "시간 종료" : "Time's up" }
    func turnLabel(_ n: Int) -> String { ko ? "\(n)번째 턴" : "Turn \(n)" }

    // Completion
    var deckComplete: String { ko ? "덱 완료" : "Deck complete" }
    var roundComplete: String { ko ? "라운드 완료" : "Round complete" }
    var completeSubtitle: String { ko ? "카드를 다 봤어요." : "You've seen all the cards." }
    var playAgain: String { ko ? "다시 하기" : "Play again" }
    var playAnotherQuick: String { ko ? "짧은 라운드 한 번 더" : "Play another quick round" }
    var changeSetup: String { ko ? "설정 바꾸기" : "Change setup" }

    // Favorites screen
    var favoritesEmptyTitle: String { ko ? "아직 저장한 카드가 없어요" : "No saved cards yet" }
    var favoritesEmptyBody: String { ko ? "게임 중 마음에 드는 카드를 하트로 저장해 보세요." : "Tap the heart on a card you like during a game." }
    var insights: String { ko ? "카드 통계" : "Card insights" }
    var statSeen: String { ko ? "표시" : "Shown" }
    var statPassed: String { ko ? "패스" : "Passed" }
    var statFavorited: String { ko ? "저장됨" : "Saved" }
    var done: String { ko ? "완료" : "Done" }
    var remove: String { ko ? "삭제" : "Remove" }

    func primaryAction(for mode: GameMode, hotSeatStep: Int) -> String {
        switch mode {
        case .thisOrThat: return ko ? "다음 선택" : "Next pick"
        case .whosMostLikely: return ko ? "다음 투표" : "Next vote"
        case .tabooRound: return ko ? "다음 주제" : "Next topic"
        case .hotSeat:
            let label = hotSeatStep == 1 ? "2/2" : "1/2"
            return ko ? "답변 \(label)" : "Answer \(label)"
        case .classicFlip: return ko ? "다음 카드" : "Next card"
        }
    }
}

// MARK: - Haptics

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
