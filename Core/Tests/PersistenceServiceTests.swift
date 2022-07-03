import Core
import GRDB
import XCTest

final class PersistenceServiceTests: XCTestCase {
  private var persistenceService: PersistenceServiceLive!

  override func setUp() {
    super.setUp()
    persistenceService = .init(migrations: [Migration()])
  }

  func testMigrationError() throws {
    let migrationError = CocoaError(.coderInvalidValue)
    let migration = PersistenceServiceMigrationMock()
    migration.performHandler = { _ in throw migrationError }

    let persistenceService = PersistenceServiceLive(migrations: [migration])
    XCTAssertThrowsError(try persistenceService.load(at: nil)) { error in
      XCTAssertEqual(error as? CocoaError, migrationError)
    }
  }

  func testSyncOperations() throws {
    try persistenceService.load(at: nil)

    let person1 = Person(name: "alice")
    let person2 = Person(name: "bob")
    let write1 = Write(person: person1)
    let write2 = Write(person: person2)

    try persistenceService.performSync(write1)
    let people1 = try persistenceService.performSync(Read())
    XCTAssertEqual(people1, [person1])

    try persistenceService.performSync(write2)
    let people2 = try persistenceService.performSync(Read())
    XCTAssertEqual(people2, [person1, person2])
  }

  func testOperations() async throws {
    try persistenceService.load(at: nil)

    let person1 = Person(name: "alice")
    let person2 = Person(name: "bob")
    let write1 = Write(person: person1)
    let write2 = Write(person: person2)

    try await persistenceService.perform(write1)
    let people1 = try await persistenceService.perform(Read())
    XCTAssertEqual(people1, [person1])

    try await persistenceService.perform(write2)
    let people2 = try await persistenceService.perform(Read())
    XCTAssertEqual(people2, [person1, person2])
  }

  func testQueuedOperations() throws {
    var result: Result<Read.Model, Error>?
    persistenceService.perform(Read()) { value in
      result = value
    }

    XCTAssertNil(result)
    try persistenceService.load(at: nil)
    wait { result != nil }
  }

  func testObservation() async throws {
    try persistenceService.load(at: nil)

    let person = Person(name: "alice")
    let write = Write(person: person)
    Task.detached {
      try await self.persistenceService.perform(write)
    }

    for try await people in persistenceService.observe(Read()) {
      XCTAssertEqual(people, [person])
      break
    }
  }

  private struct Migration: PersistenceServiceMigration {
    let identifier = "create person table"
    func perform(in database: GRDB.Database) throws {
      try database.create(table: Person.databaseTableName) { table in
        table.column(Person.Columns.name.rawValue)
      }
    }
  }

  private struct Read: PersistenceServiceRead {
    func perform(in database: Database) throws -> [Person] {
      try Person.order(Person.Columns.name)
        .fetchAll(database)
    }
  }

  private struct Write: PersistenceServiceWrite {
    let person: Person
    func perform(in database: Database) throws {
      try person.insert(database)
    }
  }

  private struct Person: PersistableRecord, FetchableRecord, Codable, Equatable {
    static let databaseTableName = "person"
    enum Columns: String, ColumnExpression { case name }
    let name: String
  }
}
