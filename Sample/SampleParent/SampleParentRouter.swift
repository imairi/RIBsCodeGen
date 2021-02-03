//
//  SampleParentRouter.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Mobility Technologies Co., Ltd. All rights reserved.
//

import RIBs

protocol SampleParentInteractable: Interactable {
    var router: SampleParentRouting? { get set }
    var listener: SampleParentListener? { get set }
}

protocol SampleParentViewControllable: ViewControllable {
}

final class SampleParentRouter: ViewableRouter<SampleParentInteractable, SampleParentViewControllable>, SampleParentRouting {

    override init(interactor: SampleParentInteractable, viewController: SampleParentViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}

// MARK: - SampleParentRouting
extension SampleParentRouter {

}
