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
    private let unlinkSetting: UnlinkSetting
    
    init(paths: [String], targetName: String, parentName: String, unlinkSetting: UnlinkSetting) {
        self.paths = paths
        self.targetName = targetName
        self.parentName = parentName
        self.unlinkSetting = unlinkSetting
    }
    
    func run() -> Result {
        guard !paths.filter({ $0.contains("/\(parentName)Component+\(targetName).swift") }).isEmpty else {
            print("\(parentName)Component+\(targetName).swift file is not found. Please check the target and parent RIB name.".red.bold)
            return .failure(error: .unknown) // TODO: 正しいエラー
        }
        
        print("\nStart unlinking \(targetName) RIB from \(parentName) RIB.".bold)
        
        var result: Result?
        
        do {
            try deleteComponentExtensions(for: parentName)
        } catch {
            result = .failure(error: .unknown) // TODO: 正しいエラー
        }
        
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
        
        do {
            try deleteRelatedCodesInParentInteractor(for: parentName)
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
        
        try delete(path: componentExtensionFilePath)
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
        }
    
        replacedText = unlinkSetting.parentBuilder.reduce(replacedText) { (result, builderSearchText) in
            let searchText = replacePlaceHolder(for: builderSearchText, with: targetName, and: parentName)
            return result.replacingOccurrences(of: searchText, with: "", options: .regularExpression)
        }
        
        try write(text: replacedText, for: builderFilePath)
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
        }
    
        replacedText = unlinkSetting.parentRouter.reduce(replacedText) { (result, routerSearchText) in
            let searchText = replacePlaceHolder(for: routerSearchText, with: targetName, and: parentName)
            return result.replacingOccurrences(of: searchText, with: "", options: .regularExpression)
        }
        
        try write(text: replacedText, for: routerFilePath)
    }
    
    func deleteRelatedCodesInParentInteractor(for parentName: String) throws {
        let targetFileName = "/\(parentName)/\(parentName)Interactor.swift"
        guard let interactorFilePath = paths.filter({ $0.contains(targetFileName) }).first else {
            print("Not found \(targetFileName.dropFirst()). \(targetName) RIB has already unlinked to \(parentName) RIB.".yellow.bold)
            return
        }
        
        let text = try String.init(contentsOfFile: interactorFilePath, encoding: .utf8)
    
        let replacedText = unlinkSetting.parentInteractor.reduce(text) { (result, interactorSearchText) in
            let searchText = replacePlaceHolder(for: interactorSearchText, with: targetName, and: parentName)
            return result.replacingOccurrences(of: searchText, with: "", options: .regularExpression)
        }
        
        var replacedTextArray = [String]()
        replacedText.enumerateLines { line, stop in
            if line.contains(pattern: "router\\?\\..*\(targetName)\\(") {
                replacedTextArray.append("// \(targetName) RIB has been deleted. The below codes seem not to be worked.")
            }
            replacedTextArray.append(line)
        }
        
        let result = replacedTextArray.joined(separator: "\n")
        
        try write(text: result, for: interactorFilePath)
    }
}

// MARK: - file operations
extension UnlinkCommand {
    func delete(path: String) throws {
        try Path(path).delete()
    }
    
    func write(text: String, for path: String) throws {
        try Path(path).write(text)
    }
}

// MARK: - Internal
extension UnlinkCommand {
    func replacePlaceHolder(for target: String, with ribName: String, and parentRIBName: String) -> String {
        target
            .replacingOccurrences(of: "__RIB_NAME_LOWER_CASED_FIRST_LETTER__", with: ribName.lowercasedFirstLetter())
            .replacingOccurrences(of: "__PARENT_RIB_NAME__", with: parentRIBName)
            .replacingOccurrences(of: "__RIB_NAME__", with: ribName)
    }
}

extension String {
    func contains(pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options()) else {
            return false
        }
        return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, count)) != nil
    }
}
