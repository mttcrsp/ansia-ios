import Foundation
import GRDB

public final class PersistenceServiceLive: PersistenceService {
  private var database: DatabaseQueue?

  private let notificationCenter = NotificationCenter()
  private let migrations: [PersistenceServiceMigration]

  public init(migrations: [PersistenceServiceMigration]) {
    self.migrations = migrations
  }
}

public extension PersistenceServiceLive {
  var path: String? {
    database?.path
  }

  func load(at path: String?) throws {
    let database: DatabaseQueue
    if let path {
      database = try DatabaseQueue(path: path)
    } else {
      database = try DatabaseQueue()
    }

    var migrator = DatabaseMigrator()
    for migration in migrations {
      migrator.registerMigration(migration.identifier, migrate: migration.perform)
    }
    try migrator.migrate(database)

    self.database = database

    let notification = Notification(name: .didLoadDatabase, userInfo: ["database": database])
    notificationCenter.post(notification)
  }
}

public extension PersistenceServiceLive {
  func perform(_ write: PersistenceServiceWrite, completion: @escaping (Error?) -> Void) {
    withDatabase { database in
      database.asyncWrite { database in
        try write.perform(in: database)
      } completion: { _, result in
        switch result {
        case .success:
          completion(nil)
        case let .failure(error):
          completion(error)
        }
      }
    }
  }

  func perform<Read: PersistenceServiceRead>(_ read: Read, completion: @escaping (Result<Read.Model, Error>) -> Void) {
    withDatabase { database in
      database.asyncRead { result in
        switch result {
        case let .failure(error):
          completion(.failure(error))
        case let .success(database):
          do {
            completion(.success(try read.perform(in: database)))
          } catch {
            completion(.failure(error))
          }
        }
      }
    }
  }
}

public extension PersistenceServiceLive {
  func performSync(_ write: PersistenceServiceWrite) throws {
    let database = withDatabaseSync()
    try database.write(write.perform)
  }

  func performSync<Read: PersistenceServiceRead>(_ read: Read) throws -> Read.Model {
    let database = withDatabaseSync()
    return try database.read(read.perform)
  }
}

public extension PersistenceServiceLive {
  func perform(_ write: PersistenceServiceWrite) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      perform(write) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: ())
        }
      }
    }
  }

  func perform<Read: PersistenceServiceRead>(_ read: Read) async throws -> Read.Model {
    try await withCheckedThrowingContinuation { continuation in
      perform(read) { result in
        switch result {
        case let .failure(error):
          continuation.resume(throwing: error)
        case let .success(model):
          continuation.resume(returning: model)
        }
      }
    }
  }

  func observe<Read: PersistenceServiceRead>(_ read: Read) -> AsyncThrowingStream<Read.Model, Error> {
    .init { continuation in
      withDatabase { database in
        let cancellable = ValueObservation.tracking(read.perform)
          .start(in: database) { error in
            continuation.yield(with: .failure(error))
          } onChange: { model in
            continuation.yield(with: .success(model))
          }

        continuation.onTermination = { _ in
          cancellable.cancel()
        }
      }
    }
  }
}

private extension PersistenceServiceLive {
  func withDatabase(_ block: @escaping (DatabaseQueue) -> Void) {
    if let database {
      return block(database)
    }

    notificationCenter.addObserver(forName: .didLoadDatabase, object: nil, queue: nil) { notification in
      if let database = notification.userInfo?["database"] as? DatabaseQueue {
        block(database)
      } else {
        assertionFailure("Malformed notification received: missing database from userInfo")
      }
    }
  }

  func withDatabaseSync() -> DatabaseQueue {
    var database: DatabaseQueue!

    let semaphore = DispatchSemaphore(value: 0)
    let queue = DispatchQueue(label: "com.mttcrsp.ansia.PersistenceService.withDatabaseSync")

    queue.async {
      self.withDatabase { loadedDatabase in
        database = loadedDatabase
        semaphore.signal()
      }
    }

    semaphore.wait()

    return database
  }
}

private extension Notification.Name {
  static let didLoadDatabase = Notification.Name("com.mttcrsp.ansia.PersistenceService.didLoadDatabase")
}
