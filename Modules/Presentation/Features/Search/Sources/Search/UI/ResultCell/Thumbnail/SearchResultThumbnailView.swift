import MEGADesignToken
import MEGASwiftUI
import SwiftUI

// ┌─────────────────────────────────────────────────────────────────────────────────────┐
// │┌─────────────────────────────────────────────────┐                                  │
// ││                       .secondary(.trailingEdge) │                                  │
// │╠─────────────────────────────────────────────────╣                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                  Icon/Preview                   ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║                                                 ║                                  │
// │║─────────────────────┐                           ║                                  │
// │║ .secondary(.leading)│                           ║                                  │
// │╚═════════════════════════════════════════════════╝                                  │
// │┌─────────────────────┐╔══════════════════════╗┌─────────────────────┐ ┌ ─ ─ ─ ─ ─ ┐ │
// ││.prominent(.leading) │║       [TITLE]        ║│.prominent(.trailing │               │
// │└─────────────────────┘╚══════════════════════╝└─────────────────────┘ │   Menu    │ │
// │╔═══════════════╗ ┌─────────────────┐                                     Select     │
// │║  [SUBTITLE]   ║ │.secondary(.trail│                                  │           │ │
// │╚═══════════════╝ └─────────────────┘                                   ─ ─ ─ ─ ─ ─  │
// └─────────────────────────────────────────────────────────────────────────────────────┘
// The Menu Select (More button or select button) is not affected by the sensitive property (.sensitive modifier)

struct SearchResultThumbnailView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewModel: SearchResultRowViewModel
    @Binding var selected: Set<ResultId>
    @Binding var selectionEnabled: Bool
    
    private let layout: ResultCellLayout = .thumbnail
    
    var body: some View {
        VStack(spacing: .zero) {
            topInfoView
            bottomInfoView
        }
        .frame(height: 214)
        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: TokenRadius.small)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipped()
    }
    
    var isSelected: Bool {
        selected.contains(viewModel.result.id)
    }
    
    private var topInfoView: some View {
        BackgroundView(
            image: viewModel.thumbnailImage,
            isThumbnailLoaded: viewModel.isThumbnailLoadedOnce,
            mode: viewModel.result.backgroundDisplayMode,
            backgroundColor: thumbnailBackgroundColor,
            header: backgroundHeader,
            footer: backgroundFooter,
            isSensitive: viewModel.isSensitive
        )
        .sensitive(viewModel.isSensitive ? .opacity : .none)
        .clipped()
    }
    
    // hosts .secondary(.trailingEdge) properties
    private var backgroundHeader: some View {
        HStack {
            Spacer()
            HStack(spacing: 4) {
                viewModel
                    .result
                    .properties
                    .propertyViewsFor(
                        layout: layout,
                        placement: .secondary(.trailingEdge),
                        colorAssets: viewModel.colorAssets
                    )
            }
            .padding(.vertical, 4)
        }
        .frame(height: 24)
        .padding(.trailing, 5)
        .background(
            hasTopHeaderIcons ? topNodeIconsBackgroundColor : .clear
        )
    }
    
    var hasTopHeaderIcons: Bool {
        viewModel
            .result
            .properties
            .propertiesFor(
                mode: layout,
                placement: .secondary(.trailingEdge)
            ).isNotEmpty
    }
    
    // hosts .secondary(.leading) properties
    // in practice currently play icon and duration
    private var backgroundFooter: some View {
        HStack(spacing: 1) {
            let placement = PropertyPlacement.secondary(.leading)
            ForEach(viewModel.result.properties.propertiesFor(mode: layout, placement: placement) ) { property in
                switch property.content {
                case .icon(image: let image, scalable: let scalable):
                    property.resultPropertyImage(image: image, scalable: scalable, colorAssets: viewModel.colorAssets, placement: placement)
                        .frame(width: 16, height: 16)
                        .padding(2)
                case .text(let text):
                    Text(text)
                        .padding(2)
                        .font(.caption)
                        .foregroundColor(viewModel.colorAssets.verticalThumbnailFooterText)
                        .background(viewModel.colorAssets.verticalThumbnailFooterBackground)
                        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
                case .spacer:
                    Spacer()
                }
            }
            Spacer()
        }
        .padding(.leading, 3)
        .padding(.trailing, 8)
        .padding(.bottom, 3)
    }
    
    private var bottomInfoView: some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: .zero) {
                topLine
                bottomLine
            }.sensitive(viewModel.isSensitive ? .opacity : .none)
            
            Spacer()
            trailingView
                .frame(
                    width: 40,
                    height: 40
                )
        }
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder var trailingView: some View {
        if selectionEnabled {
            selectionIcon
        } else {
            moreButton
        }
    }
    
    @ViewBuilder var selectionIcon: some View {
        Image(
            uiImage: isSelected ?
            viewModel.selectedCheckmarkImage :
                viewModel.unselectedCheckmarkImage
        )
        .resizable()
        .scaledToFit()
        .frame(width: 22, height: 22)
    }
    
    // hosts title and .prominent properties
    private var topLine: some View {
        HStack(spacing: 4) {
            viewModel
                .result
                .properties
                .propertyViewsFor(
                    layout: layout,
                    placement: .prominent(.leading),
                    colorAssets: viewModel.colorAssets
                )

            Text(viewModel.plainTitle)
                .foregroundStyle(viewModel.titleTextColor)
                .font(.system(.caption).weight(.medium))
                .lineLimit(1)
                .accessibilityLabel(viewModel.accessibilityIdentifier)

            viewModel
                .result
                .properties
                .propertyViewsFor(
                    layout: layout,
                    placement: .prominent(.trailing),
                    colorAssets: viewModel.colorAssets
                )
        }
    }
    
    // hosts subtitle and .secondary(.trailing) properties
    @ViewBuilder
    private var bottomLine: some View {
        if viewModel.hasDescriptionOrProperties(for: layout, propertyPlacement: .secondary(.trailing)) {
            HStack(spacing: 4) {
                Text(viewModel.result.description(layout))
                    .foregroundColor(viewModel.colorAssets.subtitleTextColor)
                    .font(.caption)

                viewModel
                    .result
                    .properties
                    .propertyViewsFor(
                        layout: layout,
                        placement: .secondary(.trailing),
                        colorAssets: viewModel.colorAssets
                    )
            }
        } else {
            EmptyView()
        }
    }
    
    private var moreButton: some View {
        ImageButtonWrapper(
            image: Image(uiImage: viewModel.moreGrid),
            imageColor: TokenColors.Icon.secondary.swiftUI
        ) { button in
            viewModel.actions.contextAction(button)
        }
    }
    
    private var borderColor: Color {
        if selectionEnabled && isSelected {
            viewModel.colorAssets.selectedBorderColor
        } else {
            viewModel.colorAssets.unselectedBorderColor
        }
    }
    
    private var topNodeIconsBackgroundColor: Color {
        viewModel.colorAssets.verticalThumbnailTopIconsBackground
    }
    
    private var thumbnailBackgroundColor: Color {
        viewModel.colorAssets.verticalThumbnailPreviewBackground
    }
}

