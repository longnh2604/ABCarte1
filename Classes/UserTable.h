//
//  TestTable.h
//  Setting
//
//  Created by MacBook on 10/10/14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define TABLE_NAME			@"mst_user"
#define DB_FILE_NAME		@"iPadCamera.db"

@interface UserTable : NSObject 
{
	sqlite3*	db;
	
	NSString*	dbPath;
	NSArray*	columnNames;
	NSString*	tableName;
}

@property sqlite3* db;
@property (nonatomic, retain) NSString*	dbPath;
@property (nonatomic, retain) NSArray*	columnNames;
@property (nonatomic, retain) NSString*	tableName;

- (id)init;
- (BOOL)openDataBase;
- (BOOL)createTable;
- (BOOL)insertData:(NSString*) name regist:(BOOL)isRegist;
- (NSMutableArray*)selectName:(NSString*) statement;
- (void)closeDataBase;
- (void)errDataBase;

@end
