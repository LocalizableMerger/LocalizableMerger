import Foundation

class LocalizeFiles{
    let configuration: Configuration
    
    init(configuration: Configuration){
        self.configuration = configuration
    }
    
    func localizeLanguages(_ originPath: URL) -> [LocalizableFile]{
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: originPath.absoluteString) else{
            return []
        }
        
        let objects = enumerator.allObjects
            .compactMap({ $0 as? String })
            .filter({ $0.hasSuffix(".strings") && !$0.hasSuffix("_generated.strings")})
            .compactMap({ self.generateObjectFrom(path: $0)})
        return objects
        
    }
    
    func generateObjectFrom(path: String) -> LocalizableFile?{
        guard let language = path.split(separator: "/").filter({ $0.hasSuffix("lproj")}).first?.split(separator: ".").first else{
            return nil
        }
        return LocalizableFile(language: String(language), url: path, isBase: path.contains(self.configuration.baseFolder))
        
    }
}
