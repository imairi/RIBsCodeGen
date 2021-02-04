//
//  SampleParentViewlessInteractor.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Yosuke Imairi. All rights reserved.
//

import RIBs
import RxSwift

protocol SampleParentViewlessRouting: Routing {
    func cleanupViews()
}

protocol SampleParentViewlessListener: class {
}

final class SampleParentViewlessInteractor: Interactor, SampleParentViewlessInteractable {

    weak var router: SampleParentViewlessRouting?
    weak var listener: SampleParentViewlessListener?

    override init() {}

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()

        router?.cleanupViews()
    }
}
