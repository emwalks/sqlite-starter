/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import SQLite3
import PlaygroundSupport

destroyPart1Database()

/*:
 
 # Getting Started
 
 The first thing to do is set your playground to run manually rather than automatically. This will help ensure that your SQL commands run when you intend them to. At the bottom of the playground click and hold the Play button until the dropdown menu appears. Choose "Manually Run".
 
 You will also notice a `destroyPart1Database()` call at the top of this page. You can safely ignore this, the database file used is destroyed each time the playground is run to ensure all statements execute successfully as you iterate through the tutorial.
 
 Secondly, this Playground will need to write SQLite database files to your file system. Create the directory `~/Documents/Shared Playground Data/SQLiteTutorial` by running the following command in Terminal.
 
 `mkdir -p ~/Documents/Shared\ Playground\ Data/SQLiteTutorial`
 
 */

//: ## Open a Connection
func openDatabase() -> OpaquePointer? {
    var db: OpaquePointer? = nil
    //the & is an in-out parameter: passes value by reference rather than value
    if sqlite3_open(part1DbPath, &db) == SQLITE_OK {
        print("Successfully opened connection to database at \(part1DbPath)")
        return db
    } else {
        print("Unable to open database. Verify that you created the directory described " +
            "in the Getting Started section.")
        PlaygroundPage.current.finishExecution()
    }
    
}

let db = openDatabase()
//: ## Create a Table
let createTableString = """
CREATE TABLE Contact(
Id INT PRIMARY KEY NOT NULL,
Name CHAR(255));
"""

func createTable() {
    // creates a pointer to reference
    var createTableStatement: OpaquePointer? = nil
    
    //compiles the SQL statement into byte code and returns a status code
    if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
        
        // runs the compiled statement. In this case, you only “step” once as this statement has a single result
        if sqlite3_step(createTableStatement) == SQLITE_DONE {
            print("Contact table created.")
        } else {
            print("Contact table could not be created.")
        }
    } else {
        print("CREATE TABLE statement could not be prepared.")
    }
    
    // You must always call sqlite3_finalize() on your compiled statement to delete it and avoid resource leaks
    sqlite3_finalize(createTableStatement)
}

createTable()
//: ## Insert a Contact
// The ? syntax tells the compiler that you’ll provide real values when you actually execute the statement
let insertStatementString = "INSERT INTO Contact (Id, Name) VALUES (?, ?);"

//func insert() {
//    var insertStatement: OpaquePointer? = nil
//
//    // compile the statement and verify that all is well
//    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
//        let id: Int32 = 1
//        let name: NSString = "Ray"
//
//        // Here, you define a value for the ? placeholder. The function’s name — sqlite3_bind_int() — implies you’re binding an Int value to the statement. The first parameter of the function is the statement to bind to, while the second is a non-zero based index for the position of the ? you’re binding to. The third and final parameter is the value itself. This binding call returns a status code, but for now you assume that it succeeds;
//        sqlite3_bind_int(insertStatement, 1, id)
//
//        // Perform the same binding process, but this time for a text value. There are two additional parameters on this call; for the purposes of this tutorial you can simply pass -1 and nil for them.
//        sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
//
//        // Use the sqlite3_step() function to execute the statement and verify that it finished
//        if sqlite3_step(insertStatement) == SQLITE_DONE {
//            print("Successfully inserted row.")
//        } else {
//            print("Could not insert row.")
//        }
//    } else {
//        print("INSERT statement could not be prepared.")
//    }
//    // finalize the statement. If you were going to insert multiple contacts, you’d likely retain the statement and re-use it with different values.
//    sqlite3_finalize(insertStatement)
//}
//
//insert()

//refactored 90-127 to insert multiple

func insertMultipleStatements() {
    
    var insertStatement: OpaquePointer? = nil
    
    let names: [NSString] = ["Ray", "Emma", "Andrew", "Chris"]
    
    // compile the statement and verify that all is well
    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
        
        for (index, name) in names.enumerated() {
            let id = Int32(index + 1)
            sqlite3_bind_int(insertStatement, 1, id)
            sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Could not insert row.")
            }
            sqlite3_reset(insertStatement)
        }
        
        sqlite3_finalize(insertStatement)
        
    } else {
        print("INSERT statement could not be prepared.")
    }
}

insertMultipleStatements()
//: ## Querying
let queryStatementString = "SELECT * FROM Contact;"
func query() {
    var queryStatement: OpaquePointer? = nil
    // prepares the statement
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        
        // checks the query status code: SQLITE_ROW means that you retrieved a row when you stepped through the result;
        while (sqlite3_step(queryStatement) == SQLITE_ROW) {
            
            // you can access the row’s values column by column. The first column is an Int, so you use sqlite3_column_int() and pass in the statement and a zero-based column index. You assign the returned value to the locally-scoped id constant
            let id = sqlite3_column_int(queryStatement, 0)
            
            //fetch the text value from the Name column. This is a bit messy due to the C API. First, you capture the value as queryResultCol1 so you can convert it to a proper Swift string on the next line
            let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
            let name = String(cString: queryResultCol1!)
            
            // prints result
            print("Query Result:")
            print("\(id) | \(name)")
            
//        } else {
//            print("Query returned no results")
        }
    } else {
        print("SELECT statement could not be prepared")
    }
    
    // finalize as above
    sqlite3_finalize(queryStatement)
}

query()


//: ## Update

//: ## Delete

//: ## Errors

//: ## Close the database connection

//: Continue to [Making It Swift](@next)

