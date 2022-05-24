//
// Created by 今入　庸介 on 2022/05/13.
//

import Foundation
import SourceKittenFramework
import PathKit

struct UnlinkCommand: Command {
    private let targetName: String
    private let parentName: String
    private let paths: [String]
    
    init(paths: [String], targetName: String, parentName: String) {
        self.paths = paths
        self.targetName = targetName
        self.parentName = parentName
    }
    
    func run() -> Result {
        guard !paths.filter({ $0.contains("/\(parentName)Component+\(targetName).swift") }).isEmpty else {
            print("\(parentName)Component+\(targetName).swift file is not found. Please check the target and parent RIB name.".red.bold)
            return .failure(error: .unknown) // TODO: 正しいエラー
        }
        
        print("\nStart unlinking \(targetName) RIB from \(parentName) RIB.".bold)
        
        var result: Result?
        
        do {
            try deleteRelatedCodesInParentBuilder(for: parentName)
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
    
        do {
            try deleteRelatedCodesInParentRouter(for: parentName)
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
    
        return result ?? .success(message: "Successfully finished unlinking \(targetName) RIB from its parents.".green.bold)
    }
}

// MARK: - Operations
private extension UnlinkCommand {
    func deleteComponentExtensions(for parentName: String) throws {
        let targetFileName = "\(parentName)/Dependencies/\(parentName)Component+\(targetName).swift"
        guard let componentExtensionFilePath = paths.filter({ $0.contains(targetFileName) }).first else {
            print("Not found \(targetFileName). Skip to delete Component Extension files.".yellow.bold)
            return
        }
        
        try Path(componentExtensionFilePath).delete()
    }
    
    func deleteRelatedCodesInParentBuilder(for parentName: String) throws {
        let targetFileName = "/\(parentName)/\(parentName)Builder.swift"
        guard let builderFilePath = paths.filter({ $0.contains(targetFileName) }).first else {
            print("Not found \(targetFileName.dropFirst()). \(targetName) RIB has already unlinked to \(parentName) RIB.".yellow.bold)
            return
        }
        
        let builderFile = File(path: builderFilePath)!
        let builderFileStructure = try! Structure(file: builderFile)
        let builderDictionary = builderFileStructure.dictionary
        let subStructures = builderDictionary.getSubStructures()
        let protocols = subStructures.filterByKeyKind(.protocol)
        let targetProtocolDictionary = protocols.extractDictionaryByKeyName("\(parentName)Dependency")
        guard !targetProtocolDictionary.isEmpty else {
            print("\(parentName)Dependency protocol is not found.".red.bold)
            print("Skip to delete related codes in \(parentName)Builder.swift".yellow.bold)
            return
        }
        
        let inheritedTypes = targetProtocolDictionary.getInheritedTypes()
        guard !inheritedTypes.isEmpty else {
            print("No protocols conforms to \(parentName)Dependency.".red.bold)
            print("Skip to delete related codes in \(parentName)Builder.swift".yellow.bold)
            return
        }
    
        let text = try String.init(contentsOfFile: builderFilePath, encoding: .utf8)
        var replacedText = ""
        if inheritedTypes.count == 1 {
            replacedText = text.replacingOccurrences(of: "\(parentName)Dependency\(targetName)", with: "Dependency")
        } else {
            replacedText = text
                .replacingOccurrences(of: "\\,\\n\\s+\(parentName)Dependency\(targetName)", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\(parentName)Dependency\(targetName)\\,\\n\\s+", with: "", options: .regularExpression)
        }
    
        replacedText = replacedText
            .replacingOccurrences(of: "let\\s+\(targetName.lowercasedFirstLetter())Builder\\s+\\=\\s+\(targetName)Builder.*\\n\\s+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\,\\n\\s+\(targetName.lowercasedFirstLetter())Builder\\:\\s+\(targetName.lowercasedFirstLetter())Builder", with: "", options: .regularExpression)
        
        print("★ for builder")
        print(replacedText)
//        try Path(builderFilePath).write(replacedText)
    }
    
    func deleteRelatedCodesInParentRouter(for parentName: String) throws {
        let targetFileName = "/\(parentName)/\(parentName)Router.swift"
        guard let routerFilePath = paths.filter({ $0.contains(targetFileName) }).first else {
            print("Not found \(targetFileName.dropFirst()). \(targetName) RIB has already unlinked to \(parentName) RIB.".yellow.bold)
            return
        }
    
        let routerFile = File(path: routerFilePath)!
        let routerFileStructure = try! Structure(file: routerFile)
        let routerDictionary = routerFileStructure.dictionary
        let subStructures = routerDictionary.getSubStructures()
        let protocols = subStructures.filterByKeyKind(.protocol)
        let targetProtocolDictionary = protocols.extractDictionaryByKeyName("\(parentName)ViewControllable")
        guard !targetProtocolDictionary.isEmpty else {
            print("\(parentName)ViewControllable protocol is not found.".red.bold)
            print("Skip to delete related codes for \(parentName)ViewControllable.".yellow.bold)
            return
        }
    
        let inheritedTypes = targetProtocolDictionary.getInheritedTypes()
        guard !inheritedTypes.isEmpty else {
            print("No protocols conforms to \(parentName)ViewControllable.".red.bold)
            print("Skip to delete related codes for \(parentName)ViewControllable.".yellow.bold)
            return
        }
    
        let text = try String.init(contentsOfFile: routerFilePath, encoding: .utf8)
        var replacedText: String
        if inheritedTypes.count == 1 {
            replacedText = text.replacingOccurrences(of: "\(targetName)ViewControllable", with: "ViewControllable")
        } else {
            replacedText = text
                .replacingOccurrences(of: "\\,\\n\\s+\(targetName)ViewControllable", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\(targetName)ViewControllable\\,\\n\\s+", with: "", options: .regularExpression)
        }
        
        replacedText = replacedText
            .replacingOccurrences(of: "\\,\\n\\s+\(targetName)Listener", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\n.*let\\s+\(targetName.lowercasedFirstLetter())Builder\\:\\s+\(targetName)Buildable", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\n.*var\\s+\(targetName.lowercasedFirstLetter())\\:\\s+Routing\\?", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\,\\n\\s+\(targetName.lowercasedFirstLetter())Builder\\:\\s+\(targetName)Buildable", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\n\\s+self\\.\(targetName.lowercasedFirstLetter())Builder\\s+\\=\\s+\(targetName.lowercasedFirstLetter())Builder", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s{4}func\\s+routeTo\(targetName)\\(.*\\{\\n[\\s\\S]*?\\n\\s{4}\\}\\n", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s{4}func\\s+switchTo\(targetName)\\(.*\\{\\n[\\s\\S]*?\\n\\s{4}\\}\\n", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s{4}func\\s+remove\(targetName)\\(.*\\{\\n[\\s\\S]*?\\n\\s{4}\\}\\n", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s{4}func\\s+detach\(targetName)\\(.*\\{\\n[\\s\\S]*?\\n\\s{4}\\}\\n", with: "", options: .regularExpression)
        
        print("★ router")
        print(replacedText)
//        try Path(routerFilePath).write(replacedText)
    }
}
