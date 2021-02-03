//
//  SampleChildViewlessInteractor.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Mobility Technologies Co., Ltd. All rights reserved.
//

import RIBs
import RxSwift

protocol SampleChildViewlessRouting: Routing {
    func cleanupViews()
}

protocol SampleChildViewlessListener: class {
}

final class SampleChildViewlessInteractor: Interactor, SampleChildViewlessInteractable {

    weak var router: SampleChildViewlessRouting?
    weak var listener: SampleChildViewlessListener?

    override init() {}

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()

        router?.cleanupViews()
    }
}
