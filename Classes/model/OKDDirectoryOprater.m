//
//  OKDDirectoryOprater.m
//  Pattoru
//
//  Created by MacBook on 11/02/03.
//  Copyright 2011 okada-denshi-Co.Ltd. All rights reserved.
//

#import "OKDDirectoryOprater.h"

#import "../defines.h"

///
/// ディレクトリ（フォルダ）操作クラス 
///
@implementation OKDDirectoryOprater

@synthesize folderName = _folderName;

#pragma mark private_mothods

#pragma mark life_cycle

// 初期化 
//	folderName:対象となるフォルダ名 　= nilでrootフォルダが対象となる
-(id) initWithFolderName:(NSString*)folderName
{
	if (self = [super init])
	{
		self.folderName = (folderName)?
			[NSString stringWithFormat:@"%@/Documents/%@", 
				NSHomeDirectory(), folderName] :
			[NSString stringWithFormat:@"%@/Documents", 
				NSHomeDirectory()];
	}
	
	return (self);
}

// Cachesフォルダでの初期化
//	folderName:対象となるフォルダ名 　= nilでrootフォルダが対象となる
-(id) initWithCachesFolderName:(NSString*)folderName
{
    if (self = [super init])
	{
		self.folderName = (folderName)?
            [NSString stringWithFormat:@"%@/%@/%@", 
                NSHomeDirectory(), DOWNLOAD_PICTURE_CACHES_FOLDER, folderName] :
            [NSString stringWithFormat:@"%@/%@", 
                NSHomeDirectory(), DOWNLOAD_PICTURE_CACHES_FOLDER];
	}
	
	return (self);
}

- (void)dealloc 
{
    if (self.folderName) {
        [self.folderName release];
    }
	
	[super dealloc];
}


#pragma mark public_methods

// フルパスのフォルダ名を取得
/*
-(NSString*) makeFullPathName
{
	return ( (self.foldeName)?
				[NSString stringWithFormat:@"%@/Documents/%@", 
					NSHomeDirectory(), self.foldeName] :
				[NSString stringWithFormat:@"%@/Documents", 
					NSHomeDirectory()] 
			);
}
*/

// フォルダの確認と作成
//	isMakeEnfoce	:存在しない場合に作成するか	YES=作成する NO=作成しない
-(DIR_OPRATE_RESULT) chkFolderMake:(BOOL)isMakeEnfoce
{
	DIR_OPRATE_RESULT result = RESULT_OK;
	
	NSFileManager *fileMng = [NSFileManager defaultManager];
	BOOL isFolder;
	if ( ! [fileMng fileExistsAtPath:self.folderName isDirectory:&isFolder] )
	{
		// フォルダは存在しない
		if (isMakeEnfoce)
		{
			// 作成指定の場合はフォルダを作成
			if ([fileMng createDirectoryAtPath:self.folderName 
				   withIntermediateDirectories:YES attributes:nil error:NULL])
			{	result = RESULT_OK; }		// 作成成功
			else
			{	result = RESULT_ERROR; }	// 作成失敗
		}
		else 
		{
			// 作成指定がない場合は、戻り値を[そのディレクトリは存在しない]にセット
			result = NOT_DIRECTORY;
		}

	}
	else 
	{
		// フォルダは存在する
		result = EXIST_DIRECTORY;
	}
		
	return (result);
}

// フォルダの確認（別名）
-(DIR_OPRATE_RESULT) chkAnotherFolder:(NSString*)anotherFolder
{
	DIR_OPRATE_RESULT result = RESULT_OK;
	
	NSString *anaFolder =
		[NSString stringWithFormat:@"%@/Documents/%@", 
			NSHomeDirectory(), anotherFolder];
	
	NSFileManager *fileMng = [NSFileManager defaultManager];
	BOOL isFolder;
	if ( ! [fileMng fileExistsAtPath:anaFolder isDirectory:&isFolder] )
	{
		result = NOT_DIRECTORY;
	}
	else {
		result = EXIST_DIRECTORY;
	}

	return (result);
}

// 指定フォルダ以下のフォルダ（またはファイル）一覧の取得
-(NSArray*)	getFilesWithFolderName
{
	NSArray *fileNames 
		= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.folderName 
															  error:NULL];
	
	return (fileNames);
}

// フォルダの削除
-(DIR_OPRATE_RESULT) deleteFolderWithFolderName
{
	DIR_OPRATE_RESULT result = RESULT_OK;
	
	NSError *err = nil;
	
	if (! [[NSFileManager defaultManager] removeItemAtPath:self.folderName 
													 error:&err] )
	{	
		if (err)
		{	
			NSLog(@" deleteFolder:%@ error -> %@",
					self.folderName, [err localizedDescription] ); 
		}
		
		result = RESULT_ERROR; 
	}
	
	return (result);
}

// フォルダ名の変更
-(DIR_OPRATE_RESULT) renameFolder:(NSString*)newFolderName
{
	DIR_OPRATE_RESULT result = RESULT_OK;
	
	NSError *err = nil;
	
	NSString *newFolder =
		[NSString stringWithFormat:@"%@/Documents/%@", 
		 NSHomeDirectory(), newFolderName];
	
	if (! [[NSFileManager defaultManager] moveItemAtPath:self.folderName 
												toPath:newFolder
													 error:&err] )
	{	
		if (err)
		{	
			NSLog(@" renameFolder:%@ error -> %@",
				  self.folderName, [err localizedDescription] ); 
		}
		
		result = RESULT_ERROR; 
	}
	
	return (result);
}

// Document以下のフォルダを付与してファイル名を取得する
-(NSString*) getDocumentFolderFilenameWithUID:(NSString*)uidFolderName 
							 fileNameNoFolder:(NSString*)fileName
{
	return ([NSString stringWithFormat:@"Documents/%@/%@",
			 uidFolderName, fileName]);
}

@end
