import Foundation
import SwiftParser
import SwiftSyntax

enum SwiftDeclarationKind: String, CaseIterable {
    case `protocol` = "source.lang.swift.decl.protocol"
    case `class` = "source.lang.swift.decl.class"
    case `struct` = "source.lang.swift.decl.struct"
    case `extension` = "source.lang.swift.decl.extension"
    case functionConstructor = "source.lang.swift.decl.function.constructor"
    case functionMethodInstance = "source.lang.swift.decl.function.method.instance"
    case varInstance = "source.lang.swift.decl.var.instance"
    case varParameter = "source.lang.swift.decl.var.parameter"
}

enum SwiftDeclarationAttributeKind: String, CaseIterable {
    case `override` = "source.decl.attribute.override"
}

struct SwiftAttribute {
    let kind: SwiftDeclarationAttributeKind
}

struct SwiftInheritedType {
    let name: String
}

struct ByteCount {
    let value: Int
}

struct ByteRange {
    let location: ByteCount
    let length: ByteCount
}

struct Line {
    let index: Int
    let content: String
    let byteRange: ByteRange
}

final class File {
    let path: String?
    private(set) var contents: String

    var lines: [Line] {
        LineParser.parse(contents: contents)
    }

    init?(path: String) {
        self.path = URL(fileURLWithPath: path).path
        guard let loaded = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        contents = loaded
    }

    init(contents: String) {
        path = nil
        self.contents = contents
    }

    func format(trimmingTrailingWhitespace: Bool,
                useTabs: Bool,
                indentWidth: Int) throws -> String {
        SwiftFileFormatter.format(
            contents: contents,
            trimmingTrailingWhitespace: trimmingTrailingWhitespace,
            useTabs: useTabs,
            indentWidth: indentWidth
        )
    }
}

struct Structure {
    let dictionary: SwiftNode

    init(file: File) throws {
        dictionary = SwiftSyntaxStructureParser.makeRoot(source: file.contents)
    }
}

struct SwiftNode {
    let name: String
    let typeName: String
    let kind: String
    let offset: Int
    let length: Int
    let nameOffset: Int
    let nameLength: Int
    let bodyOffset: Int
    let bodyLength: Int
    let attributes: [SwiftAttribute]
    let inheritedTypes: [SwiftInheritedType]
    let substructures: [SwiftNode]
    let isEmpty: Bool

    static let empty = SwiftNode(
        name: "",
        typeName: "",
        kind: "",
        offset: 0,
        length: 0,
        nameOffset: 0,
        nameLength: 0,
        bodyOffset: 0,
        bodyLength: 0,
        attributes: [],
        inheritedTypes: [],
        substructures: [],
        isEmpty: true
    )
}

private enum SwiftSyntaxExpressionKind: String {
    case call = "source.lang.swift.expr.call"
    case argument = "source.lang.swift.expr.argument"
}

private enum LineParser {
    static func parse(contents: String) -> [Line] {
        let splitLines = contents.split(separator: "\n", omittingEmptySubsequences: false)
        var offset = 0
        var result: [Line] = []

        for (index, element) in splitLines.enumerated() {
            let line = String(element)
            let hasTerminator = index < splitLines.count - 1
            let length = line.lengthOfBytes(using: .utf8) + (hasTerminator ? 1 : 0)
            result.append(
                Line(
                    index: index + 1,
                    content: line,
                    byteRange: ByteRange(location: ByteCount(value: offset), length: ByteCount(value: length))
                )
            )
            offset += length
        }

        return result
    }
}

private enum SwiftFileFormatter {
    static func format(contents: String,
                       trimmingTrailingWhitespace: Bool,
                       useTabs: Bool,
                       indentWidth: Int) -> String {
        let rawLines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var formattedLines: [String] = []
        var braceDepth = 0
        var parenStack: [Int] = []
        var inheritanceIndent: Int?

        for rawLine in rawLines {
            let trimmedLine = rawLine.trimmingCharacters(in: .whitespaces)

            guard !trimmedLine.isEmpty else {
                formattedLines.append("")
                continue
            }

            let leadingClosingBraces = trimmedLine.leadingClosingBraceCount
            let baseBraceDepth = max(0, braceDepth - leadingClosingBraces)
            let baseIndent = baseBraceDepth * indentWidth

            let indent: Int
            if let inheritanceIndent, !trimmedLine.startsTypeDeclaration {
                indent = inheritanceIndent
            } else if let continuationIndent = parenStack.last, !trimmedLine.hasPrefix("}") {
                indent = continuationIndent
            } else {
                indent = baseIndent
            }

            let normalizedLine = indentationString(width: indent, useTabs: useTabs, indentWidth: indentWidth) + trimmedLine
            formattedLines.append(normalizedLine)

            updateContext(
                line: normalizedLine,
                braceDepth: &braceDepth,
                parenStack: &parenStack,
                inheritanceIndent: &inheritanceIndent
            )
        }

        var output = formattedLines.joined(separator: "\n")
        if trimmingTrailingWhitespace {
            output = output
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.removingTrailingWhitespace }
                .joined(separator: "\n")
        }

