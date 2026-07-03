import SwiftUI

struct CardListView: View {
    @EnvironmentObject private var catalog: StarCatalog
    @EnvironmentObject private var collection: CollectionStore
    @State private var showLockedMessage = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(catalog.featuredAsterisms()) { asterism in
                            if collection.isViewed(asterism.id) {
                                NavigationLink {
                                    CardDetailView(asterism: asterism)
                                } label: {
                                    card(asterism, locked: false)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    showLockedMessage = true
                                } label: {
                                    card(asterism, locked: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(18)

                    Text("已发现 \(collection.viewedCount())/8 个星宿")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "B8C4E0"))
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("星宿图鉴")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("先在星图中点击这个星宿吧！", isPresented: $showLockedMessage) {
                Button("知道了", role: .cancel) {}
            }
        }
    }

    private func card(_ asterism: Asterism, locked: Bool) -> some View {
        VStack(spacing: 8) {
            if locked {
                Text("?")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color(hex: "B8C4E0"))
                Text("去星图中找到它")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "B8C4E0"))
                    .multilineTextAlignment(.center)
            } else {
                PinyinLabel(chinese: asterism.name, pinyin: asterism.pinyin)
                Text(String(repeating: "★", count: max(1, min(3, asterism.difficulty ?? 1))))
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "FFD700"))
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(12)
        .background(
            locked
            ? Color(hex: "3A3A5C").opacity(0.72)
            : Color(hex: "1E2140").opacity(0.95)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
