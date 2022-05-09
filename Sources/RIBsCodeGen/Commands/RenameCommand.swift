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
        RenameProtocolType.allCases.forEach { renameProtocolType in
            do {
                try renameForInteractor(for: renameProtocolType)
            } catch {
                result = .failure(error: .unknown) // TODO 正しいエラー
            }
        }
        
        return result ?? .success(message: "succeeded")
    }
}

// MARK: - Run
private extension RenameCommand {
    func renameForInteractor(for renameProtocolType: RenameProtocolType) throws {
        let interactorFile = File(path: interactorPath)!
        let interactorFileStructure = try! Structure(file: interactorFile)
        let interactorDictionary = interactorFileStructure.dictionary
        let subStructures = interactorDictionary.getSubStructures()
        let protocols = subStructures.filterByKeyKind(.protocol)
        let targetProtocolDictionary = protocols.extractByKeyName("\(currentName)\(renameProtocolType.suffix)")
        guard !targetProtocolDictionary.isEmpty else {
            print("\(currentName)\(renameProtocolType.suffix) is not found. Skip to rename.".yellow)
            return
        }
    
        var text = try String.init(contentsOfFile: interactorPath, encoding: .utf8)
        let startIndex = text.utf8.index(text.startIndex, offsetBy: targetProtocolDictionary.getOuterLeadingPosition())
        let endIndex = text.utf8.index(text.startIndex, offsetBy: targetProtocolDictionary.getOuterLeadingPosition() + targetProtocolDictionary.getKeyNameLength())
        text.replaceSubrange(startIndex..<endIndex, with: "\(newName)\(renameProtocolType.suffix)")
        try Path(interactorPath).write(text)
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
