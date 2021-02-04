//
//  SampleParentBuilder.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Yosuke Imairi. All rights reserved.
//

import RIBs

protocol SampleParentDependency: Dependency {
}

final class SampleParentComponent: Component<SampleParentDependency> {
}

// MARK: - Builder

protocol SampleParentBuildable: Buildable {
    func build(withListener listener: SampleParentListener) -> SampleParentRouting
}

final class SampleParentBuilder: Builder<SampleParentDependency>, SampleParentBuildable {

    override init(dependency: SampleParentDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: SampleParentListener) -> SampleParentRouting {
        let component = SampleParentComponent(dependency: dependency)
        let viewController = SampleParentViewController()
        let interactor = SampleParentInteractor(presenter: viewController)
        interactor.listener = listener
        return SampleParentRouter(interactor: interactor, viewController: viewController)
    }
}
