//
//  ___VARIABLE_productName___Builder.swift
//
//  Created by RIBsCodeGen.
//

import RIBs
import NeedleFoundation

protocol ___VARIABLE_productName___Dependency: NeedleFoundation.Dependency {
    var ___VARIABLE_productName_lowercased___ViewController: ___VARIABLE_productName___ViewControllable { get }
}

final class ___VARIABLE_productName___Component: NeedleFoundation.Component<___VARIABLE_productName___Dependency> {

    fileprivate var ___VARIABLE_productName_lowercased___ViewController: ___VARIABLE_productName___ViewControllable {
        return dependency.___VARIABLE_productName_lowercased___ViewController
    }

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
        let interactor = ___VARIABLE_productName___Interactor()
        interactor.listener = listener
        return ___VARIABLE_productName___Router(interactor: interactor,
                                                viewController: component.___VARIABLE_productName_lowercased___ViewController)
    }
}
