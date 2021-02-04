//___FILEHEADER___

import RIBs

protocol TestDependency: Dependency {
}

final class TestComponent: Component<TestDependency> {
}

// MARK: - Builder

protocol TestBuildable: Buildable {
    func build(withListener listener: TestListener) -> TestRouting
}

final class TestBuilder: Builder<TestDependency>, TestBuildable {

    override init(dependency: TestDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: TestListener) -> TestRouting {
        let component = TestComponent(dependency: dependency)
        let viewController = TestViewController()
        let interactor = TestInteractor(presenter: viewController)
        interactor.listener = listener
        return TestRouter(interactor: interactor, viewController: viewController)
    }
}
