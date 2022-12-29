import Crypto
import Foundation

import Gardener
import KeychainTypes

public class Keychain: Codable, KeychainProtocol
{
    public var keychainURL: URL
    
    public init?(baseDirectory: URL)
    {
        // Make sure that the base directory selected by the user already exists.
        // Fail if it doesn't.
        if !File.exists(baseDirectory.path)
        {
            guard File.makeDirectory(url: baseDirectory) else
            {
                print("Unable to initialize keychain, the selected directory does not exist and could not be created.")
                return nil
            }
        }
        
        // Append keychain directory to the base url provided
        keychainURL = baseDirectory.appendingPathComponent("keychain")
        
        // Check if the directory exists
        if !FileManager.default.fileExists(atPath: keychainURL.path)
        {
            // If it does not, create it.
            do
            {
                // Create a keychain directory that has permissions set to read and write for the user only
                try FileManager.default.createDirectory(at: keychainURL, withIntermediateDirectories: false, attributes: [.posixPermissions : 0o700])
            }
            catch let createDirectoryError
            {
                print("Unable to initialize the keychain, we were unable to create the keychain directory.")
                print("Directory creation error: \(createDirectoryError)")
                return nil
            }
        }
    }
    
    public func retrieveOrGeneratePrivateKey(label: String, type: KeyType) -> PrivateKey?
    {
        // Do we already have a key?
        if let key = retrievePrivateKey(label: label, type: type)
        {
            guard key.type == type else
            {
                return nil
            }

            return key
        }

        do
        {
            // We don't?
            // Let's create some and return those
            var privateKey: PrivateKey? = nil
            while privateKey == nil
            {
                let tempPrivateKey = try PrivateKey(type: type)
                guard tempPrivateKey.data != nil else
                {
                    continue
                }
                privateKey = tempPrivateKey
            }

            guard let privateKey = privateKey else
            {
                return nil
            }
            // Save the key we stored
            let stored = storePrivateKey(privateKey, label: label)
            if !stored
            {
                print("😱 Failed to store our new server key.")
                return nil
            }
            return privateKey
        }
        catch
        {
            return nil
        }
    }
    
    public func generateAndSavePrivateKey(label: String, type: KeyType) -> PrivateKey?
    {
        do
        {
            var privateKey: PrivateKey? = nil
            while privateKey == nil
            {
                let tempPrivateKey = try PrivateKey.new(type: type)
                guard tempPrivateKey.data != nil else
                {
                    continue
                }
                privateKey = tempPrivateKey
            }

            guard let privateKey = privateKey else
            {
                return nil
            }
            // Save the key we stored
            let stored = storePrivateKey(privateKey, label: label)
            if !stored
            {
                print("😱 Failed to store our new server key.")
                return nil
            }

            return privateKey
        }
        catch
        {
            return nil
        }
    }
    
    public func storePrivateKey(_ key: PrivateKey, label: String) -> Bool
    {
        guard let keyData = key.typedData else
        {
            return false
        }
        let fileURL = keychainURL.appendingPathComponent("\(label).private")
        
        // Create a file with posix file permission set to "-rw-------"
        // non-directory, read and write for the owner of the file only, no one else can see that file exists (except root)
        return FileManager.default.createFile(atPath: fileURL.path, contents: keyData, attributes: [.posixPermissions : 0o600])
    }
    
    public func retrievePrivateKey(label: String, type: KeyType) -> PrivateKey?
    {
        let fileURL = keychainURL.appendingPathComponent("\(label).private")
        
        do
        {
            // Make sure that permissions have not been altered for the directory
            let directoryAttributes = try FileManager.default.attributesOfItem(atPath: keychainURL.path)
            let directoryPosixPermissions = directoryAttributes[.posixPermissions]
            
            guard directoryPosixPermissions as? Int == 0o700
            else
            {
                print("Unable to retrieve the private key, the keychain directory permissions have been changed.")
                return nil
            }
    
            // Make sure that permissions have not been altered for the key file
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let filePosixPermissions = fileAttributes[.posixPermissions]
            
            guard filePosixPermissions as? Int == 0o600
            else
            {
                print("Unable to retrieve the private key, the key file permissions have been changed.")
                return nil
            }
        }
        catch let permissionsError
        {
            print("Error checking permission: \(permissionsError)" )
            return nil
        }
         
        do
        {
            let keyData = try Data(contentsOf: fileURL, options: .uncached)
            let privateKey = try PrivateKey(typedData: keyData)
            
            return privateKey
        }
        catch let retrieveDataError
        {
            print("Error retrieving key: \(retrieveDataError)")
            return nil
        }
    }
    
    public func deleteKey(label: String)
    {
        let fileURL = keychainURL.appendingPathComponent("\(label).private")
        
        // TODO: Secure delete
        do
        {
            try FileManager.default.removeItem(at: fileURL)
        }
        catch let removeFileError
        {
            print("Error attempting to remove private key file: \(removeFileError)")
        }
    }
}
