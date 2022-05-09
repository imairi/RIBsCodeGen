//
//  OrderInteractor.swift
//
//  Created by RIBsCodeGen.
//

import RIBs
import RxSwift

protocol OrderRouting: ViewableRouting {
}

protocol OrderPresentable: Presentable {
    var listener: OrderPresentableListener? { get set }
}

protocol OrderListener: class {
}

final class OrderInteractor: PresentableInteractor<NewOrderPresentable>, NewOrderInteractable, NewOrderPresentableListener {

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

// MARK: - Test
extension OrderInteractor {
}
