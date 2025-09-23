import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGARepo
import MEGASwift
import UIKit

final class ProgressIndicatorView: UIView {
    private let throttler = Throttler(timeInterval: 1.0, dispatchQueue: .main)
    private let transferInventoryUseCaseHelper = TransferInventoryUseCaseHelper()
    
    private var backgroundLayer: CAShapeLayer?
    private var progressBackgroundLayer: CAShapeLayer?
    private var progressLayer: CAShapeLayer?
    
    private var arrowImageView: UIImageView = UIImageView(
        image: MEGAAssets.UIImage.transfersDownload
    )
    private var stateBadge: UIImageView = UIImageView()
    
    private var transfers = [TransferEntity]()
    private var queuedUploadTransfers = [String]()
    private var transfersPaused: Bool {
        UserDefaults.standard.bool(forKey: "TransfersPaused")
    }
    private var configureDataTask: Task<Void, any Error>? {
        willSet {
            configureDataTask?.cancel()
        }
    }
    
    private var isWidgetForbidden = false
    @objc var overquota = false {
        didSet {
            configureData()
        }
    }
    
    @objc var progress: CGFloat = 0 {
        didSet {
            guard let progressLayer else {
                return
            }
            
            if progress > 1.0 {
                progressLayer.strokeEnd = 1.0
            } else if progress < 0.0 {
                progressLayer.strokeEnd = 0.0
            } else {
                progressLayer.strokeEnd = progress
            }
        }
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        configureData()
        configureLayers()
        configureView()
        configureDelegate()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayers()
        configureView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - Private
    
    private func updateProgress() {
        guard transfers.isNotEmpty else { return }
        let totals = transfers.reduce(into: (transferred: 0, total: 0)) { result, transfer in
            result.transferred += transfer.transferredBytes
            result.total += transfer.totalBytes
        }
        progress = CGFloat(totals.transferred) / CGFloat(totals.total)
    }
    
    @objc func showWidgetIfNeeded() {
        isWidgetForbidden = false
        configureData()
    }
    
    @objc func hideWidget(widgetFobidden: Bool = false) {
        isWidgetForbidden = widgetFobidden
        isHidden = true
        configureDataTask = nil
    }
    
    @objc func dismissWidget() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            guard self.transfers.isEmpty else {
                return
            }
            
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.progress = 0
                self.hideWidget()
            })
        }
    }
}

// MARK: - Design token colors and images

private extension ProgressIndicatorView {
    var redProgressColor: CGColor {
        TokenColors.Support.error.cgColor
    }
    
    var greenProgressColor: CGColor {
        TokenColors.Support.success.cgColor
    }
    
    var yellowProgressColor: CGColor {
        TokenColors.Support.warning.cgColor
    }
    
    var completedBadge: UIImage {
        MEGAAssets.UIImage.completedBadgeDesignToken.withTintColor(TokenColors.Support.success)
    }
    
    var errorBadge: UIImage {
        MEGAAssets.UIImage.errorBadgeDesignToken.withTintColor(TokenColors.Support.error)
    }
    
    var overquotaImage: UIImage {
        MEGAAssets.UIImage.overquotaDesignToken.withTintColor(TokenColors.Support.warning)
    }
    
    var pauseImage: UIImage {
        MEGAAssets.UIImage.pauseDesignToken.withTintColor(TokenColors.Icon.secondary)
    }
    
    var transfersDownloadImage: UIImage {
        MEGAAssets.UIImage.transfersDownloadDesignToken
    }
    
    var transfersUploadImage: UIImage {
        MEGAAssets.UIImage.transfersUploadDesignToken
    }
}

// MARK: - Configuration