        if !output.isEmpty && !output.hasSuffix("\n") {
            output.append("\n")
        }

        return output
    }

    private static func indentationString(width: Int, useTabs: Bool, indentWidth: Int) -> String {
        guard useTabs else {
            return String(repeating: " ", count: width)
        }

        let tabCount = width / max(1, indentWidth)
        let spaceCount = width % max(1, indentWidth)
        return String(repeating: "\t", count: tabCount) + String(repeating: " ", count: spaceCount)
    }

    private static func updateContext(line: String,
                                      braceDepth: inout Int,
                                      parenStack: inout [Int],
                                      inheritanceIndent: inout Int?) {
        inheritanceIndent = nextInheritanceIndent(current: inheritanceIndent, line: line)

        var isInsideString = false
        var isEscaped = false
        let characters = Array(line)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if isInsideString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    isInsideString = false
                }
                index += 1
                continue
            }

            if character == "/" && index + 1 < characters.count && characters[index + 1] == "/" {
                break
            }

            switch character {
            case "\"":
                isInsideString = true
            case "(":
                parenStack.append(index + 1)
            case ")":
                if !parenStack.isEmpty {
                    parenStack.removeLast()
                }
            case "{":
                braceDepth += 1
            case "}":
                braceDepth = max(0, braceDepth - 1)
            default:
                break
            }

            index += 1
        }
    }

    private static func nextInheritanceIndent(current: Int?, line: String) -> Int? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        if trimmedLine.startsTypeDeclaration,
           let colonIndex = line.firstIndex(of: ":"),
           !trimmedLine.contains("{") || trimmedLine.hasSuffix(",") {
            let firstInheritedColumn = line.distance(from: line.startIndex, to: colonIndex) + 2
            return firstInheritedColumn
        }

        if current != nil && trimmedLine.contains("{") {
            return nil
        }

        return current
    }
}

private enum SwiftSyntaxStructureParser {
    static func makeRoot(source: String) -> SwiftNode {
        let sourceFile = Parser.parse(source: source)
        var substructures: [SwiftNode] = []

        for statement in sourceFile.statements {
            if let decl = statement.item.as(DeclSyntax.self) {
                substructures.append(contentsOf: parseDecl(decl, source: source))
            }
        }

        return SwiftNode(
            name: "",
            typeName: "",
            kind: "source.lang.swift.decl.root",
            offset: 0,
            length: source.lengthOfBytes(using: .utf8),
            nameOffset: 0,
            nameLength: 0,
            bodyOffset: 0,
            bodyLength: source.lengthOfBytes(using: .utf8),
            attributes: [],
            inheritedTypes: [],
            substructures: substructures,
            isEmpty: false
        )
    }

    private static func parseDecl(_ decl: DeclSyntax, source: String) -> [SwiftNode] {
        if let protocolDecl = decl.as(ProtocolDeclSyntax.self) {
            return [parseProtocol(protocolDecl, source: source)]
        }
        if let classDecl = decl.as(ClassDeclSyntax.self) {
            return [parseClass(classDecl, source: source)]
        }
        if let structDecl = decl.as(StructDeclSyntax.self) {
            return [parseStruct(structDecl, source: source)]
        }
        if let extensionDecl = decl.as(ExtensionDeclSyntax.self) {
            return [parseExtension(extensionDecl, source: source)]
        }
        if let variableDecl = decl.as(VariableDeclSyntax.self) {
            return parseVar(variableDecl, as: .varInstance)
        }
        if let initializerDecl = decl.as(InitializerDeclSyntax.self) {
            return [parseInitializer(initializerDecl, source: source)]
        }
        if let functionDecl = decl.as(FunctionDeclSyntax.self) {
            return [parseFunction(functionDecl, source: source)]
        }
        return []
    }

