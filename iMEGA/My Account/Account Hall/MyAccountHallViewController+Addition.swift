import Accounts
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGASwiftUI

extension MyAccountHallViewController {
    
    @objc func notifyViewDidLoad() {
        viewModel.dispatch(.viewDidLoad)
    }
    
    @objc func showSettings() {
        viewModel.dispatch(.navigateToSettings)
    }
    
    @objc func didTapProfileView() {
        viewModel.dispatch(.didTapAccountHeader)
    }
    
    @objc func showProfileView() {
        viewModel.dispatch(.navigateToProfile)
    }
    
    @objc func showUsageView() {
        viewModel.dispatch(.navigateToUsage)
    }
    
    @objc func setupNavigationBarColor(with trait: UITraitCollection) {
        let color =  UIColor.surface1Background()
        
        navigationController?.navigationBar.standardAppearance.backgroundColor = color
        navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = color
        navigationController?.navigationBar.isTranslucent = false
    }
    
    @objc func registerCustomCells() {
        self.tableView?.register(HostingTableViewCell<MyAccountHallPlanView>.self,
                                 forCellReuseIdentifier: "AccountPlanUpgradeCell")
        self.tableView?.register(HostingTableViewCell<MyAccountHallMenuView>.self,
                                 forCellReuseIdentifier: "MyAccountHallMenuView")
    }
    
    @objc func setUpInvokeCommands() {
        viewModel.invokeCommand = { [weak self] command in
            guard let self else { return }
            
            excuteCommand(command)
        }
    }
    
    @objc func loadContent() {
        viewModel.dispatch(.reloadUI)
        viewModel.dispatch(.load(.planList))
        viewModel.dispatch(.load(.accountDetails))
        viewModel.dispatch(.load(.contentCounts))
        viewModel.dispatch(.load(.promos))
    }
    
    @objc func dispatchOnViewAppearAction() {
        viewModel.dispatch(.viewWillAppear)
    }
    
    @objc func dispatchOnViewWillDisappearAction() {
        viewModel.dispatch(.viewWillDisappear)
    }
    
    // MARK: - Open sections programmatically
    @objc func openAchievements() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let achievementsIndexPath = IndexPath(row: MyAccountMegaSection.achievements.rawValue, section: MyAccountSection.mega.rawValue)
            if let tableView = self.tableView {
                tableView.selectRow(at: achievementsIndexPath, animated: true, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: achievementsIndexPath)
            }
        }
    }
    
    @objc func openOffline() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let offlineIndexPath = IndexPath(row: MyAccountMegaSection.offline.rawValue, section: MyAccountSection.mega.rawValue)
            if let tableView = self.tableView {
                tableView.selectRow(at: offlineIndexPath, animated: true, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: offlineIndexPath)
            }
        }
    }
    
    // MARK: - Private
    
    private func excuteCommand(_ command: MyAccountHallViewModel.Command) {
        switch command {
        case .reloadCounts, .reloadStorage:
            tableView?.reloadData()
        case .reloadUIContent:
            configNavigationBar()
            configPlanDisplay()
            configTableFooterView()
            configProfileHeaderMenu()
            setUserAvatar()
            setUserFullName()
            tableView?.reloadData()
        case .setUserAvatar:
            setUserAvatar()
        case .setName:
            setUserFullName()
        case .configPlanDisplay:
            configPlanDisplay()
        }
    }
    
    private func setUserAvatar() {
        guard let userHandle = viewModel.currentUserHandle else { return }
        avatarImageView?.mnz_setImage(forUserHandle: userHandle)
    }
    
    private func setUserFullName() {
        nameLabel?.text = viewModel.userFullName
    }
    
    private func configPlanDisplay() {
        guard let accountDetails = viewModel.accountDetails,
              accountDetails.proLevel == .business ||
                accountDetails.proLevel == .proFlexi else {
            accountTypeLabel?.text = ""
            return
        }

        accountTypeLabel?.text = accountDetails.proLevel.toAccountTypeDisplayName()
    }
    
    private func configNavigationBar() {
        if let navigationController, navigationController.isNavigationBarHidden {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }
    
    private func configTableFooterView() {
        guard viewModel.isMasterBusinessAccount else {
            tableView?.tableFooterView = UIView(frame: .zero)
            return
        }
        tableFooterLabel?.text = Strings.Localizable.userManagementIsOnlyAvailableFromADesktopWebBrowser
        tableView?.tableFooterView = tableFooterView
    }
    
    private func configProfileHeaderMenu() {
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileView))
        profileView?.gestureRecognizers = [profileTapGesture]
    }
    
    // MARK: - Ads
    @objc func hideAds() {
        guard let mainTabBar = UIApplication.mainTabBarRootViewController() as? MainTabBarController else { return }
        mainTabBar.hideAds()
    }
}
