//
//  SwiftExpressionKind.swift
//  RIBsCodeGen
//
//  Created by 今入　庸介 on 2021/02/04.
//
// cf. https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Extensions/SwiftExpressionKind.swift

import Foundation

enum SwiftExpressionKind: String {
    /// A call to a named function or closure.
    case call = "source.lang.swift.expr.call"
    /// An argument value for a function or closure.
    case argument = "source.lang.swift.expr.argument"
    /// An Array expression.
    case array = "source.lang.swift.expr.array"
    /// A Dictionary expression.
    case dictionary = "source.lang.swift.expr.dictionary"
    /// An object literal expression. https://developer.apple.com/swift/blog/?id=33
    case objectLiteral = "source.lang.swift.expr.object_literal"
    /// A closure expression. https://docs.swift.org/swift-book/LanguageGuide/Closures.html
    case closure = "source.lang.swift.expr.closure"
    /// A tuple expression. https://docs.swift.org/swift-book/ReferenceManual/Types.html#ID448
    case tuple = "source.lang.swift.expr.tuple"
}