    private static func parseProtocol(_ node: ProtocolDeclSyntax, source: String) -> SwiftNode {
        let children = node.memberBlock.members.flatMap { parseDecl($0.decl, source: source) }
        return makeDeclNode(
            name: node.name.text,
            kind: SwiftDeclarationKind.protocol.rawValue,
            syntax: Syntax(node),
            nameSyntax: Syntax(node.name),
            bodySyntax: Syntax(node.memberBlock),
            attributes: parseAttributes(node.attributes),
            inheritedTypes: parseInheritedTypes(node.inheritanceClause),
            children: children
        )
    }

    private static func parseClass(_ node: ClassDeclSyntax, source: String) -> SwiftNode {
        let children = node.memberBlock.members.flatMap { parseDecl($0.decl, source: source) }
        return makeDeclNode(
            name: node.name.text,
            kind: SwiftDeclarationKind.class.rawValue,
            syntax: Syntax(node),
            nameSyntax: Syntax(node.name),
            bodySyntax: Syntax(node.memberBlock),
            attributes: parseAttributes(node.attributes),
            inheritedTypes: parseInheritedTypes(node.inheritanceClause),
            children: children
        )
    }

    private static func parseStruct(_ node: StructDeclSyntax, source: String) -> SwiftNode {
        let children = node.memberBlock.members.flatMap { parseDecl($0.decl, source: source) }
        return makeDeclNode(
            name: node.name.text,
            kind: SwiftDeclarationKind.struct.rawValue,
            syntax: Syntax(node),
            nameSyntax: Syntax(node.name),
            bodySyntax: Syntax(node.memberBlock),
            attributes: parseAttributes(node.attributes),
            inheritedTypes: parseInheritedTypes(node.inheritanceClause),
            children: children
        )
    }

    private static func parseExtension(_ node: ExtensionDeclSyntax, source: String) -> SwiftNode {
        let children = node.memberBlock.members.flatMap { parseDecl($0.decl, source: source) }
        return makeDeclNode(
            name: node.extendedType.trimmedDescription,
            kind: SwiftDeclarationKind.extension.rawValue,
            syntax: Syntax(node),
            nameSyntax: Syntax(node.extendedType),
            bodySyntax: Syntax(node.memberBlock),
            attributes: parseAttributes(node.attributes),
            inheritedTypes: parseInheritedTypes(node.inheritanceClause),
            children: children
        )
    }

