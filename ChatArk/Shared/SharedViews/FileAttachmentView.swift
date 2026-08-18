import SwiftUI
import NukeUI

struct FileAttachmentView: View {
    let fileUrl: String
    let fileName: String?
    let fileSize: Int64?
    let fileType: String?
    let messageType: MessageType

    var body: some View {
        if fileUrl.hasPrefix("https://"), messageType == .image, let url = URL(string: fileUrl) {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if state.isLoading {
                    ProgressView()
                        .frame(width: 200, height: 150)
                } else {
                    fileFallback
                }
            }
            .frame(maxWidth: 280, maxHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            fileFallback
        }
    }

    private var fileFallback: some View {
        HStack(spacing: ConstellationSpacing.gapInline) {
            Image(systemName: fileIcon)
                .arkType(.lead)
                .foregroundStyle(ConstellationTheme.primary)
                .frame(width: 40, height: 40)
                .background(ConstellationTheme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                Text(fileName ?? "File")
                    .arkType(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let fileSize {
                    Text(FileValidator.formatFileSize(fileSize))
                        .arkType(.cap)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "arrow.down.circle")
                .arkType(.lead)
                .foregroundStyle(ConstellationTheme.primary)
        }
        .padding(ConstellationSpacing.gapInline)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: 280)
    }

    private var fileIcon: String {
        guard let fileType else { return "doc" }
        if fileType.hasPrefix("image/") { return "photo" }
        if fileType.hasPrefix("video/") { return "film" }
        if fileType.hasPrefix("audio/") { return "waveform" }
        if fileType.contains("pdf") { return "doc.richtext" }
        if fileType.contains("zip") || fileType.contains("archive") { return "archivebox" }
        return "doc"
    }
}

#if DEBUG
#Preview {
    FileAttachmentView(
        fileUrl: "https://example.com/report.pdf",
        fileName: "Q4 Report.pdf",
        fileSize: 1_500_000,
        fileType: "application/pdf",
        messageType: .file
    )
    .padding()
}
#endif
