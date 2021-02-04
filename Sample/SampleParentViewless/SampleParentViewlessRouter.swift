//
//  SampleParentViewlessRouter.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Yosuke Imairi. All rights reserved.
//

import RIBs

protocol SampleParentViewlessInteractable: Interactable {
    var router: SampleParentViewlessRouting? { get set }
    var listener: SampleParentViewlessListener? { get set }
}

protocol SampleParentViewlessViewControllable: ViewControllable {
}

final class SampleParentViewlessRouter: Router<SampleParentViewlessInteractable>, SampleParentViewlessRouting {

    private let viewController: SampleParentViewlessViewControllable

    init(interactor: SampleParentViewlessInteractable, viewController: SampleParentViewlessViewControllable) {
        self.viewController = viewController
        super.init(interactor: interactor)
        interactor.router = self
    }
}

// MARK: - SampleParentViewlessRouting
extension SampleParentViewlessRouter {
    func cleanupViews() {
    }
}
