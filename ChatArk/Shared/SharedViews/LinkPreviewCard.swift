import SwiftUI
import NukeUI

struct LinkPreviewCard: View {
    let preview: LinkPreview

    var body: some View {
        if let urlString = preview.url,
           let url = URL(string: urlString),
           url.scheme == "https" {
            Link(destination: url) {
                VStack(alignment: .leading, spacing: 0) {
                    if let imageUrl = preview.imageUrl,
                       let imgUrl = URL(string: imageUrl),
                       imgUrl.scheme == "https" {
                        LazyImage(url: imgUrl) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 150)
                        .clipped()
                    }

                    VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                        if let title = preview.title {
                            Text(title)
                                .arkType(.body)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .foregroundStyle(.primary)
                        }

                        if let description = preview.description {
                            Text(description)
                                .arkType(.cap)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Text(url.host ?? urlString)
                            .arkType(.cap)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(ConstellationSpacing.gapInline)
                }
                .background(Color.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(maxWidth: 280)
            }
        }
    }
}

#if DEBUG
#Preview {
    LinkPreviewCard(preview: PreviewData.sampleLinkPreview)
        .padding()
}
#endif
