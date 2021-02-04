//___FILEHEADER___

import RIBs

protocol ChildDemoDependency: Dependency {
}

final class ChildDemoComponent: Component<ChildDemoDependency> {
}

// MARK: - Builder

protocol ChildDemoBuildable: Buildable {
    func build(withListener listener: ChildDemoListener) -> ChildDemoRouting
}

final class ChildDemoBuilder: Builder<ChildDemoDependency>, ChildDemoBuildable {

    override init(dependency: ChildDemoDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: ChildDemoListener) -> ChildDemoRouting {
        let component = ChildDemoComponent(dependency: dependency)
        let viewController = ChildDemoViewController()
        let interactor = ChildDemoInteractor(presenter: viewController)
        interactor.listener = listener
        return ChildDemoRouter(interactor: interactor, viewController: viewController)
    }
}
