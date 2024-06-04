//
//  ___VARIABLE_productName___Builder.swift
//
//  Created by RIBsCodeGen.
//

import RIBs
import NeedleFoundation

protocol ___VARIABLE_productName___Dependency: NeedleFoundation.Dependency {
}

final class ___VARIABLE_productName___Component: NeedleFoundation.Component<___VARIABLE_productName___Dependency> {
    init(parent: Scope) {
        super.init(parent: parent)
    }
}

// MARK: - Builder

protocol ___VARIABLE_productName___Buildable: Buildable {
    func build(withListener listener: ___VARIABLE_productName___Listener) -> ___VARIABLE_productName___Routing
}

final class ___VARIABLE_productName___Builder: ComponentizedBuilder<___VARIABLE_productName___Component, ___VARIABLE_productName___Routing, ___VARIABLE_productName___Listener, ()>, ___VARIABLE_productName___Buildable {

    func build(withListener listener: ___VARIABLE_productName___Listener) -> ___VARIABLE_productName___Routing {
        build(withDynamicBuildDependency: listener, dynamicComponentDependency: ())
    }
    
    override func build(with component: ___VARIABLE_productName___Component, _ listener: ___VARIABLE_productName___Listener) -> ___VARIABLE_productName___Routing {
        let viewController = ___VARIABLE_productName___ViewController()
        let interactor = ___VARIABLE_productName___Interactor(presenter: viewController)
        interactor.listener = listener
        return ___VARIABLE_productName___Router(interactor: interactor,
                                                viewController: viewController)
    }
}
