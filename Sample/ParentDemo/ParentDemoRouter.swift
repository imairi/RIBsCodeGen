//___FILEHEADER___

import RIBs

protocol ParentDemoInteractable: Interactable,
                                 ChildDemoListener {
    var router: ParentDemoRouting? { get set }
    var listener: ParentDemoListener? { get set }
}

protocol ParentDemoViewControllable: ViewControllable {
}

final class ParentDemoRouter: ViewableRouter<ParentDemoInteractable, ParentDemoViewControllable>, ParentDemoRouting {

    private let childDemoBuilder: ChildDemoBuildable

    init(interactor: ParentDemoInteractable, viewController: ParentDemoViewControllable,
         childDemoBuilder: ChildDemoBuildable) {
        self.childDemoBuilder = childDemoBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}

// MARK: - ParentDemoRouting
extension ParentDemoRouter {

}
