import Foundation

class LocalizableFileWriter{
    let configuration: Configuration
    
    init(configuration:Configuration){
        self.configuration = configuration
    }
    func write(dict:[String: String], actionPlan: LocalizablePlanAction.ActionPlan){
        guard let generatedUrl = actionPlan.generate?.url else{
            return
        }
        let dictToString = dict.sorted(by: { (keyValue1, keyValue2) -> Bool in
            let (key1, _) = keyValue1
            let (key2, _) = keyValue2
            return key1 < key2
        }).reduce("") { (str, arg1) -> String in
            let (key, value) = arg1
            let line = "\"\(key)\" = \"\(value)\";\n"
            return str + line
        }
        let baseURL = URL(fileURLWithPath: configuration.workingDirectory, isDirectory: true)
        if #available(OSX 10.11, *) {
            let absoluteURL = URL(fileURLWithPath: generatedUrl, isDirectory: false, relativeTo: baseURL)
            print(absoluteURL.absoluteString)
            do{
                try dictToString.write(to: absoluteURL, atomically: true, encoding: .utf8)
            }catch{
                print(error)
            }
            

        } else {
            // Fallback on earlier versions
        }
    }
}
