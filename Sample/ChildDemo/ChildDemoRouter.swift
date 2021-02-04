//___FILEHEADER___

import RIBs

protocol ChildDemoInteractable: Interactable {
    var router: ChildDemoRouting? { get set }
    var listener: ChildDemoListener? { get set }
}

protocol ChildDemoViewControllable: ViewControllable {
}

final class ChildDemoRouter: ViewableRouter<ChildDemoInteractable, ChildDemoViewControllable>, ChildDemoRouting {

    override init(interactor: ChildDemoInteractable, viewController: ChildDemoViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}

// MARK: - ChildDemoRouting
extension ChildDemoRouter {

}