    private static func parseVar(_ node: VariableDeclSyntax, as kind: SwiftDeclarationKind) -> [SwiftNode] {
        node.bindings.compactMap { binding in
            guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                return nil
            }

            return makeDeclNode(
                name: identifierPattern.identifier.text,
                kind: kind.rawValue,
                syntax: Syntax(binding),
                nameSyntax: Syntax(identifierPattern.identifier),
                bodySyntax: nil,
                typeName: binding.typeAnnotation?.type.trimmedDescription ?? "",
                attributes: [],
                inheritedTypes: [],
                children: []
            )
        }
    }

    private static func parseInitializer(_ node: InitializerDeclSyntax, source: String) -> SwiftNode {
        let parameterNodes = parseParameters(node.signature.parameterClause.parameters)
        let callNodes = parseCallNodes(node.body, source: source)
        let children = parameterNodes + callNodes
        let labels = node.signature.parameterClause.parameters.map { parameterLabel(for: $0) }.joined()

        return makeDeclNode(
            name: "init(\(labels))",
            kind: SwiftDeclarationKind.functionConstructor.rawValue,
            syntax: Syntax(node),
            nameSyntax: Syntax(node.initKeyword),
            bodySyntax: node.body.map { Syntax($0) },
            attributes: parseDeclarationAttributes(attributes: node.attributes, modifiers: node.modifiers),
            inheritedTypes: [],
            children: children
        )
    }

    private static func parseFunction(_ node: FunctionDeclSyntax, source: String) -> SwiftNode {
        let parameterNodes = parseParameters(node.signature.parameterClause.parameters)
        let callNodes = parseCallNodes(node.body, source: source)
        let children = parameterNodes + callNodes
        let labels = node.signature.parameterClause.parameters.map { parameterLabel(for: $0) }.joined()

        return makeDeclNode(
            name: "\(node.name.text)(\(labels))",
            kind: SwiftDeclarationKind.functionMethodInstance.rawValue,
            syntax: Syntax(node),
            nameSyntax: Syntax(node.name),
            bodySyntax: node.body.map { Syntax($0) },
            typeName: node.signature.returnClause?.type.trimmedDescription ?? "",
            attributes: parseDeclarationAttributes(attributes: node.attributes, modifiers: node.modifiers),
            inheritedTypes: [],
            children: children
        )
    }

    private static func parameterLabel(for parameter: FunctionParameterSyntax) -> String {
        let label = parameter.firstName.text
        if label == "_" {
            return "_:"
        }
        return "\(label):"
    }

    private static func parseParameters(_ parameters: FunctionParameterListSyntax) -> [SwiftNode] {
        parameters.map { parameter in
            let parameterNameToken = parameter.secondName ?? parameter.firstName
            let parameterName: String
            if let secondName = parameter.secondName, secondName.text != "_" {
                parameterName = secondName.text
            } else {
                parameterName = parameter.firstName.text
            }

            return makeDeclNode(
                name: parameterName,
                kind: SwiftDeclarationKind.varParameter.rawValue,
                syntax: Syntax(parameter),
                nameSyntax: Syntax(parameterNameToken),
                bodySyntax: nil,
                typeName: parameter.type.trimmedDescription,
                attributes: [],
                inheritedTypes: [],
                children: []
            )
        }
    }

    private static func parseCallNodes(_ body: CodeBlockSyntax?, source: String) -> [SwiftNode] {
        guard let body else {
            return []
        }
        let collector = CallCollector(source: source)
        collector.walk(Syntax(body))
        return collector.collectedCalls
    }

    private static func parseAttributes(_ attributes: AttributeListSyntax?) -> [SwiftAttribute] {
        guard let attributes else {
            return []
        }

        var result: [SwiftAttribute] = []
        for attributeElement in attributes {
            guard let attribute = attributeElement.as(AttributeSyntax.self) else {
                continue
            }
            if attribute.attributeName.trimmedDescription == "override" {
                result.append(SwiftAttribute(kind: .override))
            }
        }
        return result
    }

    private static func parseDeclarationAttributes(attributes: AttributeListSyntax?,
                                                   modifiers: DeclModifierListSyntax?) -> [SwiftAttribute] {
        var result = parseAttributes(attributes)
        result.append(contentsOf: parseModifiers(modifiers))
        return result
    }

    private static func parseModifiers(_ modifiers: DeclModifierListSyntax?) -> [SwiftAttribute] {
        guard let modifiers else {
            return []
        }
        return modifiers.compactMap { modifier in
            modifier.name.text == "override" ? SwiftAttribute(kind: .override) : nil
        }
    }

    private static func parseInheritedTypes(_ inheritance: InheritanceClauseSyntax?) -> [SwiftInheritedType] {
        guard let inheritance else {
            return []
        }
        return inheritance.inheritedTypes.map { inheritedType in
            SwiftInheritedType(name: inheritedType.type.trimmedDescription)
        }
    }

    private static func makeDeclNode(name: String,
                                     kind: String,
                                     syntax: Syntax,
                                     nameSyntax: Syntax?,
                                     bodySyntax: Syntax?,
                                     typeName: String = "",
                                     attributes: [SwiftAttribute],
                                     inheritedTypes: [SwiftInheritedType],
                                     children: [SwiftNode]) -> SwiftNode {
        let offset = startOffset(of: syntax)
        let end = endOffset(of: syntax)
        let nameOffset = nameSyntax.map(startOffset(of:)) ?? offset
        let nameLength = name.lengthOfBytes(using: .utf8)
        let bodyRange = bodySyntax.flatMap(extractBodyRange(of:)) ?? (offset: 0, length: 0)

        return SwiftNode(
            name: name,
            typeName: typeName,
            kind: kind,
            offset: offset,
            length: max(0, end - offset),
            nameOffset: nameOffset,
            nameLength: nameLength,
            bodyOffset: bodyRange.offset,
            bodyLength: bodyRange.length,
            attributes: attributes,
            inheritedTypes: inheritedTypes,
            substructures: children,
            isEmpty: false
        )
    }

    private static func startOffset(of syntax: Syntax) -> Int {
        syntax.positionAfterSkippingLeadingTrivia.utf8Offset
    }

    private static func endOffset(of syntax: Syntax) -> Int {
        syntax.endPositionBeforeTrailingTrivia.utf8Offset
    }

    private static func extractBodyRange(of syntax: Syntax) -> (offset: Int, length: Int)? {
        if let memberBlock = syntax.as(MemberBlockSyntax.self) {
            let offset = memberBlock.leftBrace.endPositionBeforeTrailingTrivia.utf8Offset
            let end = memberBlock.rightBrace.positionAfterSkippingLeadingTrivia.utf8Offset
            return (offset, max(0, end - offset))
        }

        if let codeBlock = syntax.as(CodeBlockSyntax.self) {
            let offset = codeBlock.leftBrace.endPositionBeforeTrailingTrivia.utf8Offset
            let end = codeBlock.rightBrace.positionAfterSkippingLeadingTrivia.utf8Offset
            return (offset, max(0, end - offset))
        }

        return nil
    }
}

