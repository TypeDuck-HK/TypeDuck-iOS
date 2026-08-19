//
//  DataInstaller.swift
//  CantoboardFramework
//
//  Created by Alex Man on 5/4/21.
//

import Foundation

import CocoaLumberjackSwift

class DataFileManager {
    static let hasInstalled: Bool = installIfNeeded()

    static let resourceDirectory = getResourcePath()
    static let dataResourceDirectory = "\(resourceDirectory)/Data"
    static let rimeSharedDirectory = "\(dataResourceDirectory)/Rime"
    static let installToCacheDirectory = "\(dataResourceDirectory)/InstallToCache"
    
    static let cacheDirectory = getCachePath()
    static let cacheDataDirectory = "\(cacheDirectory)/Data"
    static let logsDirectory = "\(cacheDirectory)/Logs"
    static let builtInEnglishDictDirectory = "\(cacheDataDirectory)/EnglishDict"
    static let builtInUnihanDictDirectory = "\(cacheDataDirectory)/Unihan"
    static let builtInNGramDictDirectory = "\(cacheDataDirectory)/NGram"
    static let versionFilePath = "\(cacheDataDirectory)/version"
    
    static let documentDirectory = getDocumentDirectoryPath()
    static let userDataDirectory = "\(documentDirectory)/UserData"
    static let englishUserDictPath = "\(userDataDirectory)/EnglishUserDict"
    static let rimeUserDirectory = "\(userDataDirectory)/Rime"
    static let rimeBuildCacheDirectory = "\(rimeUserDirectory)/build"

    static let migrationEnglishUserDirectory = "\(documentDirectory)/RimeUserData/UserDict"
    static let migrationRimeUserDirectory = "\(documentDirectory)/RimeUserData"
    
    static let appVersion = getAppVersion()
    
    static private func installIfNeeded() -> Bool {
        if isInstalledDataOutdated() {
            DDLogInfo("Installing data file from \(installToCacheDirectory) to \(cacheDataDirectory).")
            let fileManager = FileManager.default
            // Remove stale data cache.
            try? fileManager.removeItem(atPath: cacheDataDirectory)
            // Install new data cache.
            do {
                try fileManager.copyItem(atPath: installToCacheDirectory, toPath: cacheDataDirectory)
            } catch {
                DDLogError("Failed to install data files: \(error)")
                return false
            }
            // Create user data directory if it doesn't exist.
            try? fileManager.createDirectory(atPath: userDataDirectory, withIntermediateDirectories: false, attributes: nil)
            // One off migration. Remove it later.
            try? fileManager.moveItem(atPath: migrationEnglishUserDirectory, toPath: englishUserDictPath)
            try? fileManager.moveItem(atPath: migrationRimeUserDirectory, toPath: rimeUserDirectory)
            // Invalidate Rime build cache on upgrade.
            try? fileManager.removeItem(atPath: rimeBuildCacheDirectory)
            try? appVersion.write(toFile: versionFilePath, atomically: true, encoding: .utf8)
            // Slow start to regenerate schema when the app is updated.
            RimeApi.removeQuickStartFlagFile()
        }
        return true
    }

    private static func getResourcePath() -> String {
        guard let path = Bundle.init(for: Self.self).resourcePath else {
            DDLogError("Bundle.resourcePath is nil - this indicates a corrupted app bundle")
            assertionFailure("Bundle.resourcePath is nil")
            return NSTemporaryDirectory()
        }
        return path
    }

    private static func getDocumentDirectoryPath() -> String {
        guard let path = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            DDLogError("Unable to find documentDirectory - this indicates a critical iOS error")
            assertionFailure("Unable to find documentDirectory")
            return NSTemporaryDirectory()
        }
        return path.path
    }
    
    private static func getCachePath() -> String {
        guard let path = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            DDLogError("Unable to find cachesDirectory - this indicates a critical iOS error")
            assertionFailure("Unable to find cachesDirectory")
            return NSTemporaryDirectory()
        }
        return path.path
    }
    
    private static func isInstalledDataOutdated() -> Bool {
        let installedDataVersion = getInstalledDataVersion()
        let isOutdated = appVersion != installedDataVersion
        
        if isOutdated {
            DDLogInfo("Installed data file is outdated. App version: \(appVersion) to installed data version: \(installedDataVersion).")
        }
        return isOutdated
    }
    
    private static func getAppVersion() -> String {
        if let dict = Bundle.main.infoDictionary,
           let version = dict["CFBundleShortVersionString"] as? String,
           let bundleVersion = dict["CFBundleVersion"] as? String {
                return "\(version).\(bundleVersion)"
        }
        return "unknown"
    }
    
    private static func getInstalledDataVersion() -> String {
        return (try? String(contentsOfFile: versionFilePath)) ?? "missing"
    }
}
