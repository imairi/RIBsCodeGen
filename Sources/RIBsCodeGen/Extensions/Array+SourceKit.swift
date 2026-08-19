//
//  Array+SourceKit.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/04.
//

import Foundation
import SourceKittenFramework

extension Collection where Iterator.Element == [String: SourceKitRepresentable] {
    func extractDictionaryContainsKeyName(_ targetKeyName: String) -> [String: SourceKitRepresentable] {
        let targetStructures = self.filter { structure -> Bool in
            let keyName = structure["key.name"] as? String ?? ""
            return keyName.contains(targetKeyName)
        }
        return targetStructures.first ?? [String: SourceKitRepresentable]()
    }

    func extractDictionaryContainsKeyNameLast(_ targetKeyName: String) -> [String: SourceKitRepresentable] {
        let targetStructures = self.filter { structure -> Bool in
            let keyName = structure["key.name"] as? String ?? ""
            return keyName.contains(targetKeyName)
        }
        return targetStructures.last ?? [String: SourceKitRepresentable]()
    }

    func extractDictionaryByKeyName(_ targetKeyName: String) -> [String: SourceKitRepresentable] {
        let targetStructures = self.filter { structure -> Bool in
            let keyName = structure["key.name"] as? String ?? ""
            return keyName == targetKeyName
        }
        return targetStructures.first ?? [String: SourceKitRepresentable]()
    }

    func filterByKeyName(_ targetKeyName: String) -> [[String: SourceKitRepresentable]] {
        let targetStructures = self.filter { structure -> Bool in
            let keyName = structure["key.name"] as? String ?? ""
            return keyName.contains(targetKeyName)
        }
        return targetStructures
    }

    func filterByAttribute(_ targetKind: SwiftDeclarationAttributeKind) -> [[String: SourceKitRepresentable]] {
        let targetStructures = self.filter { structure -> Bool in
            let keyAttributes = structure["key.attribute"] as? String ?? ""
            let attributeKind = SwiftDeclarationAttributeKind(rawValue: keyAttributes)

            return attributeKind == targetKind
        }
        return targetStructures
    }

    func filterByKeyKind(_ targetKind: SwiftDeclarationKind) -> [[String: SourceKitRepresentable]] {
        let targetStructures = self.filter { initStructure -> Bool in
            guard let kindValue = initStructure["key.kind"] as? String else {
                return false
            }
            let kind = SwiftDeclarationKind(rawValue: kindValue)
            return kind == targetKind
        }
        return targetStructures
    }

    func filterByKeyKind(_ targetKind: SwiftExpressionKind) -> [[String: SourceKitRepresentable]] {
        let targetStructures = self.filter { initStructure -> Bool in
            guard let kindValue = initStructure["key.kind"] as? String else {
                return false
            }
            let kind = SwiftExpressionKind(rawValue: kindValue)
            return kind == targetKind
        }
        return targetStructures
    }

    func filterByKeyTypeName(_ targetTypeName: String) -> [[String: SourceKitRepresentable]] {
        let targetStructures = self.filter { structure -> Bool in
            let keyTypeName = structure["key.typename"] as? String ?? ""
            return keyTypeName.contains(targetTypeName)
        }
        return targetStructures
    }
}
