import GRDB

/// @mockable
public protocol PersistenceServiceWrite {
  func perform(in database: Database) throws
}

/// @mockable
public protocol PersistenceServiceRead {
  func perform(in database: Database) throws -> Model
  associatedtype Model
}

/// @mockable
public protocol PersistenceServiceMigration {
  func perform(in database: Database) throws
  var identifier: String { get }
}

/// @mockable
public protocol PersistenceService {
  var path: String? { get }
  func load(at path: String?) throws

  func performSync(_ write: PersistenceServiceWrite) throws
  func perform(_ write: PersistenceServiceWrite, completion: @escaping (Error?) -> Void)
  func perform(_ write: PersistenceServiceWrite) async throws

  func performSync<Read>(_ read: Read) throws -> Read.Model where Read: PersistenceServiceRead
  func perform<Read>(_ read: Read, completion: @escaping (Result<Read.Model, Error>) -> Void) where Read: PersistenceServiceRead
  func perform<Read>(_ read: Read) async throws -> Read.Model where Read: PersistenceServiceRead

  func observe<Read>(_ read: Read) -> AsyncThrowingStream<Read.Model, Error> where Read: PersistenceServiceRead
}
