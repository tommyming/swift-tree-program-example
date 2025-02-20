// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import PathKit

@main
struct Tree: ParsableCommand {
    @Argument
    var path: Path = .current

    func run() throws {
        print(path.absolute().string)
        try path.listChildren()
    }

    func validate() throws {
        if !path.exists {
            throw Error.invalidPath(path)
        }

        if !path.isDirectory {
            throw Error.notADirectory(path)
        }
    }
}

extension Path: @retroactive ExpressibleByArgument, @unchecked @retroactive Sendable {
    public init(argument: String) {
        self = Path(argument)
    }
}

extension Tree {
    enum Error: Swift.Error {
        case invalidPath(Path)
        case notADirectory(Path)
    }
}

extension Tree.Error: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidPath(let path):
            return "Invalid path: \(path.absolute().string)"
        case .notADirectory(let path):
            return "Not a directory: \(path.absolute().string)"
        }
    }
}

extension Path {
    func listChildren(ancestors: [IsLastChild] = []) throws {
        let children = try children().sorted()
        let lastIndex = children.count - 1

        let enumeratedChildren = children.enumerated()
        try enumeratedChildren.forEach { index, child in
            let isLast = (index == lastIndex)

            if child.lastComponent.hasPrefix(".") { return }

            let indentation = String.indentation(isLast: isLast, ancestors: ancestors)

            if child.isFile {
                print(indentation, child.lastComponent)
            } else {
                print(indentation, child.lastComponent)
                var updatedAncestors = ancestors
                updatedAncestors.append(isLast)
                try child.listChildren(ancestors: updatedAncestors)
            }
        } 
    }
}

typealias IsLastChild = Bool

extension String {
    static let levelLine = "│   "
    static let child     = "├──"
    static let lastChild = "└──"
    static let lastChildSpacing = "    "

    static func indentation(
        isLast: IsLastChild,
        ancestors: [IsLastChild]
    ) -> String {
        var indentation = ""

        ancestors.forEach { isLastAncestor in
            if isLastAncestor {
                indentation.append(lastChildSpacing) 
            } else {
                indentation.append(levelLine)
            }
        }

        if isLast {
            indentation.append(lastChild)
        } else {
            indentation.append(child)
        }

        return indentation
    }
}