extension ProgressIndicatorView {
    private func configureView() {
        addSubview(arrowImageView)
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            arrowImageView.widthAnchor.constraint(equalToConstant: 28),
            arrowImageView.heightAnchor.constraint(equalToConstant: 28),
            arrowImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        arrowImageView.contentMode = .scaleToFill
        
        addSubview(stateBadge)
        stateBadge.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stateBadge.widthAnchor.constraint(equalToConstant: 12),
            stateBadge.heightAnchor.constraint(equalToConstant: 12),
            stateBadge.trailingAnchor.constraint(equalTo: arrowImageView.trailingAnchor),
            stateBadge.topAnchor.constraint(equalTo: arrowImageView.topAnchor)
        ])
        
        if transfersPaused {
            stateBadge.image = pauseImage
        } else {
            stateBadge.image = nil
        }
        
        updateProgress()
    }
    
    private func configureLayers() {
        addBackgroundLayer()
        addProgressBackgroundLayer()
        addProgressLayer()
    }
    
    private func configureDelegate() {
        MEGASdk.shared.add(self as (any MEGARequestDelegate))
        MEGASdk.shared.add(self as (any MEGATransferDelegate))
    }
    
    @objc func configureData() {
        configureDataTask = Task {
            try await configureData()
        }
    }
    
    private func configureData() async throws {
        try Task.checkCancellation()
        
        guard !isWidgetForbidden else {
            isHidden = true
            return
        }
        transfers.removeAll()
        transfers = await transferInventoryUseCaseHelper.transfers()
        queuedUploadTransfers.removeAll()
        queuedUploadTransfers = transferInventoryUseCaseHelper.queuedUploadTransfers()

        try Task.checkCancellation()
        
        if let failedTransfer = transferInventoryUseCaseHelper.completedTransfers(filteringUserTransfers: true)
            .first(where: { $0.state != .complete && $0.state != .cancelled }) {
            updateStateBadge(for: failedTransfer)
        } else {
            stateBadge.image = nil
        }
        
        if transfers.isEmpty && queuedUploadTransfers.isEmpty {
            updateForCompletedTransfers()
        } else {
            updateForActiveTransfers()
        }
    }
    
    private func updateStateBadge(for transfer: TransferEntity) {
        guard let lastErrorExtended = transfer.lastErrorExtended else {
            stateBadge.image = nil
            return
        }
        
        switch lastErrorExtended {
        case .overquota:
            stateBadge.image = overquotaImage
        case .generic:
            stateBadge.image = nil
        default:
            stateBadge.image = errorBadge
        }
    }
    
    private func updateForActiveTransfers() {
        isHidden = false
        alpha = 1
        progressLayer?.strokeColor = greenProgressColor
        
        let hasDownloadTransfer = transfers.contains { $0.type == .download }
        let hasUploadTransfer = transfers.contains { $0.type == .upload } || queuedUploadTransfers.isNotEmpty
        arrowImageView.image = hasDownloadTransfer ? transfersDownloadImage : transfersUploadImage
        
        if overquota {
            stateBadge.image = overquotaImage
            progressLayer?.strokeColor = hasUploadTransfer ? greenProgressColor : yellowProgressColor
        } else if transfersPaused {
            stateBadge.image = pauseImage
        }
    }
    
    private func updateForCompletedTransfers() {
        let completedTransfers = transferInventoryUseCaseHelper.completedTransfers(filteringUserTransfers: true)
        guard completedTransfers.isNotEmpty else {
            isHidden = true
            return
        }
        
        progress = 1
        isHidden = false
        
        if let failedTransfer = completedTransfers.first(where: { $0.state != .complete && $0.state != .cancelled }) {
            handleFailedTransfer(failedTransfer)
        } else {
            stateBadge.image = completedBadge
            progressLayer?.strokeColor = greenProgressColor
            dismissWidget()
        }
    }
    
    private func handleFailedTransfer(_ transfer: TransferEntity) {
        guard let lastErrorExtended = transfer.lastErrorExtended else {
            stateBadge.image = completedBadge
            progressLayer?.strokeColor = greenProgressColor
            dismissWidget()
            return
        }
        
        if lastErrorExtended == .overquota {
            stateBadge.image = overquotaImage
            progressLayer?.strokeColor = yellowProgressColor
        } else if lastErrorExtended != .generic {
            stateBadge.image = errorBadge
            progressLayer?.strokeColor = redProgressColor
        }
    }
}

// MARK: - Setup Progress Layers

