//
//  SampleChildRouter.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Yosuke Imairi. All rights reserved.
//

import RIBs

protocol SampleChildInteractable: Interactable {
    var router: SampleChildRouting? { get set }
    var listener: SampleChildListener? { get set }
}

protocol SampleChildViewControllable: ViewControllable {
}

final class SampleChildRouter: ViewableRouter<SampleChildInteractable, SampleChildViewControllable>, SampleChildRouting {

    override init(interactor: SampleChildInteractable, viewController: SampleChildViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}

// MARK: - SampleChildRouting
extension SampleChildRouter {

}
