//___FILEHEADER___

import RIBs

protocol TestInteractable: Interactable {
    var router: TestRouting? { get set }
    var listener: TestListener? { get set }
}

protocol TestViewControllable: ViewControllable {
}

final class TestRouter: ViewableRouter<TestInteractable, TestViewControllable>, TestRouting {

    override init(interactor: TestInteractable, viewController: TestViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}

// MARK: - TestRouting
extension TestRouter {

}
