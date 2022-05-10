//
// Created by 今入　庸介 on 2022/05/09.
//

import Foundation
import SourceKittenFramework
import Rainbow
import PathKit

private enum RenameProtocolType: CaseIterable {
    case routing, listener, presentable
    
    var suffix: String {
        switch self {
        case .routing:
            return "Routing"
        case .listener:
            return "Listener"
        case .presentable:
            return "Presentable"
        }
    }
}

private enum RenameVariableType: CaseIterable {
    case routing, listener, presentableListener
    
    var suffix: String {
        switch self {
        case .routing:
            return "Routing?"
        case .listener:
            return "Listener?"
        case .presentableListener:
            return "PresentableListener?"
        }
    }
}

private enum RenameInheritedType: CaseIterable {
    case presentableInteractor, interactable, presentableListener
}

struct RenameCommand: Command {
    private let paths: [String]
    private let currentName: String
    private let newName: String
    
    private let interactorPath: String
    private let routerPath: String
    private let builderPath: String
    private let viewControllerPath: String?
    private let currentDependenciesPath: [String]
    private let parents: [String]
    
    init(paths: [String], currentName: String, newName: String) {
        self.paths = paths
        self.currentName = currentName
        self.newName = newName
        
        guard let interactorPath = paths.filter({ $0.contains("/" + currentName + "Interactor.swift") }).first else {
            fatalError("Not found \(currentName)Interactor.swift".red.bold)
        }
        
        guard let routerPath = paths.filter({ $0.contains("/" + currentName + "Router.swift") }).first else {
            fatalError("Not found \(currentName)Router.swift".red.bold)
        }
        
        guard let builderPath = paths.filter({ $0.contains("/" + currentName + "Builder.swift") }).first else {
            fatalError("Not found \(currentName)Builder.swift".red.bold)
        }
        
        self.interactorPath = interactorPath
        self.routerPath = routerPath
        self.builderPath = builderPath
        viewControllerPath = paths.filter({ $0.contains("/" + currentName + "ViewController.swift") }).first
        currentDependenciesPath = paths.filter({ $0.contains("/" + currentName + "/Dependencies/") })
    
        parents = paths
            .filter({ $0.contains("Component+\(currentName).swift") })
            .flatMap { $0.split(separator: "/") }
            .filter({ $0.contains("Component+\(currentName).swift") })
            .compactMap { $0.split(separator: "+").first }
            .map { $0.dropLast("Component".count) }
            .map { String($0) }
    }
    
