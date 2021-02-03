//
//  SampleParentInteractor.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Mobility Technologies Co., Ltd. All rights reserved.
//

import RIBs
import RxSwift

protocol SampleParentRouting: ViewableRouting {
}

protocol SampleParentPresentable: Presentable {
    var listener: SampleParentPresentableListener? { get set }
}

protocol SampleParentListener: class {
}

final class SampleParentInteractor: PresentableInteractor<SampleParentPresentable>, SampleParentInteractable, SampleParentPresentableListener {

    weak var router: SampleParentRouting?
    weak var listener: SampleParentListener?

    override init(presenter: SampleParentPresentable) {
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

// MARK: - SampleParentPresentableListener
extension SampleParentInteractor {

}
