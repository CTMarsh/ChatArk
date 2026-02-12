#if !os(watchOS)
import SwiftUI
import NukeUI

struct ImageViewer: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        scale = value.magnification
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            scale = max(1.0, scale)
                                        }
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            offset = value.translation
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            offset = .zero
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    scale = scale > 1.0 ? 1.0 : 2.0
                                    offset = .zero
                                }
                            }
                    } else if state.isLoading {
                        ProgressView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .background(.black)
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: url)
                        .tint(.white)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ImageViewer(url: URL(string: "https://picsum.photos/800/600")!)
}
#endif
#endif
