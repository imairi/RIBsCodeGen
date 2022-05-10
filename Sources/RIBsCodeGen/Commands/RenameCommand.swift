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
    }
    
    func run() -> Result {
        print("\nStart rename \(currentName) to \(newName)".bold)
    
        var result: Result?
        
        do {
            try renameForInteractor()
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
