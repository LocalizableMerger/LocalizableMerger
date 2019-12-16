import Foundation
import Guaka
if #available(OSX 10.11, *) {

enum Flags: String, CaseIterable{
    case workDirectory
    case baseFolder
    case configFile
    
    var description: String{
        switch self{
        case .workDirectory:
            return "Enter the path of your project"
        case .baseFolder:
            return "Enter the path of the baseFolder"
        case .configFile:
            return "Enter the path of the LocalizableMerge.yml"
        }
    }
    var defaultValue: String{
        switch self{
        case .workDirectory:
            return FileManager.default.currentDirectoryPath
        case .baseFolder:
            return ""
        case .configFile:
            return "LocalizableMerger.yml"
        }
    }
}

let command = Command(usage: "localizable-merger") { flags, args in
    guard let workingDirectory = flags.getString(name: Flags.workDirectory.rawValue) else{
        return
    }
    var configuration: Configuration
    if let baseFolderPath = flags.getString(name: Flags.baseFolder.rawValue){
        configuration = Configuration(workingDirectory: workingDirectory, baseFolder: baseFolderPath)
    }else{
        configuration = Configuration(workingDirectory: workingDirectory, baseFolder: "")
    }
    
    if let config = flags.getString(name: Flags.configFile.rawValue){
        let configFilePath = URL(fileURLWithPath: config, isDirectory: false, relativeTo: URL(fileURLWithPath: workingDirectory, isDirectory: true))
        if FileManager.default.fileExists(atPath: configFilePath.absoluteString){
            configuration = YAMLConfigurationReader().read(file: configFilePath, originConfiguration: configuration)
        }
    }
    if configuration.baseFolder.isEmpty{
        print("Error base folder not set")
    }
    print(configuration)
    execute(configuration: configuration)
}
Flags.allCases.map { (flag) -> Flag in
    return Flag(longName: flag.rawValue, value: flag.defaultValue,
         description: flag.description, inheritable: true)
}.forEach(command.add)

command.execute()
    
func execute(configuration: Configuration){
    let files = LocalizeFiles(configuration: configuration).localizeLanguages(URL(string:configuration.workingDirectory)!)
    let actionPlan = LocalizablePlanAction().generateActionPlan(files).filter({ $0.action == .generate})
    let reader = LocalizableFileReader(configuration: configuration)
    let writer = LocalizableFileWriter(configuration: configuration)

    actionPlan.forEach { (plan) in
        let merged = reader.merge(actionPlan: plan)
        writer.write(dict: merged, actionPlan: plan)
    }
}

}
