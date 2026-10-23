import SwiftUI

struct CollectionGalleryView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 7) {
                        GameEyebrow(key: "collections.eyebrow")
                        Text("collections.hero").font(.system(.title2, design: .serif, weight: .bold))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(GameStyle.amber).accessibilityHidden(true)
                }.gameCard(accent: GameStyle.amber)
                DisclosureGroup("collections.about") { Text("collections.intro").font(.subheadline).foregroundStyle(GameStyle.secondaryText) }
                ForEach(CollectionDefinition.all) { collection in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(GameText.string(collection.titleKey, locale: locale)).font(.system(.title2, design: .serif, weight: .bold))
                            Spacer(minLength: 0)
                            Text(verbatim: "\(collection.count(in: store.snapshot))/\(collection.models.count)").font(.title2.bold()).foregroundStyle(GameStyle.amber)
                        }
                        Text(GameText.string("collection.\(collection.id).story", locale: locale)).font(.subheadline).foregroundStyle(GameStyle.secondaryText)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 3), alignment: .leading, spacing: 10) {
                            ForEach(collection.models, id: \.self) { model in
                                if let definition = store.definitions.first(where: { $0.id == model }) {
                                    let item = collection.pieces(in: store.snapshot).first { $0.definitionID == model }
                                    VStack(alignment: .leading, spacing: 8) {
                                        ZStack {
                                            DeviceArt(symbol: definition.artSymbol, identity: model, appearance: item.map { .owned($0) })
                                                .saturation(item == nil ? 0 : 1).brightness(item == nil ? -0.20 : 0).opacity(item == nil ? 0.75 : 1)
                                            if item == nil {
                                                Image(systemName: "questionmark.diamond.fill").font(.title).foregroundStyle(GameStyle.amber).shadow(color: .black, radius: 5)
                                            }
                                        }.aspectRatio(1, contentMode: .fit)
                                        Text(definition.displayName(locale: locale)).font(.caption.bold()).fixedSize(horizontal: false, vertical: true)
                                        Text(item == nil ? "collections.missing" : "collections.owned").font(.caption2).foregroundStyle(item == nil ? .secondary : GameStyle.gain)
                                    }
                                }
                            }
                        }
                        ProgressView(value: Double(collection.count(in: store.snapshot)), total: Double(collection.models.count)).tint(GameStyle.amber)
                        if collection.count(in: store.snapshot) == collection.models.count {
                            Label("collections.complete", systemImage: "seal.fill").font(.headline).foregroundStyle(GameStyle.amber)
                        } else if store.snapshot.collections.completedBefore.contains(collection.id) {
                            Label("collections.completedBefore", systemImage: "seal").font(.caption).foregroundStyle(GameStyle.secondaryText)
                        }
                        if store.snapshot.collections.focus == collection.id {
                            Label("collections.focused", systemImage: "bookmark.fill").font(.caption.bold()).foregroundStyle(GameStyle.gain)
                        } else {
                            Button("collections.focus") { store.perform { try store.focusCollection(collection.id); GameFeel.play(.submitted) } }
                                .buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("focusCollection.\(collection.id)")
                        }
                        ForEach(store.snapshot.player.inventory.filter { collection.models.contains($0.definitionID) && $0.inspected }) { item in
                            if let definition = store.definition(for: item) { Text(definition.displayName(locale: locale)).font(.subheadline.bold()) }
                            Button(store.snapshot.collections.displayed.contains(item.id) ? "collections.release" : "collections.display") {
                                store.perform { let previous = store.snapshot.collections.completedBefore.count; try store.toggleDisplay(item.id); GameFeel.play(store.snapshot.collections.completedBefore.count > previous ? .profit : .reveal) }
                            }.buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("displayCollection.\(item.id.rawValue)")
                        }
                    }.gameCard(accent: GameStyle.amber)
                }
            }.padding(16)
        }.gameScreen().navigationTitle("collections.title").navigationBarTitleDisplayMode(.inline)
    }
}
