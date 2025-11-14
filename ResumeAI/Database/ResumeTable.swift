//
//  ResumeTable.swift
//  ResumeAI
//
//  Created by Chaman on 02/11/25.
//

import Foundation
import UIKit
import SQLite3

class ResumeTable: Database {
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    var statement: OpaquePointer? = nil
    func createResumeTable() {
        let createTableQuery = """
            CREATE TABLE IF NOT EXISTS ResumeTable (
                localId INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                createdAt TEXT,
                updatedAt TEXT
            );
        """
        if sqlite3_exec(Database.databaseConnection, createTableQuery, nil, nil, nil) != SQLITE_OK {
            print("Error creating ResumeTable")
        }
     }
    
    func saveResume(resume: Resume, completion: @escaping (Bool, String?) -> Void) {
        var statement: OpaquePointer?
        let insertQuery = "INSERT INTO ResumeTable (name, createdAt, updatedAt) VALUES (?, ?, ?)"

        if sqlite3_prepare_v2(Database.databaseConnection, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, resume.name, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, resume.createdAt ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, resume.updatedAt, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMsg = String(cString: sqlite3_errmsg(Database.databaseConnection))
                print("Error inserting contact: \(errorMsg)")
                completion(false, errorMsg)
            } else {
                print("Contact inserted successfully")
                completion(true, nil)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(Database.databaseConnection))
            print("Error preparing statement: \(errorMsg)")
            completion(false, errorMsg)
        }

        sqlite3_finalize(statement)
    }
    
    func getResumes() -> [Resume] {
        var resultArray = [Resume]()
        var statement: OpaquePointer?
        let query = "SELECT * FROM ResumeTable"

        if sqlite3_prepare_v2(Database.databaseConnection, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var resume = Resume()
                resume.id = Int(sqlite3_column_int(statement, 0))
                resume.name = String(cString: sqlite3_column_text(statement, 1))
                resume.createdAt = String(cString: sqlite3_column_text(statement, 2))
                resume.updatedAt = String(
                    cString: sqlite3_column_text(statement, 3)
                )
                resultArray.append(resume)
            }
            sqlite3_finalize(statement)
        } else {
            print("Failed to prepare statement for fetching contacts.")
        }
        
        return resultArray
    }
}
