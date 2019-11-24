import Foundation

class LocalizableFileReader{
    let configuration: Configuration
    
    init(configuration: Configuration){
        self.configuration = configuration
    }
    func read(_ localizableFile: LocalizableFile) -> Dictionary<String, String>{
        if #available(OSX 10.11, *) {
            if let dict = NSDictionary(contentsOf: URL(fileURLWithPath: localizableFile.url, isDirectory: false, relativeTo: URL(fileURLWithPath: configuration.workingDirectory, isDirectory: true))) as? Dictionary<String, String>{
                return dict
            }else{
                print("Couldn't read \(localizableFile.url)")
                return [:]
            }
        } else {
            return [:]
        }
    }
    func merge(actionPlan: LocalizablePlanAction.ActionPlan) -> Dictionary<String, String>{
        guard let base = actionPlan.base, let compare = actionPlan.compare else{
            return [:]
        }
        return self.merge(base, compare: compare)
    }
    func merge(_ baseFile: LocalizableFile, compare: LocalizableFile) -> Dictionary<String, String>{
        let baseDict = self.read(baseFile)
        let compareDict = self.read(compare)
        // TODO: Get Warnings of keys of compare file that are not present on base file
        return baseDict.merging(compareDict) { (baseKey, compareKey) -> String in
            return compareKey
        }
    }
}
