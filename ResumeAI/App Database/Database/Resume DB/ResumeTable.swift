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
            CREATE TABLE IF NOT EXISTS \(TableName.resumeTableName.rawValue) (
                localId INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                createdAt TEXT,
                updatedAt TEXT
            );
        """
        if sqlite3_exec(Database.databaseConnection, createTableQuery, nil, nil, nil) != SQLITE_OK {
            print("Error creating \(TableName.resumeTableName.rawValue)")
        }
    }
    
    func saveResume(resume: Resume, completion: @escaping (Bool, String?, Int?) -> Void) {
        var statement: OpaquePointer?
        let insertQuery = "INSERT INTO \(TableName.resumeTableName.rawValue) (name, createdAt, updatedAt) VALUES (?, ?, ?)"
        
        if sqlite3_prepare_v2(Database.databaseConnection, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, resume.name, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, resume.createdAt ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, resume.updatedAt, -1, SQLITE_TRANSIENT)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMsg = String(cString: sqlite3_errmsg(Database.databaseConnection))
                print("Error inserting contact: \(errorMsg)")
                completion(false, errorMsg, nil)
            } else {
                let lastId = sqlite3_last_insert_rowid(Database.databaseConnection) // ✅ HERE
                completion(true, nil, Int(lastId))
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(Database.databaseConnection))
            print("Error preparing statement: \(errorMsg)")
            completion(false, nil, nil)
        }
        
        sqlite3_finalize(statement)
    }
    
    func getResumes() -> [Resume] {
        var resultArray = [Resume]()
        var statement: OpaquePointer?
        let query = "SELECT * FROM \(TableName.resumeTableName.rawValue)"
        
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
    
    func duplicateResume(resumeName: String, id: Int, completion: @escaping (Bool) -> Void) {
        let selectQuery = "SELECT * FROM \(TableName.resumeTableName.rawValue) WHERE localId = ?"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(Database.databaseConnection, selectQuery, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            if sqlite3_step(stmt) == SQLITE_ROW {
                let createdAt = String(cString: sqlite3_column_text(stmt, 2))
                let updatedAt = String(cString: sqlite3_column_text(stmt, 3))
                sqlite3_finalize(stmt)
                
                let insertQuery = "INSERT INTO \(TableName.resumeTableName.rawValue) (name, createdAt, updatedAt) VALUES (?, ?, ?)"
                var insertStmt: OpaquePointer?
                
                if sqlite3_prepare_v2(Database.databaseConnection, insertQuery, -1, &insertStmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(insertStmt, 1, resumeName, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(insertStmt, 2, createdAt, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(insertStmt, 3, updatedAt, -1, SQLITE_TRANSIENT)
                    
                    if sqlite3_step(insertStmt) == SQLITE_DONE {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
                sqlite3_finalize(insertStmt)
                return
            }
        }
        completion(false)
        sqlite3_finalize(stmt)
    }
    
    func deleteResume(id: Int) {
        let deleteQuery = "DELETE FROM \(TableName.resumeTableName.rawValue) WHERE localId = ?"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(Database.databaseConnection, deleteQuery, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
    
    func updateResumeName(id: Int, newName: String) {
        let updateQuery = "UPDATE \(TableName.resumeTableName.rawValue) SET name = ?, updatedAt = ? WHERE localId = ?"
        var stmt: OpaquePointer?
        
        let updatedAt = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        if sqlite3_prepare_v2(Database.databaseConnection, updateQuery, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, newName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, updatedAt, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 3, Int32(id))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
}
