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
            try deleteDependencyInParentBuilder(for: parentName)
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
    
        do {
            try deleteTargetBuilderInParentBuilder(for: parentName)
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
    
    func deleteDependencyInParentBuilder(for parentName: String) throws {
        let targetFileName = "/\(parentName)/\(parentName)Builder.swift"
        guard let builderFilePath = paths.filter({ $0.contains("/\(parentName)/\(parentName)Builder.swift") }).first else {
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
            guard let lastValue = try? inheritedTypes.last?["key.name"].represented().string else {
                print("Failed to detect \(parentName)Dependency inherited types.".red.bold)
                print("Skip to delete related codes in \(parentName)Builder.swift".yellow.bold)
                return
            }
            if lastValue == "\(parentName)Dependency\(targetName)" {
                // 「\,\n\s+親Dependency子」or「\,\s+親Dependency子」を削除
                replacedText = text
                    .replacingOccurrences(of: "\\,\n\\s+\(parentName)Dependency\(targetName)", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "\\,\\s+\(parentName)Dependency\(targetName)", with: "", options: .regularExpression)
            } else {
                // 「親Dependency子\,\n」or「親Dependency子\,\s」を削除
                replacedText = text
                    .replacingOccurrences(of: "\(parentName)Dependency\(targetName)\\,\\n\\s+", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "\(parentName)Dependency\(targetName)\\,\\s", with: "", options: .regularExpression)
            }
        }
//        try Path(builderFilePath).write(replacedText)
    }
    
    func deleteTargetBuilderInParentBuilder(for parentName: String) throws {
        let targetFileName = "/\(parentName)/\(parentName)Builder.swift"
        guard let builderFilePath = paths.filter({ $0.contains("/\(parentName)/\(parentName)Builder.swift") }).first else {
            print("Not found \(targetFileName.dropFirst()). \(targetName) RIB has already unlinked to \(parentName) RIB.".yellow.bold)
            return
        }
        
        let text = try String.init(contentsOfFile: builderFilePath, encoding: .utf8)
        let replacedText = text
            .replacingOccurrences(of: "let\\s+\(targetName.lowercasedFirstLetter())Builder\\s+\\=\\s+\(targetName)Builder.*\\n\\s+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "acceptedOrderBuilder\\:\\s+acceptedOrderBuilder\\,\\n", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\,\\n\\s+\(targetName.lowercasedFirstLetter())Builder\\:\\s+\(targetName.lowercasedFirstLetter())Builder", with: "", options: .regularExpression)
//        try Path(builderFilePath).write(replacedText)
    }
}
