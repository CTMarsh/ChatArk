import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private var sharedItems: [SharePendingItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let conversations = ShareDataReader.conversations()

        let pickerView = SharePickerView(
            conversations: conversations,
            isStale: ShareDataReader.isDataStale(),
            onCancel: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onSend: { [weak self] conversation in
                self?.send(to: conversation)
            }
        )

        let hostingController = UIHostingController(rootView: pickerView)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        processSharedItems()
    }

    // MARK: - Process Shared Items

    private func processSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else { return }

        let group = DispatchGroup()

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    attachment.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                        defer { group.leave() }
                        if let url = data as? URL {
                            let fileName = url.lastPathComponent
                            if let imageData = try? Data(contentsOf: url) {
                                let shareId = UUID().uuidString
                                _ = ShareDataReader.saveFile(data: imageData, fileName: fileName, shareId: shareId)
                                self?.sharedItems.append(SharePendingItem(type: .image, text: nil, fileName: fileName))
                            }
                        } else if let imageData = data as? Data {
                            let fileName = "shared_image.jpg"
                            let shareId = UUID().uuidString
                            _ = ShareDataReader.saveFile(data: imageData, fileName: fileName, shareId: shareId)
                            self?.sharedItems.append(SharePendingItem(type: .image, text: nil, fileName: fileName))
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] data, _ in
                        defer { group.leave() }
                        if let url = data as? URL {
                            self?.sharedItems.append(SharePendingItem(type: .url, text: url.absoluteString, fileName: nil))
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    group.enter()
                    attachment.loadItem(forTypeIdentifier: UTType.text.identifier) { [weak self] data, _ in
                        defer { group.leave() }
                        if let text = data as? String {
                            self?.sharedItems.append(SharePendingItem(type: .text, text: text, fileName: nil))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Send

    private func send(to conversation: ShareConversationSummary) {
        let shareId = UUID().uuidString

        // If no items were processed, create a placeholder text item
        let items = sharedItems.isEmpty
            ? [SharePendingItem(type: .text, text: "Shared content", fileName: nil)]
            : sharedItems

        let pendingShare = SharePendingData(
            id: shareId,
            conversationId: conversation.id,
            conversationName: conversation.name,
            items: items,
            createdAt: Date()
        )

        ShareDataReader.writePendingShare(pendingShare)

        // Open main app to process the share
        let url = URL(string: "chatark://share/\(shareId)")!
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let application = nextResponder as? UIApplication {
                application.open(url)
                break
            }
            responder = nextResponder
        }

        extensionContext?.completeRequest(returningItems: nil)
    }
}
