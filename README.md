# Localizable Merger

## Purpose

The purpose of this tool is to help to mantain Localizable.strings of Xcode projects when you have multiple targets in the same projects and you want to define a base Localizable and change only several strings for child targets. This avoids copy and paste of multiple files. 

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

Localizable Merger look into your project folders looking for \*.string files. Files that are on the base folder at took as reference files so if one localizable key is not in your specific Localizable file and it's on the base files.

For an example you can see the example folder:

-  Example/Base/en.lproj/Localizable.string
-  Example/Base/en.lproj/Localizable_B.string
-  Example/Base/es.lproj/Localizable.string
-  Example/Base/es.lproj/Localizable_B.string
-  Example/AppA/en.lproj/Localizable.string
-  Example/AppA/es.lproj/Localizable.string