private final class CallCollector: SyntaxVisitor {
    private let source: String
    fileprivate var collectedCalls: [SwiftNode] = []

    init(source: String) {
        self.source = source
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        collectedCalls.append(parseCall(node))
        return .visitChildren
    }

    private func parseCall(_ node: FunctionCallExprSyntax) -> SwiftNode {
        let offset = node.positionAfterSkippingLeadingTrivia.utf8Offset
        let end = node.endPositionBeforeTrailingTrivia.utf8Offset
        let calledExpression = node.calledExpression.trimmedDescription
        let arguments: [SwiftNode] = node.arguments.map { argument in
            let argumentOffset = argument.positionAfterSkippingLeadingTrivia.utf8Offset
            let argumentEnd = argument.endPositionBeforeTrailingTrivia.utf8Offset
            let argumentName = argument.label?.text ?? ""
            return SwiftNode(
                name: argumentName,
                typeName: argument.expression.trimmedDescription,
                kind: SwiftSyntaxExpressionKind.argument.rawValue,
                offset: argumentOffset,
                length: max(0, argumentEnd - argumentOffset),
                nameOffset: argumentOffset,
                nameLength: argumentName.lengthOfBytes(using: .utf8),
                bodyOffset: 0,
                bodyLength: 0,
                attributes: [],
                inheritedTypes: [],
                substructures: [],
                isEmpty: false
            )
        }

        var bodyOffset = offset
        var bodyLength = 0
        if let range = callBodyRange(offset: offset, length: max(0, end - offset)) {
            bodyOffset = range.location
            bodyLength = range.length
        }

        return SwiftNode(
            name: calledExpression,
            typeName: "",
            kind: SwiftSyntaxExpressionKind.call.rawValue,
            offset: offset,
            length: max(0, end - offset),
            nameOffset: offset,
            nameLength: calledExpression.lengthOfBytes(using: .utf8),
            bodyOffset: bodyOffset,
            bodyLength: bodyLength,
            attributes: [],
            inheritedTypes: [],
            substructures: arguments,
            isEmpty: false
        )
    }

    private func callBodyRange(offset: Int, length: Int) -> (location: Int, length: Int)? {
        guard length > 0 else {
            return nil
        }
        guard let callText = source.utf8Substring(start: offset, length: length) else {
            return nil
        }
        guard let openParen = callText.firstIndex(of: "("),
              let closeParen = callText.lastIndex(of: ")") else {
            return nil
        }
        let openOffset = callText.distance(from: callText.startIndex, to: openParen)
        let closeOffset = callText.distance(from: callText.startIndex, to: closeParen)
        let bodyStart = offset + openOffset + 1
        let bodyLength = max(0, closeOffset - openOffset - 1)
        return (location: bodyStart, length: bodyLength)
    }
}

private extension StringProtocol {
    var removingTrailingWhitespace: String {
        var result = String(self)
        while let last = result.last, last == " " || last == "\t" {
            result.removeLast()
        }
        return result
    }
}

private extension String {
    var startsTypeDeclaration: Bool {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("protocol ")
            || trimmed.hasPrefix("class ")
            || trimmed.hasPrefix("struct ")
            || trimmed.hasPrefix("extension ")
    }

    var leadingClosingBraceCount: Int {
        var count = 0
        for character in trimmingCharacters(in: .whitespaces) {
            if character == "}" {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    func utf8Substring(start: Int, length: Int) -> String? {
        guard start >= 0, length >= 0 else {
            return nil
        }
        guard start <= utf8.count, start + length <= utf8.count else {
            return nil
        }
        let startIndex = utf8.index(utf8.startIndex, offsetBy: start)
        let endIndex = utf8.index(startIndex, offsetBy: length)
        return String(decoding: utf8[startIndex..<endIndex], as: UTF8.self)
    }
}
