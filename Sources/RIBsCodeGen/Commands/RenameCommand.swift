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
    private let currentName: String
    private let newName: String
    
    private let interactorPath: String
    private let routerPath: String
    private let builderPath: String
    private let viewControllerPath: String?
    private let dependenciesPath: [String]
    
    init(paths: [String], currentName: String, newName: String) {
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
        dependenciesPath = paths.filter({ $0.contains("/" + currentName + "/Dependencies/") })
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
        try dependenciesPath.forEach { dependencyPath in
            var text = try String.init(contentsOfFile: dependencyPath, encoding: .utf8)
            let replacedText = text
                .replacingOccurrences(of: "\(currentName)Dependency", with: "\(newName)Dependency")
                .replacingOccurrences(of: "\(currentName)Component", with: "\(newName)Component")
            
            try Path(dependencyPath).write(replacedText)
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
