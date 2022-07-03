import Foundation

/// @mockable
public protocol FileManagerProtocol {
  func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL
}

extension FileManager: FileManagerProtocol {}
