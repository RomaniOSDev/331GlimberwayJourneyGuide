import SwiftUI

struct TravelTextField: View {
    let title: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil
    var submitLabel: SubmitLabel = .done

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))

            Group {
                if axis == .vertical {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(title).foregroundColor(Color("AppTextPlaceholder")),
                        axis: .vertical
                    )
                    .lineLimit(lineLimit ?? 2...5)
                } else {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(title).foregroundColor(Color("AppTextPlaceholder"))
                    )
                }
            }
            .foregroundStyle(Color("AppTextPrimary"))
            .tint(Color("AppAccent"))
            .submitLabel(submitLabel)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color("AppBackground").opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            )
        }
    }
}

struct TravelSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppTextSecondary"))
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundColor(Color("AppTextPlaceholder"))
            )
            .foregroundStyle(Color("AppTextPrimary"))
            .tint(Color("AppAccent"))
            .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .travelCard()
    }
}
