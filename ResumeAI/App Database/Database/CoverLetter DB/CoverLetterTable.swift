//
//  CoverLetterTable.swift
//  ResumeAI
//
//  Created by Sourabh Jain on 05/12/25.
//

import SQLite3
import Foundation

enum TableName: String {
    case resumeTableName = "ResumeTable"
    case coverLetterTableName = "CoverLetterTable"
}

class CoverLetterTable: Database {
    func migrateAddDetailsColumnIfNeeded() {
        let query = "ALTER TABLE \(TableName.coverLetterTableName.rawValue) ADD COLUMN details TEXT"
        sqlite3_exec(Database.databaseConnection, query, nil, nil, nil)
    }
    
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    func createCoverLetterTable() {
        let query = """
        CREATE TABLE IF NOT EXISTS \(TableName.coverLetterTableName.rawValue) (
            localId INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            details TEXT,
            createdAt TEXT,
            updatedAt TEXT
        );
        """
        
        if sqlite3_exec(Database.databaseConnection, query, nil, nil, nil) != SQLITE_OK {
            debugPrint("Error creating \(TableName.coverLetterTableName.rawValue)")
        }
        migrateAddDetailsColumnIfNeeded()
    }
    
    // MARK: - Save Cover Letter
    func saveCoverLetter(model: CoverLeter, completion: @escaping (Bool, String?, Int?) -> Void) {
        var stmt: OpaquePointer?
        let query = """
        INSERT INTO \(TableName.coverLetterTableName.rawValue) (name, details, createdAt, updatedAt)
        VALUES (?, ?, ?, ?)
        """
        
        if sqlite3_prepare_v2(Database.databaseConnection, query, -1, &stmt, nil) == SQLITE_OK {
            
            let detailsJSON = encodeDetails(model.details)
            
            sqlite3_bind_text(stmt, 1, model.name, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, detailsJSON, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, model.createdAt, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 4, model.updatedAt, -1, SQLITE_TRANSIENT)
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                let id = sqlite3_last_insert_rowid(Database.databaseConnection)
                completion(true, nil, Int(id))
            } else {
                completion(false, String(cString: sqlite3_errmsg(Database.databaseConnection)), nil)
            }
        }
        
        sqlite3_finalize(stmt)
    }
    
    // MARK: - Get All Cover Letters
    func getCoverLetters() -> [CoverLeter] {
        var list: [CoverLeter] = []
        
        let query = """
        SELECT localId, name, details, createdAt, updatedAt
        FROM \(TableName.coverLetterTableName.rawValue)
        ORDER BY localId DESC
        """
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(Database.databaseConnection, query, -1, &stmt, nil) == SQLITE_OK {
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                
                var model = CoverLeter()
                model.id = Int(sqlite3_column_int(stmt, 0))
                
                if let nameCString = sqlite3_column_text(stmt, 1) {
                    model.name = String(cString: nameCString)
                }
                
                // ✅ details (index 2)
                if let detailsCString = sqlite3_column_text(stmt, 2) {
                    let detailsString = String(cString: detailsCString)
                    model.details = decodeDetails(detailsString)
                } else {
                    model.details = nil
                }
                
                if let createdCString = sqlite3_column_text(stmt, 3) {
                    model.createdAt = String(cString: createdCString)
                }
                
                if let updatedCString = sqlite3_column_text(stmt, 4) {
                    model.updatedAt = String(cString: updatedCString)
                }
                
                list.append(model)
            }
            
        } else {
            debugPrint("SQLite prepare failed:",
                       String(cString: sqlite3_errmsg(Database.databaseConnection)))
        }
        
        sqlite3_finalize(stmt)
        return list
    }
    
    // MARK: - Update Cover Letter
    func updateCoverLetter(id: Int, name: String, details: CoverLeterDetail?) {
        let updatedAt = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .medium,
            timeStyle: .short
        )
        
        let query = """
        UPDATE \(TableName.coverLetterTableName.rawValue)
        SET name = ?, details = ?, updatedAt = ?
        WHERE localId = ?
        """
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(Database.databaseConnection, query, -1, &stmt, nil) == SQLITE_OK {
            
            let detailsJSON = encodeDetails(details)
            
            sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, detailsJSON, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, updatedAt, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 4, Int32(id))
            
            let result = sqlite3_step(stmt)
            
            if result == SQLITE_DONE {
                let rows = sqlite3_changes(Database.databaseConnection)
                debugPrint("Update success | Rows affected:", rows)
                debugPrint("Saved JSON:", detailsJSON)
            } else {
                let error = String(cString: sqlite3_errmsg(Database.databaseConnection))
                debugPrint("Update failed:", error)
            }
            
        } else {
            let error = String(cString: sqlite3_errmsg(Database.databaseConnection))
            debugPrint("Prepare failed:", error)
        }
        
        sqlite3_finalize(stmt)
    }
    // MARK: - Delete
    func deleteCoverLetter(id: Int) {
        let query = "DELETE FROM \(TableName.coverLetterTableName.rawValue) WHERE localId = ?"
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(Database.databaseConnection, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
    }
    
    private func encodeDetails(_ details: CoverLeterDetail?) -> String {
        guard let details else { return "" }
        let data = try? JSONEncoder().encode(details)
        return String(data: data ?? Data(), encoding: .utf8) ?? ""
    }
    
    private func decodeDetails(_ string: String?) -> CoverLeterDetail? {
        guard
            let string,
            let data = string.data(using: .utf8)
        else { return nil }
        
        return try? JSONDecoder().decode(CoverLeterDetail.self, from: data)
    }
    
    func debugFetchCoverLetter(id: Int) {
        let query = "SELECT details FROM \(TableName.coverLetterTableName.rawValue) WHERE localId = ?"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(Database.databaseConnection, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            
            if sqlite3_step(stmt) == SQLITE_ROW {
                if let cString = sqlite3_column_text(stmt, 0) {
                    let json = String(cString: cString)
                    debugPrint("DB stored JSON:", json)
                } else {
                    debugPrint("details is NULL")
                }
            }
        }
        
        sqlite3_finalize(stmt)
    }
}
