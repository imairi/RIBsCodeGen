//
//  SampleChildViewlessBuilder.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Mobility Technologies Co., Ltd. All rights reserved.
//

import RIBs

protocol SampleChildViewlessDependency: Dependency {
    var SampleChildViewlessViewController: SampleChildViewlessViewControllable { get }
}

final class SampleChildViewlessComponent: Component<SampleChildViewlessDependency> {

    fileprivate var SampleChildViewlessViewController: SampleChildViewlessViewControllable {
        return dependency.SampleChildViewlessViewController
    }

}

// MARK: - Builder

protocol SampleChildViewlessBuildable: Buildable {
    func build(withListener listener: SampleChildViewlessListener) -> SampleChildViewlessRouting
}

final class SampleChildViewlessBuilder: Builder<SampleChildViewlessDependency>, SampleChildViewlessBuildable {

    override init(dependency: SampleChildViewlessDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: SampleChildViewlessListener) -> SampleChildViewlessRouting {
        let component = SampleChildViewlessComponent(dependency: dependency)
        let interactor = SampleChildViewlessInteractor()
        interactor.listener = listener
        return SampleChildViewlessRouter(interactor: interactor, viewController: component.SampleChildViewlessViewController)
    }
}