private extension ProgressIndicatorView {
    func addBackgroundLayer() {
        let shapeLayer = circlularLayer(
            withRect: bounds,
            insetSize: CGSize(width: 5, height: 5)
        )
        shapeLayer.fillColor = TokenColors.Background.surface2.cgColor
        shapeLayer.shadowRadius = 16
        shapeLayer.shadowOpacity = 0.2
        // No design token color available for the shadow
        shapeLayer.shadowColor = MEGAAssets.UIColor.gray04040F.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: 2)
        
        layer.addSublayer(shapeLayer)
        backgroundLayer = shapeLayer
    }
    
    func addProgressBackgroundLayer() {
        let shapeLayer = circlularLayer(
            withRect: bounds,
            insetSize: CGSize(width: 10, height: 10)
        )
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = TokenColors.Background.surface3.cgColor
        shapeLayer.lineWidth = 2
        
        layer.addSublayer(shapeLayer)
        progressBackgroundLayer = shapeLayer
    }
    
    func addProgressLayer() {
        let shapeLayer = circlularLayer(withRect: bounds,
                                        insetSize: CGSize(width: 10, height: 10))
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = greenProgressColor
        shapeLayer.lineWidth = 2
        shapeLayer.strokeEnd = 0.0
        
        layer.addSublayer(shapeLayer)
        progressLayer = shapeLayer
    }
    
    func circlularLayer(withRect rect: CGRect,
                        insetSize size: CGSize) -> CAShapeLayer {
        
        let shapeLayer = CAShapeLayer()
        
        shapeLayer.path = UIBezierPath(
            roundedRect: rect.insetBy(dx: size.width, dy: size.height),
            cornerRadius: rect.width
        ).cgPath
        
        return shapeLayer
    }
    
    func updateAppearance() {
        backgroundLayer?.fillColor = TokenColors.Background.surface2.cgColor
        progressBackgroundLayer?.strokeColor = TokenColors.Background.surface3.cgColor
        // Reset the progress layer's stroke color when the trait collection is changed.
        // This is necessary due to limitations with CAShapeLayer.
        configureData()
    }
}

// MARK: - MEGATransferDelegate

extension ProgressIndicatorView: MEGATransferDelegate {
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        if transfer.type == .download {
            if overquota {
                overquota = false
            }
            throttler.start { [weak self] in
                Task { @MainActor in
                    self?.configureData()
                }
            }
        } else {
            guard !isWidgetForbidden else {
                isHidden = true
                return
            }
            updateForActiveTransfers()
        }
    }
    
    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        var isExportFile = false
        var isSaveToPhotos = false
        if let appData = transfer.appData {
            isExportFile = appData.contains(TransferMetaDataEntity.exportFile.rawValue)
            isSaveToPhotos = appData.contains(TransferMetaDataEntity.saveInPhotos.rawValue)
        }
        
        guard transfer.path?.hasPrefix(transferInventoryUseCaseHelper.documentsDirectory().path) ?? false ||
                transfer.type == .upload ||
                isExportFile || isSaveToPhotos else {
            return
        }
        
        guard let index = transfers.firstIndex(where: { transfer.nodeHandle == $0.nodeHandle && transfer.parentHandle == $0.parentHandle }) else { return }
        transfers[index] = transfer.toTransferEntity()
        
        updateProgress()
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        Task {
            await self.processTransferFinish(api, transfer: transfer, error: error)
        }
    }
    
    func onTransferTemporaryError(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if error.type == .apiEOverQuota || error.type == .apiEgoingOverquota {
            overquota = true
        }
    }
    
    private nonisolated func processTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) async {
        if !transfer.isStreamingTransfer {
            api.addCompletedTransfer(transfer)
        }
        
        self.throttler.start { [weak self] in
            Task { @MainActor in
                self?.configureData()
            }
        }
    }
}

// MARK: - MEGARequestDelegate

extension ProgressIndicatorView: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type != .apiOk {
            switch error.type {
            case .apiEgoingOverquota, .apiEOverQuota:
                overquota = true
            default:
                break
            }
            
            return
        }
        if request.type == .MEGARequestTypePauseTransfers {
            if request.flag {
                stateBadge.image = pauseImage
            } else {
                configureData()
            }
        }
    }
}
