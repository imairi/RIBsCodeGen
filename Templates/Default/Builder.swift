//
//  ___VARIABLE_productName___Builder.swift
//
//  Created by RIBsCodeGen.
//

import RIBs

protocol ___VARIABLE_productName___Dependency: Dependency {
    var ___VARIABLE_productName_lowercased___ViewController: ___VARIABLE_productName___ViewControllable { get }
}

final class ___VARIABLE_productName___Component: Component<___VARIABLE_productName___Dependency> {

    fileprivate var ___VARIABLE_productName_lowercased___ViewController: ___VARIABLE_productName___ViewControllable {
        return dependency.___VARIABLE_productName_lowercased___ViewController
    }

}

// MARK: - Builder

protocol ___VARIABLE_productName___Buildable: Buildable {
    func build(withListener listener: ___VARIABLE_productName___Listener) -> ___VARIABLE_productName___Routing
}

final class ___VARIABLE_productName___Builder: Builder<___VARIABLE_productName___Dependency>, ___VARIABLE_productName___Buildable {

    override init(dependency: ___VARIABLE_productName___Dependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: ___VARIABLE_productName___Listener) -> ___VARIABLE_productName___Routing {
        let component = ___VARIABLE_productName___Component(dependency: dependency)
        let interactor = ___VARIABLE_productName___Interactor()
        interactor.listener = listener
        return ___VARIABLE_productName___Router(interactor: interactor,
                                                viewController: component.___VARIABLE_productName___ViewController)
    }
}
