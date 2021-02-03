//
//  SampleChildBuilder.swift
//  MOV
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Yosuke Imairi. All rights reserved.
//

import RIBs

protocol SampleChildDependency: Dependency {
}

final class SampleChildComponent: Component<SampleChildDependency> {
}

// MARK: - Builder

protocol SampleChildBuildable: Buildable {
    func build(withListener listener: SampleChildListener) -> SampleChildRouting
}

final class SampleChildBuilder: Builder<SampleChildDependency>, SampleChildBuildable {

    override init(dependency: SampleChildDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: SampleChildListener) -> SampleChildRouting {
        let component = SampleChildComponent(dependency: dependency)
        let viewController = SampleChildViewController()
        let interactor = SampleChildInteractor(presenter: viewController)
        interactor.listener = listener
        return SampleChildRouter(interactor: interactor, viewController: viewController)
    }
}
