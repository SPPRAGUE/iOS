import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import SwiftUI
import UIKit

public protocol TermsAndPoliciesRouting: Routing {
    func dismiss()
}

public struct TermsAndPoliciesRouter: TermsAndPoliciesRouting {
    private weak var navigationController: UINavigationController?
    private weak var presenter: UIViewController?
    private let accountUseCase: any AccountUseCaseProtocol
    private let domainNameHandler: () -> String

    public init(
        accountUseCase: some AccountUseCaseProtocol,
        domainNameHandler: @escaping () -> String,
        navigationController: UINavigationController? = nil,
        presenter: UIViewController? = nil
    ) {
        self.accountUseCase = accountUseCase
        self.domainNameHandler = domainNameHandler
        self.navigationController = navigationController
        self.presenter = presenter
    }

    public func build() -> UIViewController {
        let termsAndPoliciesView = TermsAndPoliciesView(
            viewModel: TermsAndPoliciesViewModel(
                accountUseCase: accountUseCase,
                domainNameHandler: domainNameHandler,
                router: self
            ),
            isPresented: presenter != nil
        )

        return UIHostingController(rootView: termsAndPoliciesView)
    }
    
    public func start() {
        if let navigationController {
            navigationController.pushViewController(build(), animated: true)
        } else if let presenter {
            presenter.present(build(), animated: true)
        }
    }
    
    public func dismiss() {
        if let presenter {
            presenter.dismiss(animated: true)
        }
    }
}
