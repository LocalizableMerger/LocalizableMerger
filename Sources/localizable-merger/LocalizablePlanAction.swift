import Foundation

class LocalizablePlanAction{
    struct ActionPlan {
        enum Action{
            case generate
            case ignoreNoBaseFile
        }
        let base: LocalizableFile?
        let compare: LocalizableFile?
        let generate: LocalizableFile?
        let action: Action
        
    }
    
    func generateActionPlan(_ files: [LocalizableFile]) -> [ActionPlan]{
        let base = files.filter({ $0.isBase })
        let compare = files.filter({ !$0.isBase })
        
        return compare.map { (localizable) -> ActionPlan in
            let baseLanguage:LocalizableFile? = base.first(where: {$0.language == localizable.language})
            let generatedFile = LocalizableFile(language: localizable.language, url: self.generateGeneratedFilePath(origin: localizable), isBase: false)
            return ActionPlan(base: baseLanguage,
                       compare: localizable,
                       generate: baseLanguage != nil ? generatedFile : nil,
                       action: baseLanguage == nil ? ActionPlan.Action.ignoreNoBaseFile : .generate)
        }
    }
    
    fileprivate func generateGeneratedFilePath(origin: LocalizableFile) -> String{
        return origin.url.replacingOccurrences(of: ".strings", with: "_generated.strings")
    }
}
