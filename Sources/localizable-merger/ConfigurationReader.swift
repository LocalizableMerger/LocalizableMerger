import Foundation

protocol ConfigurationReader {
    func read(file: URL, originConfiguration: Configuration) -> Configuration
}
