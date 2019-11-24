import Foundation
import Yaml

class YAMLConfigurationReader: ConfigurationReader{
    
    func read(file: URL, originConfiguration: Configuration) -> Configuration {
        var updateConfiguration = originConfiguration
        do{
            let fileContent = try String(contentsOf: file)
            let yaml = try Yaml.load(fileContent)
            updateConfiguration.baseFolder = yaml["baseFolder"].string ?? originConfiguration.baseFolder
        }catch{
            // TODO: Handle errors
            print(error)
        }
        return updateConfiguration

    }
}
