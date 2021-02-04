//___FILEHEADER___

import RIBs

protocol TestChildDependency: Dependency {
}

final class TestChildComponent: Component<TestChildDependency> {
}

// MARK: - Builder

protocol TestChildBuildable: Buildable {
    func build(withListener listener: TestChildListener) -> TestChildRouting
}

final class TestChildBuilder: Builder<TestChildDependency>, TestChildBuildable {

    override init(dependency: TestChildDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: TestChildListener) -> TestChildRouting {
        let component = TestChildComponent(dependency: dependency)
        let viewController = TestChildViewController()
        let interactor = TestChildInteractor(presenter: viewController)
        interactor.listener = listener
        return TestChildRouter(interactor: interactor, viewController: viewController)
    }
}
