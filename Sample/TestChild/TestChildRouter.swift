//___FILEHEADER___

import RIBs

protocol TestChildInteractable: Interactable {
    var router: TestChildRouting? { get set }
    var listener: TestChildListener? { get set }
}

protocol TestChildViewControllable: ViewControllable {
}

final class TestChildRouter: ViewableRouter<TestChildInteractable, TestChildViewControllable>, TestChildRouting {

    override init(interactor: TestChildInteractable, viewController: TestChildViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}

// MARK: - TestChildRouting
extension TestChildRouter {

}
