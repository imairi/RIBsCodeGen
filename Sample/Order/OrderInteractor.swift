//
//  OrderInteractor.swift
//
//  Created by RIBsCodeGen.
//

import RIBs
import RxSwift

protocol NewOrderRouting: ViewableRouting {
}

protocol NewOrderPresentable: Presentable {
    var listener: OrderPresentableListener? { get set }
}

protocol NewOrderListener: class {
}

final class OrderInteractor: PresentableInteractor<OrderPresentable>, OrderInteractable, OrderPresentableListener {

    weak var router: OrderRouting?
    weak var listener: OrderListener?

    override init(presenter: OrderPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()
    }
}

// MARK: - OrderPresentableListener
extension OrderInteractor {

}
