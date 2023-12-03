import Foundation

/// @mockable
public protocol FileManagerProtocol {
  func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL?
}

extension FileManager: FileManagerProtocol {}
