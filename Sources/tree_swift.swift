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

    @OptionGroup
    var options: Options

    func run() throws {
        var files = 0
        var directories = 0

        print(path.absolute().string)
        try path.listChildren(
            filesCount: &files,
            directoriesCount: &directories,
            options: options
        )

        if !options.disableReport {
            print("\n")

            if files == 0 {
                print("\(directories) directories")
            } else {
                print("\(directories) directories, \(files) files")
            }
        }
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
    func listChildren(
        ancestors: [IsLastChild] = [],
        filesCount: inout Int,
        directoriesCount: inout Int,
        options: Tree.Options
    ) throws {
        directoriesCount += 1
        if let maxLevel = options.maxLevel, ancestors.count >= maxLevel {
            return 
        }

        var children = try children().sorted()
        if options.directoriesOnly {
            children = children.filter { $0.isDirectory }
        }

        let lastIndex = children.count - 1

        let enumeratedChildren = children.enumerated()
        try enumeratedChildren.forEach { index, child in
            let isLast = (index == lastIndex)

            if !options.includeHidden, child.lastComponent.hasPrefix(".") { return }

            let indentation = String.indentation(isLast: isLast, ancestors: ancestors)

            if child.isFile {
                print(indentation, child.lastComponent)
            } else {
                print(indentation, child.lastComponent.bold)
                var updatedAncestors = ancestors
                updatedAncestors.append(isLast)
                try child.listChildren(
                    ancestors: updatedAncestors,
                    filesCount: &filesCount,
                    directoriesCount: &directoriesCount,
                    options: options
                )
            }

            filesCount += 1
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

extension String {
    var bold: String {
        "\u{001B}[1m" + self + "\u{001B}[0m"
    }
}

extension Tree {
    struct Options: ParsableArguments {
        @Option(name: .customShort("L"))
        var maxLevel: Int?

        @Flag(name: .customShort("a"))
        var includeHidden = false

        @Flag(name: .customShort("d"))
        var directoriesOnly = false

        @Flag(name: .customLong("noreport"))
        var disableReport = false
    }   
}