//
//  SampleChildInteractor.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Mobility Technologies Co., Ltd. All rights reserved.
//

import RIBs
import RxSwift

protocol SampleChildRouting: ViewableRouting {
}

protocol SampleChildPresentable: Presentable {
    var listener: SampleChildPresentableListener? { get set }
}

protocol SampleChildListener: class {
}

final class SampleChildInteractor: PresentableInteractor<SampleChildPresentable>, SampleChildInteractable, SampleChildPresentableListener {

    weak var router: SampleChildRouting?
    weak var listener: SampleChildListener?

    override init(presenter: SampleChildPresentable) {
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

// MARK: - SampleChildPresentableListener
extension SampleChildInteractor {

}
