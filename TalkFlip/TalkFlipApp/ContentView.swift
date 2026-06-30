import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = ContentStore()
    @StateObject private var stats = CardStatsStore()
    @State private var language: LanguageMode = .both
    @State private var players = 3
    @State private var selectedMode: GameMode = .classicFlip
    @State private var selectedDeck: Deck?
    @State private var session: GameSession?
    @State private var heroCardIndex = 0
    @State private var showFavorites = false

    private var ui: UIText { UIText(language: language) }

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    GameSessionView(session: session, stats: stats) {
                        self.session = nil
                    }
                } else {
                    setupView
                }
            }
            .navigationTitle("TalkFlip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if session == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showFavorites = true
                        } label: {
                            Label(ui.favorites, systemImage: stats.favoriteIDs.isEmpty ? "heart" : "heart.fill")
                        }
                        .accessibilityLabel(ui.favorites)
                    }
                }
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesView(store: store, stats: stats, language: language)
            }
        }
    }

    private var setupView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if let loadError = store.loadError {
                    errorView(loadError)
                } else {
                    heroCard
                    languagePicker
                    playerPicker
                    modePicker
                    deckPicker
                    startButton
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .onChange(of: selectedMode) {
            selectedDeck = firstPlayableDeck
        }
        .onChange(of: players) {
            if selectedDeckAvailability?.verdict.isPlayable != true {
                selectedDeck = firstPlayableDeck
            }
        }
        .onAppear {
            selectedDeck = firstPlayableDeck
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ui.heroTitle)
                .font(.system(size: 44, weight: .black))
                .lineLimit(2)
            Text(ui.heroSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var heroCard: some View {
        let cards = store.cards.filter { $0.cardType != .taboo }
        let card = cards.isEmpty ? nil : cards[heroCardIndex % cards.count]

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(ui.heroKicker)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Button(ui.shuffle) {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        heroCardIndex = Int.random(in: 0..<max(cards.count, 1))
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(.white)
            }

            Text(cardText(card))
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(4)
                .minimumScaleFactor(0.76)

            Text(ui.heroFooter)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.22, blue: 0.95), Color(red: 0.98, green: 0.22, blue: 0.46)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .bottomTrailing) {
            Text("FLIP")
                .font(.system(size: 54, weight: .black))
                .foregroundStyle(.white.opacity(0.12))
                .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.blue.opacity(0.22), radius: 22, x: 0, y: 14)
        .rotationEffect(.degrees(heroCardIndex.isMultiple(of: 2) ? -1.4 : 1.4))
    }

    private func cardText(_ card: TalkCard?) -> String {
        guard let card else {
            return ui.korean ? "누가 제일 먼저 분위기를 터뜨릴까?" : "Who breaks the ice first?"
        }
        switch language {
        case .ko: return card.ko
        case .en: return card.en
        case .both: return "\(card.ko)\n\(card.en)"
        }
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(ui.sectionLanguage)
            Picker(ui.sectionLanguage, selection: $language) {
                ForEach(LanguageMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var playerPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(ui.sectionPlayers)
            Stepper(value: $players, in: 1...8) {
                Text(ui.playersCount(players))
                    .font(.headline)
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(ui.sectionMode)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(GameMode.allCases) { mode in
                    Button {
                        Haptics.selection()
                        selectedMode = mode
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.title)
                                .font(.headline)
                            Text(mode.koTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(selectedMode == mode ? Color.accentColor.opacity(0.16) : Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMode == mode ? Color.accentColor : .clear, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var deckPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(ui.sectionDeck)
            ForEach(store.availability(for: selectedMode, players: players)) { item in
                deckRow(item)
            }
        }
    }

    private func deckRow(_ item: DeckAvailability) -> some View {
        let isSelected = selectedDeck?.id == item.deck.id
        let isPlayable = item.verdict.isPlayable

        return Button {
            guard isPlayable else { return }
            Haptics.selection()
            selectedDeck = item.deck
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(language == .en ? item.deck.name.en : item.deck.name.ko)
                            .font(.headline)
                        Text("\(item.cardCount)")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                    }
                    Text(language == .en ? item.deck.description.en : item.deck.description.ko)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if let label = item.verdict.label(korean: ui.korean) {
                    Text(label)
                        .font(.caption.bold())
                        .foregroundStyle(isPlayable ? Color.accentColor : .secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.16) : Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
            .opacity(isPlayable ? 1 : 0.45)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var startButton: some View {
        Button {
            guard let deck = selectedDeck else { return }
            let cards = store.cards(for: selectedMode, deck: deck, players: players)
            let isQuick = selectedDeckAvailability?.verdict == .quickRound
            Haptics.impact(.medium)
            session = GameSession(
                mode: selectedMode,
                deck: deck,
                language: language,
                players: players,
                cards: cards,
                isQuickRound: isQuick
            )
        } label: {
            Text(ui.start)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(selectedDeck == nil)
    }

    private var firstPlayableDeck: Deck? {
        store.availability(for: selectedMode, players: players)
            .first { $0.verdict.isPlayable }?
            .deck
    }

    private var selectedDeckAvailability: DeckAvailability? {
        guard let selectedDeck else { return nil }
        return store.availability(for: selectedMode, players: players)
            .first { $0.deck.id == selectedDeck.id }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }

    private func errorView(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.red)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct GameSessionView: View {
    @ObservedObject var session: GameSession
    @ObservedObject var stats: CardStatsStore
    let onExit: () -> Void
    @State private var flipDegrees = 0.0
    @State private var shareImage: UIImage?
    @State private var isShareSheetPresented = false
    @State private var lastShownCardID: String?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var ui: UIText { UIText(language: session.language) }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(ui.close, action: onExit)
                Spacer()
                if session.mode == .hotSeat {
                    Text(ui.turnLabel(session.hotSeatTurn))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                Text(session.progressText)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            if let card = session.currentCard {
                cardView(card)
                    .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
                    .animation(.spring(response: 0.36, dampingFraction: 0.72), value: flipDegrees)
                controls(for: card)
            } else {
                completeView
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color.accentColor.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onReceive(timer) { _ in
            session.tickTimer()
        }
        .onChange(of: session.tabooSecondsLeft) { _, newValue in
            if session.mode == .tabooRound, newValue == 0 {
                Haptics.notify(.warning)
            }
        }
        .onAppear {
            recordCurrentCardShown()
        }
        .onChange(of: session.currentIndex) {
            recordCurrentCardShown()
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let shareImage {
                ShareSheet(activityItems: [shareImage])
            }
        }
    }

    private func cardView(_ card: TalkCard) -> some View {
        VStack(spacing: 18) {
            HStack {
                Text(session.mode.title)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.78))
                    .textCase(.uppercase)
                Spacer()
                if session.mode == .tabooRound {
                    if session.tabooSecondsLeft == 0 {
                        Text(ui.timesUp)
                            .font(.headline.bold())
                            .foregroundStyle(.yellow)
                    } else {
                        Text("\(session.tabooSecondsLeft)s")
                            .font(.headline.bold())
                            .foregroundStyle(session.tabooSecondsLeft <= 5 ? .yellow : .white)
                            .monospacedDigit()
                    }
                }
            }

            VStack(spacing: 10) {
                if session.language != .en {
                    Text(card.ko)
                        .font(.system(size: session.language == .both ? 28 : 34, weight: .bold))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.75)
                }

                if session.language != .ko {
                    Text(card.en)
                        .font(.system(size: session.language == .both ? 20 : 32, weight: session.language == .both ? .semibold : .bold))
                        .foregroundStyle(session.language == .both ? .secondary : .primary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.75)
                }
            }

            if card.cardType == .taboo {
                tabooWords(card)
            }

            if session.showFollow, let follow = card.follow {
                Divider()
                Text(session.language == .en ? follow.en : follow.ko)
                    .font(.callout.bold())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 360)
        .background(cardGradient(for: card))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 14)
        .overlay(alignment: .bottomTrailing) {
            Text(card.cardType == .taboo ? "DON'T SAY IT" : "TALKFLIP")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white.opacity(0.10))
                .padding()
        }
        .accessibilityElement(children: .combine)
    }

    private func cardGradient(for card: TalkCard) -> LinearGradient {
        switch card.cardType {
        case .taboo:
            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .vote:
            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .choice:
            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .deepLight, .story:
            LinearGradient(colors: [.indigo, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .answer:
            LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func tabooWords(_ card: TalkCard) -> some View {
        let words = session.language == .en ? card.bannedEn : card.bannedKo

        return VStack(spacing: 8) {
            Text(ui.bannedWords)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.74))

            FlowLayout(items: words ?? []) { word in
                Text(word)
                    .font(.callout.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.20))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func controls(for card: TalkCard) -> some View {
        if session.mode == .tabooRound {
            VStack(spacing: 10) {
                cardActionRow(card)

                HStack {
                    scorePill(ui.scoreLabel, session.score, .green)
                    scorePill(ui.penaltyLabel, session.penalties, .red)
                }

                HStack {
                    Button(ui.caught) {
                        Haptics.notify(.error)
                        flipNext { session.addPenalty() }
                    }
                    .buttonStyle(.bordered)

                    Button(ui.cleared) {
                        Haptics.notify(.success)
                        flipNext { session.addPoint() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else {
            VStack(spacing: 10) {
                cardActionRow(card)

                if card.follow != nil {
                    Button(session.showFollow ? ui.hideFollow : ui.showFollow) {
                        session.showFollow.toggle()
                    }
                    .buttonStyle(.bordered)
                }

                HStack {
                    Button(ui.pass) {
                        Haptics.impact(.light)
                        stats.recordPassed(card.id)
                        flipNext {
                            session.pass()
                            recordCurrentCardShown()
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(ui.primaryAction(for: session.mode, hotSeatStep: session.answeredInHotSeat)) {
                        flipNext { session.next() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func cardActionRow(_ card: TalkCard) -> some View {
        HStack {
            Button {
                Haptics.selection()
                _ = stats.toggleFavorite(card.id)
            } label: {
                Label(stats.isFavorite(card.id) ? ui.saved : ui.save, systemImage: stats.isFavorite(card.id) ? "heart.fill" : "heart")
            }
            .buttonStyle(.bordered)

            Button {
                Haptics.impact(.light)
                renderShareImage(for: card)
            } label: {
                Label(ui.share, systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
        }
        .font(.caption.bold())
    }

    private func scorePill(_ title: String, _ value: Int, _ color: Color) -> some View {
        HStack {
            Text(title)
            Text("\(value)")
                .font(.headline.bold())
                .monospacedDigit()
        }
        .font(.caption.bold())
        .foregroundStyle(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func flipNext(_ action: @escaping () -> Void) {
        Haptics.impact(.rigid)
        withAnimation {
            flipDegrees += 92
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            action()
            withAnimation {
                flipDegrees += 88
            }
        }
    }

    private func recordCurrentCardShown() {
        guard let card = session.currentCard, lastShownCardID != card.id else { return }
        lastShownCardID = card.id
        stats.recordShown(card.id)
    }

    @MainActor
    private func renderShareImage(for card: TalkCard) {
        shareImage = makeShareImage(card: card, language: session.language, mode: session.mode)
        isShareSheetPresented = shareImage != nil
    }

    private var completeView: some View {
        VStack(spacing: 16) {
            Text(session.isQuickRound ? ui.roundComplete : ui.deckComplete)
                .font(.largeTitle.bold())
            Text(ui.completeSubtitle)
                .foregroundStyle(.secondary)

            Button(session.isQuickRound ? ui.playAnotherQuick : ui.playAgain) {
                Haptics.impact(.medium)
                session.restart()
            }
            .buttonStyle(.borderedProminent)
            .disabled(session.isQuickRound && !session.canPlayAnotherQuickRound)

            Button(ui.changeSetup, action: onExit)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Favorites

struct FavoritesView: View {
    @ObservedObject var store: ContentStore
    @ObservedObject var stats: CardStatsStore
    let language: LanguageMode

    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var isShareSheetPresented = false

    private var ui: UIText { UIText(language: language) }

    private var favoriteCards: [TalkCard] {
        store.cards.filter { stats.isFavorite($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteCards.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            ForEach(favoriteCards) { card in
                                favoriteRow(card)
                            }
                        }
                        insightsSection
                    }
                }
            }
            .navigationTitle(ui.favorites)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(ui.done) { dismiss() }
                }
            }
            .sheet(isPresented: $isShareSheetPresented) {
                if let shareImage {
                    ShareSheet(activityItems: [shareImage])
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.secondary)
            Text(ui.favoritesEmptyTitle)
                .font(.headline)
            Text(ui.favoritesEmptyBody)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func favoriteRow(_ card: TalkCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if language != .en {
                Text(card.ko).font(.headline)
            }
            if language != .ko {
                Text(card.en)
                    .font(language == .both ? .subheadline : .headline)
                    .foregroundStyle(language == .both ? .secondary : .primary)
            }

            HStack {
                Button {
                    Haptics.impact(.light)
                    let mode = GameMode.representative(for: card.cardType)
                    shareImage = makeShareImage(card: card, language: language, mode: mode)
                    isShareSheetPresented = shareImage != nil
                } label: {
                    Label(ui.share, systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .font(.caption.bold())

                Spacer()

                Button(role: .destructive) {
                    Haptics.selection()
                    _ = stats.toggleFavorite(card.id)
                } label: {
                    Label(ui.remove, systemImage: "heart.slash")
                }
                .buttonStyle(.bordered)
                .font(.caption.bold())
            }
        }
        .padding(.vertical, 4)
    }

    private var insightsSection: some View {
        Section(ui.insights) {
            let totals = aggregateStats()
            statRow(ui.statSeen, totals.shown)
            statRow(ui.statPassed, totals.passed)
            statRow(ui.statFavorited, stats.favoriteIDs.count)
        }
    }

    private func statRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .font(.headline.monospacedDigit())
        }
    }

    private func aggregateStats() -> (shown: Int, passed: Int) {
        var shown = 0
        var passed = 0
        for value in stats.stats.values {
            shown += value.shown
            passed += value.passed
        }
        return (shown, passed)
    }
}

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
            }
        }
    }
}

@MainActor
func makeShareImage(card: TalkCard, language: LanguageMode, mode: GameMode) -> UIImage? {
    let view = ShareCardSnapshot(card: card, language: language, mode: mode)
        .frame(width: 1080, height: 1600)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    return renderer.uiImage
}

struct ShareCardSnapshot: View {
    let card: TalkCard
    let language: LanguageMode
    let mode: GameMode

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 42) {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TalkFlip")
                            .font(.system(size: 54, weight: .black))
                        Text(mode.title.uppercased())
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    Text("FLIP")
                        .font(.system(size: 34, weight: .black))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.16))
                        .clipShape(Capsule())
                }

                Spacer()

                VStack(alignment: .leading, spacing: 28) {
                    if language != .en {
                        Text(card.ko)
                            .font(.system(size: 78, weight: .black))
                            .lineSpacing(5)
                            .minimumScaleFactor(0.56)
                    }

                    if language != .ko {
                        Text(card.en)
                            .font(.system(size: language == .both ? 50 : 76, weight: .black))
                            .lineSpacing(4)
                            .foregroundStyle(language == .both ? .white.opacity(0.82) : .white)
                            .minimumScaleFactor(0.56)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if card.cardType == .taboo {
                    bannedWords
                }

                Spacer()

                HStack {
                    Text(language == .en ? "Save this card. Ask your group." : "이 카드 저장. 같이 물어봐.")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                    Text("#TalkFlip")
                        .font(.system(size: 34, weight: .black))
                }
            }
            .foregroundStyle(.white)
            .padding(78)

            Text(card.cardType == .taboo ? "DON'T SAY IT" : "TALKFLIP")
                .font(.system(size: 132, weight: .black))
                .foregroundStyle(.white.opacity(0.08))
                .rotationEffect(.degrees(-12))
                .offset(x: 130, y: 420)
        }
    }

    private var gradientColors: [Color] {
        switch card.cardType {
        case .taboo: [.red, .orange]
        case .vote: [.purple, .pink]
        case .choice: [.blue, .cyan]
        case .deepLight, .story: [.indigo, .mint]
        case .answer: [.blue, .indigo]
        }
    }

    private var bannedWords: some View {
        let words = language == .en ? card.bannedEn : card.bannedKo

        return VStack(alignment: .leading, spacing: 16) {
            Text(language == .en ? "BANNED WORDS" : "금지어")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white.opacity(0.7))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 16)], alignment: .leading, spacing: 16) {
                ForEach(words ?? [], id: \.self) { word in
                    Text(word)
                        .font(.system(size: 32, weight: .black))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