#Preview("Video") {
    SearchResultThumbnailView(
        viewModel: .init(
            result: .previewResult(
                idx: 1,
                backgroundDisplayMode: .preview,
                properties: [.play, .duration, .someProminentIcon, .someTopIcon]
            ),
            query: { nil },
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(
                contextAction: { _ in },
                selectionAction: {},
                previewTapAction: {}
            ),
            swipeActions: []
        ),
        selected: .constant([]),
        selectionEnabled: .constant(false)
    )
    .frame(width: 173, height: 214)
}

#Preview("Preview") {
    SearchResultThumbnailView(
        viewModel: .init(
            result: .previewResult(
                idx: 1,
                backgroundDisplayMode: .preview,
                properties: []
            ),
            query: { nil },
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(
                contextAction: { _ in },
                selectionAction: {},
                previewTapAction: {}
            ),
            swipeActions: []
        ),
        selected: .constant([]),
        selectionEnabled: .constant(false)
    )
    .frame(width: 173, height: 214)
}

#Preview("Icon") {
    SearchResultThumbnailView(
        viewModel: .init(
            result: .previewResult(
                idx: 1,
                backgroundDisplayMode: .icon,
                properties: []
            ),
            query: { nil },
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(
                contextAction: { _ in },
                selectionAction: {},
                previewTapAction: {}
            ),
            swipeActions: []
        ),
        selected: .constant([]),
        selectionEnabled: .constant(false)
    )
    .frame(width: 173, height: 214)
}
