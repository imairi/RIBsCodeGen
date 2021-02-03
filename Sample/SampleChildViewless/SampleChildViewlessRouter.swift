//
//  SampleChildViewlessRouter.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Yosuke Imairi. All rights reserved.
//

import RIBs

protocol SampleChildViewlessInteractable: Interactable {
    var router: SampleChildViewlessRouting? { get set }
    var listener: SampleChildViewlessListener? { get set }
}

protocol SampleChildViewlessViewControllable: ViewControllable {
}

final class SampleChildViewlessRouter: Router<SampleChildViewlessInteractable>, SampleChildViewlessRouting {

    private let viewController: SampleChildViewlessViewControllable

    init(interactor: SampleChildViewlessInteractable, viewController: SampleChildViewlessViewControllable) {
        self.viewController = viewController
        super.init(interactor: interactor)
        interactor.router = self
    }
}

// MARK: - SampleChildViewlessRouting
extension SampleChildViewlessRouter {
    func cleanupViews() {
    }
}