    func run() -> Result {
        print("\nStart rename \(currentName) to \(newName)".bold)
    
        var result: Result?
        
        do {
            try renameForInteractor()
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
    
        do {
            try renameForRouter()
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
    
        do {
            try renameForBuilder()
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
    
        do {
            try renameForViewController()
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
    
        do {
            try renameForDependencies()
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
    
        do {
            try renameForParentsInteractor()
            try renameForParentsRouter()
            try renameForParentsBuilder()
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
        
        return result ?? .success(message: "succeeded")
    }
}

// MARK: - Run
private extension RenameCommand {
    func renameForInteractor() throws {
        var text = try String.init(contentsOfFile: interactorPath, encoding: .utf8)
        let replacedText = text
            .replacingOccurrences(of: "\(currentName)Interactor.swift", with: "\(newName)Interactor.swift")
            .replacingOccurrences(of: "protocol \(currentName)Routing:", with: "protocol \(newName)Routing:")
            .replacingOccurrences(of: "protocol \(currentName)Presentable:", with: "protocol \(newName)Presentable:")
            .replacingOccurrences(of: "protocol \(currentName)Listener:", with: "protocol \(newName)Listener:")
            .replacingOccurrences(of: "class \(currentName)Interactor", with: "class \(newName)Interactor")
            .replacingOccurrences(of: "extension \(currentName)Interactor", with: "extension \(newName)Interactor")
            .replacingOccurrences(of: "PresentableInteractor<\(currentName)Presentable>", with: "PresentableInteractor<\(newName)Presentable>")
            .replacingOccurrences(of: "\(currentName)Interactable", with: "\(newName)Interactable")
            .replacingOccurrences(of: "\(currentName)PresentableListener", with: "\(newName)PresentableListener")
            .replacingOccurrences(of: "presenter: \(currentName)Presentable", with: "presenter: \(newName)Presentable")
            .replacingOccurrences(of: "// MARK: - \(currentName)PresentableListener", with: "// MARK: - \(newName)PresentableListener")
        try Path(interactorPath).write(replacedText)
    }
    
    func renameForRouter() throws {
        var text = try String.init(contentsOfFile: routerPath, encoding: .utf8)
        let replacedText = text
            .replacingOccurrences(of: "\(currentName)Router.swift", with: "\(newName)Router.swift")
            .replacingOccurrences(of: "protocol \(currentName)Interactable:", with: "protocol \(newName)Interactable:")
            .replacingOccurrences(of: "protocol \(currentName)ViewControllable:", with: "protocol \(newName)ViewControllable:")
            .replacingOccurrences(of: "class \(currentName)Router:", with: "class \(newName)Router:")
            .replacingOccurrences(of: "extension \(currentName)Router", with: "extension \(newName)Router")
            .replacingOccurrences(of: "router: \(currentName)Routing?", with: "router: \(newName)Routing?")
            .replacingOccurrences(of: "listener: \(currentName)Listener?", with: "listener: \(newName)Listener?")
            .replacingOccurrences(of: "interactor: \(currentName)Interactable", with: "interactor: \(newName)Interactable")
            .replacingOccurrences(of: "viewController: \(currentName)ViewControllable", with: "viewController: \(newName)ViewControllable")
            .replacingOccurrences(of: "ViewableRouter<\(currentName)Interactable, \(currentName)ViewControllable>", with: "ViewableRouter<\(newName)Interactable, \(newName)ViewControllable>")
            .replacingOccurrences(of: ", \(currentName)Routing", with: ", \(newName)Routing")
            .replacingOccurrences(of: "Router<\(currentName)Interactable>", with: "Router<\(newName)Interactable>")
            .replacingOccurrences(of: "viewController: \(currentName)ViewControllable", with: "viewController: \(newName)ViewControllable")
            .replacingOccurrences(of: "// MARK: - \(currentName)Routing", with: "// MARK: - \(newName)Routing")
        try Path(routerPath).write(replacedText)
    }
    
    func renameForBuilder() throws {
        var text = try String.init(contentsOfFile: builderPath, encoding: .utf8)
        let replacedText = text
            .replacingOccurrences(of: "\(currentName)Builder.swift", with: "\(newName)Builder.swift")
            .replacingOccurrences(of: "class \(currentName)Builder:", with: "class \(newName)Builder:")
            .replacingOccurrences(of: "\(currentName)Dependency", with: "\(newName)Dependency")
            .replacingOccurrences(of: "\(currentName)Component", with: "\(newName)Component")
            .replacingOccurrences(of: "\(currentName)ViewController", with: "\(newName)ViewController")
            .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())ViewController", with: "\(newName.lowercasedFirstLetter())ViewController")
            .replacingOccurrences(of: "\(currentName)ViewControllable", with: "\(newName)ViewControllable")
            .replacingOccurrences(of: "\(currentName)Listener", with: "\(newName)Listener")
            .replacingOccurrences(of: "\(currentName)Routing", with: "\(newName)Routing")
            .replacingOccurrences(of: "\(currentName)ActionableItem", with: "\(newName)ActionableItem")
            .replacingOccurrences(of: "\(currentName)Router", with: "\(newName)Router")
        try Path(builderPath).write(replacedText)
    }
    
    func renameForViewController() throws {
        guard let viewControllerPath = viewControllerPath else {
            return
        }
        var text = try String.init(contentsOfFile: viewControllerPath, encoding: .utf8)
        let replacedText = text
            .replacingOccurrences(of: "\(currentName)ViewController.swift", with: "\(newName)ViewController.swift")
            .replacingOccurrences(of: "\(currentName)PresentableListener", with: "\(newName)PresentableListener")
            .replacingOccurrences(of: "class \(currentName)ViewController:", with: "class \(newName)ViewController:")
            .replacingOccurrences(of: "extension \(currentName)ViewController", with: "extension \(newName)ViewController")
            .replacingOccurrences(of: "\(currentName)Presentable", with: "\(newName)Presentable")
            .replacingOccurrences(of: "\(currentName)ViewControllable", with: "\(newName)ViewControllable")
        try Path(viewControllerPath).write(replacedText)
    }
    
    func renameForDependencies() throws {
        try currentDependenciesPath.forEach { dependencyPath in
            var text = try String.init(contentsOfFile: dependencyPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "\(currentName)Dependency", with: "\(newName)Dependency")
                .replacingOccurrences(of: "\(currentName)Component", with: "\(newName)Component")
            try Path(dependencyPath).write(replacedText)
        }
    }
    
    func renameForParentsInteractor() throws {
        try parents.forEach { parentName in
            guard let parentInteractorPath = paths.filter({ $0.contains("/" + parentName + "Interactor.swift") }).first else {
                fatalError("Not found \(parentName)Interactor.swift".red.bold)
            }
    
            var text = try String.init(contentsOfFile: parentInteractorPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "\(currentName)Listener", with: "\(newName)Listener")
                .replacingOccurrences(of: "routeTo\(currentName)", with: "routeTo\(newName)")
                .replacingOccurrences(of: "switchTo\(currentName)", with: "switchTo\(newName)")
                .replacingOccurrences(of: "detach\(currentName)", with: "detach\(newName)")
                .replacingOccurrences(of: "remove\(currentName)", with: "remove\(newName)")
                .replacingOccurrences(of: "deactivate\(currentName)", with: "deactivate\(newName)")
            try Path(parentInteractorPath).write(replacedText)
        }
    }
    
    func renameForParentsRouter() throws {
        try parents.forEach { parentName in
            guard let parentRouterPath = paths.filter({ $0.contains("/" + parentName + "Router.swift") }).first else {
                fatalError("Not found \(parentName)Router.swift".red.bold)
            }
            
            var text = try String.init(contentsOfFile: parentRouterPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "\(currentName)Listener", with: "\(newName)Listener")
                .replacingOccurrences(of: "routeTo\(currentName)", with: "routeTo\(newName)")
                .replacingOccurrences(of: "switchTo\(currentName)", with: "switchTo\(newName)")
                .replacingOccurrences(of: "\(currentName)Listener", with: "\(newName)Listener")
                .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())Builder: ReservationDashboardBuildable", with: "\(newName.lowercasedFirstLetter())Builder: ReservationDashboardBuildable")
                .replacingOccurrences(of: "self.\(currentName.lowercasedFirstLetter())Builder = reservationDashboardBuilder", with: "self.\(newName.lowercasedFirstLetter())Builder = reservationDashboardBuilder")
                .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())Builder.build", with: "\(newName.lowercasedFirstLetter())Builder.build")
                .replacingOccurrences(of: "is \(currentName)Routing", with: "is \(newName)Routing")
                .replacingOccurrences(of: " \(currentName)ViewControllable", with: " \(newName)ViewControllable")
                .replacingOccurrences(of: "var \(currentName.lowercasedFirstLetter()): Routing?", with: "var \(newName.lowercasedFirstLetter()): Routing?")
                .replacingOccurrences(of: "detach\(currentName)(", with: "detach\(newName)(")
                .replacingOccurrences(of: "remove\(currentName)(", with: "remove\(newName)(")
            try Path(parentRouterPath).write(replacedText)
        }
    }
    
    func renameForParentsBuilder() throws {
        try parents.forEach { parentName in
            guard let parentBuilderPath = paths.filter({ $0.contains("/" + parentName + "Builder.swift") }).first else {
                fatalError("Not found \(parentName)Builder.swift".red.bold)
            }
            
            var text = try String.init(contentsOfFile: parentBuilderPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "\(parentName)Dependency\(currentName)", with: "\(parentName)Dependency\(newName)")
                .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())Builder = \(currentName)Builder", with: "\(newName.lowercasedFirstLetter())Builder = \(newName)Builder")
                .replacingOccurrences(of: "\(currentName.lowercasedFirstLetter())Builder: \(currentName.lowercasedFirstLetter())Builder", with: "\(newName.lowercasedFirstLetter())Builder: \(newName.lowercasedFirstLetter())Builder")
            try Path(parentBuilderPath).write(replacedText)
        }
    }
}

extension Dictionary {
    func prettyPrinted() {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) else {
            print("JSON Serialization error")
            return
        }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("JSON Encoding error")
            return
        }
        print(jsonString)
    }
}

extension Array {
    func prettyPrinted() {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) else {
            print("JSON Serialization error")
            return
        }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("JSON Encoding error")
            return
        }
        print(jsonString)
    }
}
