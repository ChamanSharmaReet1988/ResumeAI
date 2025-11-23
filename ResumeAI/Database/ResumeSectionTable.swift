//
//  ResumeSectionTable.swift
//  ResumeAI
//
//  Created by Chaman on 23/11/25.
//

import Foundation
import UIKit
import SQLite3

class ResumeSectionTable {
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    var statement: OpaquePointer? = nil
    func createResumeSectionTable() {
        let createTableQuery = """
            CREATE TABLE IF NOT EXISTS ResumeSectionTable (
                localId INTEGER PRIMARY KEY AUTOINCREMENT,
                resumeId TEXT,
                name TEXT,
                sequence TEXT
            );
        """
        if sqlite3_exec(Database.databaseConnection, createTableQuery, nil, nil, nil) != SQLITE_OK {
            print("ResumeSectionModel: Error creating ResumeSectionTable")
        }
    }
    
    func saveResumeSection(resumeSectionModel: ResumeSectionModel, completion: @escaping (Bool, String?) -> Void) {
        var statement: OpaquePointer?
        let insertQuery = "INSERT INTO ResumeSectionTable (resumeId, name, sequence) VALUES (?, ?, ?)"
        
        if sqlite3_prepare_v2(Database.databaseConnection, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, resumeSectionModel.resumeId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, resumeSectionModel.name, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, resumeSectionModel.sequence ?? "", -1, SQLITE_TRANSIENT)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMsg = String(cString: sqlite3_errmsg(Database.databaseConnection))
                print("ResumeSectionTable: Error inserting contact: \(errorMsg)")
                completion(false, errorMsg)
            } else {
                print("ResumeSectionTable: Contact inserted successfully")
                completion(true, nil)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(Database.databaseConnection))
            print("ResumeSectionTable: Error preparing statement: \(errorMsg)")
            completion(false, errorMsg)
        }
        
        sqlite3_finalize(statement)
    }
    
    func getResumeSections(resumeId: String) -> [ResumeSectionModel] {
        var resultArray = [ResumeSectionModel]()
        var statement: OpaquePointer?
        let query = "SELECT * FROM ResumeSectionTable WHERE resumeId = \(resumeId) ORDER BY sequence ASC"
        if sqlite3_prepare_v2(Database.databaseConnection, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var resumeSectionModel = ResumeSectionModel()
                resumeSectionModel.id = Int(sqlite3_column_int(statement, 0))
                resumeSectionModel.resumeId = String(cString: sqlite3_column_text(statement, 1))
                resumeSectionModel.name = String(cString: sqlite3_column_text(statement, 2))
                resumeSectionModel.sequence = String( cString: sqlite3_column_text(statement, 3))
                resultArray.append(resumeSectionModel)
            }
            sqlite3_finalize(statement)
        } else {
            print("ResumeSectionModel: Failed to prepare statement for fetching contacts.")
        }
        
        return resultArray
    }
    
    func deletegetResumeSection(id: Int) {
        let deleteQuery = "DELETE FROM ResumeSectionTable WHERE localId = ?"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(Database.databaseConnection, deleteQuery, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
    
    func deletegetResumeSection(resumeId: String) {
        let deleteQuery = "DELETE FROM ResumeSectionTable WHERE resumeId = ?"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(Database.databaseConnection, deleteQuery, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, resumeId, -1, SQLITE_TRANSIENT)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
    
    func updateResumeSectionSequence(id: Int, squence: String) {
        let updateQuery = "UPDATE ResumeSectionTable SET sequence = ? WHERE localId = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(Database.databaseConnection, updateQuery, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, squence, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 2, Int32(id))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
}
