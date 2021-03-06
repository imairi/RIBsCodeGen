//
//  SampleParentViewlessBuilder.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/03.
//  Copyright © 2021 Yosuke Imairi. All rights reserved.
//

import RIBs

protocol SampleParentViewlessDependency: Dependency {
    var sampleParentViewlessViewController: SampleParentViewlessViewControllable { get }
}

final class SampleParentViewlessComponent: Component<SampleParentViewlessDependency> {

    fileprivate var sampleParentViewlessViewController: SampleParentViewlessViewControllable {
        return dependency.sampleParentViewlessViewController
    }

}

// MARK: - Builder

protocol SampleParentViewlessBuildable: Buildable {
    func build(withListener listener: SampleParentViewlessListener) -> SampleParentViewlessRouting
}

final class SampleParentViewlessBuilder: Builder<SampleParentViewlessDependency>, SampleParentViewlessBuildable {

    override init(dependency: SampleParentViewlessDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: SampleParentViewlessListener) -> SampleParentViewlessRouting {
        let component = SampleParentViewlessComponent(dependency: dependency)
        let interactor = SampleParentViewlessInteractor()
        interactor.listener = listener
        return SampleParentViewlessRouter(interactor: interactor, viewController: component.SampleParentViewlessViewController)
    }
}
