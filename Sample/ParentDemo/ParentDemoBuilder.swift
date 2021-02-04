//___FILEHEADER___

import RIBs

protocol ParentDemoDependency: Dependency,
                               ParentDemoDependencyChildDemo {
}

final class ParentDemoComponent: Component<ParentDemoDependency> {
}

// MARK: - Builder

protocol ParentDemoBuildable: Buildable {
    func build(withListener listener: ParentDemoListener) -> ParentDemoRouting
}

final class ParentDemoBuilder: Builder<ParentDemoDependency>, ParentDemoBuildable {

    override init(dependency: ParentDemoDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: ParentDemoListener) -> ParentDemoRouting {
        let component = ParentDemoComponent(dependency: dependency)
        let viewController = ParentDemoViewController()
        let interactor = ParentDemoInteractor(presenter: viewController)
        interactor.listener = listener
        let childDemoBuilder = ChildDemoBuilder(component: dependency)
        return ParentDemoRouter(interactor: interactor, viewController: viewController,
                                childDemoBuilder: childDemoBuilder)
    }
}
