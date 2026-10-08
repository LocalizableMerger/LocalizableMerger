import Foundation
import PackagePlugin

/// The `merge-localizables` command. It runs `localizable-merger` in the package directory.
///
/// The plugin sends all arguments to the tool. A `--work-directory` argument from the user wins.
@main
struct LocalizableMergerPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "localizable-merger")
        let process = Process()
        process.executableURL = tool.url
        process.currentDirectoryURL = context.package.directoryURL
        process.arguments = ["--work-directory", context.package.directoryURL.path] + arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            throw PluginError.toolFailed(exitCode: process.terminationStatus)
        }
    }
}

enum PluginError: Error, CustomStringConvertible {
    case toolFailed(exitCode: Int32)

    var description: String {
        switch self {
        case .toolFailed(let exitCode): "localizable-merger failed with exit code \(exitCode)."
        }
    }
}
