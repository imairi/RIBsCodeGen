//
//  OrderRouter.swift
//
//  Created by RIBsCodeGen.
//

import RIBs

protocol OrderInteractable: Interactable {
    var router: OrderRouting? { get set }
    var listener: OrderListener? { get set }
}

protocol OrderViewControllable: ViewControllable {
}

final class OrderRouter: ViewableRouter<OrderInteractable, OrderViewControllable>, OrderRouting {

    override init(interactor: OrderInteractable,
                  viewController: OrderViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}

// MARK: - OrderRouting
extension OrderRouter {

}
