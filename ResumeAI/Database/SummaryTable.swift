//
//  SummaryTable.swift
//  ResumeAI
//
//  Created by Sakshi on 05/12/25.
//

import Foundation
import SQLite3

class SummaryTable: Database {
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    func createSummaryTable() {
        let query = """
            CREATE TABLE IF NOT EXISTS Summary (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                summary TEXT,
                createdAt TEXT,
                updatedAt TEXT
            );
        """
        
        if sqlite3_exec(Database.databaseConnection, query, nil, nil, nil) != SQLITE_OK {
            print("❌ Error creating Summary table")
        }
    }

    func saveSummary(summary: SummaryModel, completion: @escaping (Bool, String?, Int?) -> Void) {
        
        var statement: OpaquePointer?
        let insertQuery = """
            INSERT INTO Summary (summary, createdAt, updatedAt)
            VALUES (?, ?, ?)
        """

        if sqlite3_prepare_v2(Database.databaseConnection, insertQuery, -1, &statement, nil) == SQLITE_OK {
            
            sqlite3_bind_text(statement, 1, summary.summary ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, summary.createdAt ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, summary.updatedAt ?? "", -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                let lastId = Int(sqlite3_last_insert_rowid(Database.databaseConnection))
                completion(true, nil, lastId)
            } else {
                let error = String(cString: sqlite3_errmsg(Database.databaseConnection))
                completion(false, error, nil)
            }
        } else {
            let error = String(cString: sqlite3_errmsg(Database.databaseConnection))
            completion(false, error, nil)
        }

        sqlite3_finalize(statement)
    }
}
