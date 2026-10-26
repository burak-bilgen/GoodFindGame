import SwiftUI

/// Personal identity belongs to this installation, independent of career/weekly saves and Game Center.
struct EditProfileView: View {
    let store: GameStore
    @AppStorage("playerDisplayName") private var savedName = ""
    @AppStorage("playerAvatar") private var savedAvatar = 0
    @AppStorage("playerTitle") private var savedTitle = -1
    @State private var name = ""
    @State private var avatar = 0
    @State private var title = -1
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    private var cleanName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var body: some View {
        GameForm {
            Section("profile.name") {
                TextField("profile.name", text: $name).textContentType(.nickname).submitLabel(.done).accessibilityIdentifier("playerName")
                    .onChange(of: name) { _, value in if value.count > 24 { name = String(value.prefix(24)) } }
            }
            Section("profile.avatar") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64))], spacing: 14) {
                    ForEach(0..<4) { value in
                        Button { avatar = value } label: {
                            TraderPortrait(identity: value, size: 56).padding(6)
                                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(avatar == value ? GameStyle.gain : .clear, lineWidth: 3))
                        }.buttonStyle(.plain).accessibilityLabel(Text(GameText.format("profile.avatarNumber", locale: locale, value + 1)))
                            .accessibilityAddTraits(avatar == value ? .isSelected : []).accessibilityIdentifier("playerAvatar.\(value)")
                    }
                }
            }
            Section("profile.displayTitle") {
                Picker("profile.displayTitle", selection: $title) {
                    Text("profile.noTitle").tag(-1)
                    ForEach(TraderTitle.earned(in: store.snapshot)) { earned in
                        Text(GameText.string(earned.key, locale: locale)).tag(earned.id)
                    }
                }.accessibilityIdentifier("displayTitle")
                Text("profile.identityHint").font(.caption).foregroundStyle(GameStyle.secondaryText)
            }
        }.gameScreen().navigationTitle("profile.edit").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("action.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save") {
                        savedName = cleanName; savedAvatar = avatar; savedTitle = title; dismiss()
                    }.disabled(cleanName.isEmpty || cleanName.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })).accessibilityIdentifier("saveProfile")
                }
            }
            .onAppear { name = savedName; avatar = min(3, max(0, savedAvatar)); title = TraderTitle.earned(in: store.snapshot).contains(where: { $0.id == savedTitle }) ? savedTitle : -1 }
    }
}
