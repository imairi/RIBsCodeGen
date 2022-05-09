//
//  OrderBuilder.swift
//
//  Created by RIBsCodeGen.
//

import RIBs

protocol OrderDependency: Dependency {
}

final class OrderComponent: Component<OrderDependency> {
}

// MARK: - Builder

protocol OrderBuildable: Buildable {
    func build(withListener listener: OrderListener) -> OrderRouting
}

final class OrderBuilder: Builder<OrderDependency>, OrderBuildable {

    override init(dependency: OrderDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: OrderListener) -> OrderRouting {
        let component = OrderComponent(dependency: dependency)
        let viewController = OrderViewController()
        let interactor = OrderInteractor(presenter: viewController)
        interactor.listener = listener
        return OrderRouter(interactor: interactor,
                           viewController: viewController)
    }
}
