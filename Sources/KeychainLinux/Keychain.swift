import Foundation

#if (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
import CryptoKit
#else
import Crypto
#endif

public class Keychain
{
    public var keychainURL: URL
    
    public init?(baseDirectory: URL)
    {
        // Make sure that the base directory selected by the user already exists.
        // Fail if it doesn't.
        guard FileManager.default.fileExists(atPath: baseDirectory.path)
        else
        {
            print("Unable to initialize keychain, the selected directory does not exist.")
            return nil
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
    
    public func retrieveOrGeneratePrivateKey(label: String) -> P256.KeyAgreement.PrivateKey?
    {
        if let privateKey = retrievePrivateKey(label: label)
        {
            return privateKey
        }
        else
        {
            return generateAndSavePrivateKey(label: label)
        }
    }
    
    public func generateAndSavePrivateKey(label: String) -> P256.KeyAgreement.PrivateKey?
    {
        let privateKey = P256.KeyAgreement.PrivateKey()
        
        // Save the key we stored
        let stored = storePrivateKey(privateKey, label: label)
        if !stored
        {
            print("😱 Failed to store our new server key.")
            return nil
        }
        
        return privateKey
    }
    
    public func storePrivateKey(_ key: P256.KeyAgreement.PrivateKey, label: String) -> Bool
    {
        let keyData = key.x963Representation
        let fileURL = keychainURL.appendingPathComponent("\(label).private")
        
        // Create a file with posix file permission set to "-rw-------"
        // non-directory, read and write for the owner of the file only, no one else can see that file exists (except root)
        return FileManager.default.createFile(atPath: fileURL.path, contents: keyData, attributes: [.posixPermissions : 0o600])
    }
    
    public func retrievePrivateKey(label: String) -> P256.KeyAgreement.PrivateKey?
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
            let privateKey = try P256.KeyAgreement.PrivateKey(x963Representation: keyData)
            
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
