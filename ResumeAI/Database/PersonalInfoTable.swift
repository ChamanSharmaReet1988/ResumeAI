//
//  PersonalInfoTable.swift
//  ResumeAI
//
//  Created by Sakshi on 05/12/25.
//

import Foundation
import SQLite3
import UIKit

class PersonalInfoTable: Database {
    
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    var statement: OpaquePointer? = nil
    
    func createPersonalInfoTable() {
        let query = """
        CREATE TABLE IF NOT EXISTS PersonalInfoTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            email TEXT,
            address TEXT,
            imagePath TEXT,
            createdAt TEXT,
            updatedAt TEXT
        );
        """
        
        if sqlite3_exec(Database.databaseConnection, query, nil, nil, nil) != SQLITE_OK {
            print("❌ Error creating PersonalInfoTable")
        } else {
            print("✅ PersonalInfoTable Created")
        }
    }
    
    func savePersonalInfo(_ info: PersonalInfoModel, completion: @escaping (Bool, String?) -> Void) {
        
        let query = """
        INSERT INTO PersonalInfoTable (name, phone, email, address, imagePath, createdAt, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        if sqlite3_prepare_v2(Database.databaseConnection, query, -1, &statement, nil) == SQLITE_OK {
            
            sqlite3_bind_text(statement, 1, info.name ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, info.phone ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, info.email ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, info.address ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 5, info.imagePath ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 6, info.createdAt ?? "", -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 7, info.updatedAt ?? "", -1, SQLITE_TRANSIENT)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                completion(true, nil)
            } else {
                let error = String(cString: sqlite3_errmsg(Database.databaseConnection))
                completion(false, error)
            }
        } else {
            let error = String(cString: sqlite3_errmsg(Database.databaseConnection))
            completion(false, error)
        }
        sqlite3_finalize(statement)
    }
    
    func fetchPersonalInfo() -> PersonalInfoModel? {
        let query = "SELECT * FROM PersonalInfoTable LIMIT 1"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(Database.databaseConnection, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                
                let info = PersonalInfoModel(
                    id: Int(sqlite3_column_int(statement, 0)),
                    name: String(cString: sqlite3_column_text(statement, 1)),
                    phone: String(cString: sqlite3_column_text(statement, 2)),
                    email: String(cString: sqlite3_column_text(statement, 3)),
                    address: String(cString: sqlite3_column_text(statement, 4)),
                    imagePath: String(cString: sqlite3_column_text(statement, 5)),
                    createdAt: String(cString: sqlite3_column_text(statement, 6)),
                    updatedAt: String(cString: sqlite3_column_text(statement, 7))
                )
                sqlite3_finalize(statement)
                return info
            }
        }
        
        sqlite3_finalize(statement)
        return nil
    }
}
