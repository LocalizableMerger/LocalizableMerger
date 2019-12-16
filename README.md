# Localizable Merger

## Purpose

The purpose of this tool is to help to mantain Localizable.strings of Xcode projects when you have multiple targets in the same project and you want to define a base Localizable and change only several strings for child targets. This avoids copy and paste of multiple files. 

## Install

### Mint

You can install it using Mint

```
mint install LocalizableMerger/LocalizableMerger
```


## How to use it


You can execute localizable merge using this command from the root folder of your project

`localizable-merger --baseFolder <Folder where base Localizable Strings are placed>`

For example

`localizable-merger --baseFolder project/Localizables`


## What it does?

Localizable Merger look into your project folders looking for \*.string files. Files that are on the base folder at taken as reference files so if one localizable key is not in your specific Localizable file and it's on the base files will be copied to the generated file

For an example you can see the example folder:

-  Example/Base/en.lproj/Localizable.string
-  Example/Base/es.lproj/Localizable.string
-  Example/AppA/en.lproj/Localizable.string
-  Example/AppB/en.lproj/Localizable.string
-  Example/AppB/es.lproj/Localizable.string

Base Localizable in English is:

```
"key_1" = "Hello World";
"key_2" = "Welcome to Base App";
"key_3" = "Finish app";
```

App A Localizable in English is:

```
"key_2" = "Welcome to App A";
```

After Localizable Merger execution will create a new file, `Example/AppA/en.lproj/Localizable_generated.string` and will have this structure:

```
"key_1" = "Hello World";
"key_2" = "Welcome to App A";
"key_3" = "Finish app";
```

On each execution generated files will be updated with new localizables.


## TODO

- Add generated header on generated files to inform that this file should not be edit manually
- Extend YAML file with sort options
	- Give option of sort base file
- Add tests
- Refactor main file
- Test integration with other tools (Tuist) 
