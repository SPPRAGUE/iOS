import MEGADomain
import MEGAPresentation
import MEGASDKRepo

extension AccountRepository: @retroactive RepositoryProtocol {
    public static var newRepo: AccountRepository {
        AccountRepository(
            backupsRootFolderNodeAccess: BackupRootNodeAccess.shared,
            accountUpdatesProvider: AccountUpdatesProvider(
                sdk: MEGASdk.sharedSdk,
                areSOQBannersEnabled: {
                    true
                }
            )
        )
    }
}
