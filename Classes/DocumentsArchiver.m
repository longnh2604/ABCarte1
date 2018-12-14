//
//  DocumentsArchiver.m
//  ZipArchiveStub
//
//  Created by MacBook on 11/08/02.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DocumentsArchiver.h"

#import "ZipArchive.h"

#import "defines.h"

// ルートパス：Documentフォルダ
#define ROOT_FOLDER			@"Documents"
// 写真フォルダのパス
#define PICTURE_FOLDER		@"%@/Documents/User%08d"

// 圧縮ファイルの拡張子
#define ARCHIVE_FILE_EXTENSION	@"zip"

// 削除対象のフォルダ／ファイルの名称変更の接頭語
#define REPLACE_DELETE_HEADER	@"__R__"

// 圧縮情報ファイル名
#define ARCHIVE_INFO_FILE_NAME	@"_archiveInfo.xml"

// データベースファイル名
#define DATABESE_FILE_NAME		@"cameraApp.db"
#define DATABESE_FILE_NAME2		@"cameraApp_trial.db"

///
/// Documentsフォルダの圧縮を行う
///
@implementation DocumentsArchiver

@synthesize docArchiveError = _docArchiveError;
@synthesize docArchiveError4Temp = _docArchiveError4Temp;
@synthesize delegate;

#pragma mark private_methods

// Archiveファイルの作成
- (BOOL) makeArchvieFileWithRootFolder:(NSString*)rootFolder  zipArchive:(ZipArchive*)archive
{
	BOOL stat;
	
	/*NSString *zipFile = [NSString stringWithFormat:@"%@%@.%@", 
	 NSTemporaryDirectory(), _archiveFileName, ARCHIVE_FILE_EXTENSION];*/
	NSString *zipFile = [NSString stringWithFormat:@"%@/%@.%@", 
						 rootFolder, _archiveFileName, ARCHIVE_FILE_EXTENSION];
	
	NSLog(@"archive file path:%@", zipFile);
	
	if ([_password length] <= 0)
	{	stat = [archive CreateZipFile2:zipFile]; }
	else {
		stat = [archive CreateZipFile2:zipFile Password:_password]; 
	}
	
	return (stat);
}

// 圧縮情報ファイルの作成
- (BOOL) makeArchiveInfoFileWithPath:(NSString*)path
{
	NSMutableString *doc = [NSMutableString string];
	
	[doc appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n"];
	[doc appendString:@"<archive-info-root> \n"];
	[doc appendString:@"\t<info"];
	[doc appendFormat:@" create_date=\"%@\" ", [_archiveInfo objectForKey:@"create_date"]];
	[doc appendFormat:@" archive_memo=\"%@\" ", [_archiveInfo objectForKey:@"archive_memo"]];
	[doc appendFormat:@" user_num=\"%@\" ", [_archiveInfo objectForKey:@"user_num"]];
	[doc appendFormat:@" picture_num=\"%@\" ", [_archiveInfo objectForKey:@"picture_num"]];
	[doc appendFormat:@" hist_nums=\"%@\" ", [_archiveInfo objectForKey:@"hist_nums"]];
    [doc appendFormat:@" archiver_version=\"%d\" ", DOC_ARCHIVER_VERSION];     // add attribute at ver111 submited 3rd later
	[doc appendString:@"> \n "];
	[doc appendString:@"\t</info> \n"];
	[doc appendString:@"</archive-info-root>"];
	
	NSError *error = nil;
	[doc writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];

	BOOL stat = YES;
	if (error)
	{
		NSLog (@"makeArchiveInfoFileWithPath error:%@", error);
		stat = NO;
	}
	
	return (stat);
}

// 圧縮情報ファイルの追加
- (BOOL) addArchiveInfoWithArchive:(ZipArchive*)archive
{
	// tempフォルダに一時作成
	NSString *tmpFolder = NSTemporaryDirectory();
	NSString *path = [tmpFolder stringByAppendingPathComponent:ARCHIVE_INFO_FILE_NAME];
	
	// 圧縮情報ファイルの作成
	if (! [self makeArchiveInfoFileWithPath:path] )
	{	return (NO); }
	
	// archiveに追加
	BOOL  stat = ([archive addFileToZip:path 
								newname:[NSString stringWithFormat:@"/%@", 
											ARCHIVE_INFO_FILE_NAME]]);
	// 圧縮情報ファイルを削除
	[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	
	return (stat);
}

// Documentフォルダより復元する圧縮ファイルを取得:
- (NSString*) searchBackupFile4Documents:(BOOL)isRequestFullpath
{
	NSString *file = nil;
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;

	NSString *rootFolder 
		= [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), ROOT_FOLDER];
	NSArray *fileList2
		= [manager contentsOfDirectoryAtPath:rootFolder error:&error];
	if (error)
	{	
		NSLog (@"searchBackupFile4Documents fileList get error in document folder:%@", error);
		return (nil);
	}
	for (NSInteger idx = ([fileList2 count] -1); idx >= 0; idx--) // -> 降順
	{
		NSString *fileName = [fileList2 objectAtIndex:idx];
		if ([fileName hasSuffix:ARCHIVE_FILE_EXTENSION])
		{
			// ファイルが見つかった
			file = (isRequestFullpath)?
				[rootFolder stringByAppendingPathComponent:fileName]:
				[fileName mutableCopy];
			return (file);
		}
	}
	
	return (nil);
}

// 復元する圧縮ファイルを取得:
- (NSString*) searchBackupFile:(BOOL*) isFindInTemp isRequestFullpath:(BOOL)isNeed
{
	NSString *file = nil;
	*isFindInTemp = NO;
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;
	
	// 最初にTempフォルダより検索
	NSString *tmpFolder = NSTemporaryDirectory();
	NSArray *fileList
		= [manager contentsOfDirectoryAtPath:tmpFolder error:&error];
	if (error)
	{	
		NSLog (@"searchBackupFile fileList get error in temp folder:%@", error);
		return (nil);
	}
	for (NSInteger idx = ([fileList count] -1); idx >= 0; idx--) // -> 降順
	{
		NSString *fileName = [fileList objectAtIndex:idx];
		if ([fileName hasSuffix:ARCHIVE_FILE_EXTENSION])
		{
			// ファイルが見つかった
			file = (isNeed)?
						[tmpFolder stringByAppendingPathComponent:fileName] :
						[fileName mutableCopy];
			*isFindInTemp = YES;
			return (file);
		}
	}

	// 次にDocumentフォルダより検索
	return ([self searchBackupFile4Documents:isNeed]);
}

// 現状のrootフォルダ以下のフォルダ名とファイル名をリネームする
- (void)rename4DeleteWithRootFolder:(NSString*)rootFolder
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;
	
 	NSArray *fileList
		= [manager contentsOfDirectoryAtPath:rootFolder error:&error];
	if (error)
	{	
		NSLog (@"rename4DeleteWithRootFolder fileList get error in document folder:%@", error);
		return ;
	}
	for (NSString *fileName in fileList)
	{
		// 圧縮ファイルは対象より除く
		if ([fileName hasSuffix:ARCHIVE_FILE_EXTENSION])
		{	continue; }
		
		// フルパス
		NSString *file = [rootFolder stringByAppendingPathComponent:fileName];
				
		// リネームする
		[manager moveItemAtPath:file 
						 toPath:[NSString stringWithFormat:@"%@/%@%@", 
								 rootFolder, REPLACE_DELETE_HEADER, fileName]
						  error:&error];
		if (error)
		{	
			NSLog (@"rename4DeleteWithRootFolder fileList rename error:%@", error);
			// return ; エラーでも続行
		}
	}
}

// リネームしたのrootフォルダ以下のフォルダ名とファイル名を元に戻す
- (void)restore2RenameWithRootFolder:(NSString*)rootFolder
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;
	
 	NSArray *fileList
	= [manager contentsOfDirectoryAtPath:rootFolder error:&error];
	if (error)
	{	
		NSLog (@"restore2RenameWithRootFolder fileList get error in document folder:%@", error);
		return ;
	}
	for (NSString *fileName in fileList)
	{
		// 圧縮ファイルは対象より除く
		if ([fileName hasSuffix:ARCHIVE_FILE_EXTENSION])
		{	continue; }
		
		// 削除対象の接頭語が無いものは除く
		if (! [fileName hasPrefix:REPLACE_DELETE_HEADER] )
		{	continue; }
		
		// フルパス
		NSString *file = [rootFolder stringByAppendingPathComponent:fileName];
		
		// リネームを元に戻す:REPLACE_DELETE_HEADERを空白にする
		[manager moveItemAtPath:file 
						 toPath:[file stringByReplacingOccurrencesOfString:REPLACE_DELETE_HEADER 
																withString:@""]
						  error:&error];
		if (error)
		{	
			NSLog (@"rename4DeleteWithRootFolder fileList rename error:%@", error);
			// return ; エラーでも続行
		}
	}
}

// リネームした現状のファイルを削除する
- (void)deleteRenameFileWithRootFolder:(NSString*)rootFolder isTargetDelHeader:(BOOL)isHeader
{
	NSFileManager *manager = [NSFileManager defaultManager];
	
	// Documentフォルダ内のファイル（ディレクトリ含む）一覧を取得
	NSArray *fileList
		= [manager contentsOfDirectoryAtPath:rootFolder error:NULL];
	for (NSString* fileName in fileList)
	{
		// いずれの場合も、圧縮ファイルは対象より除く
		if ([fileName hasSuffix:ARCHIVE_FILE_EXTENSION])
		{	continue; }
		
		// 削除対象の接頭語があるか？
		if (! [fileName hasPrefix:REPLACE_DELETE_HEADER] )
		{	
			// 接頭語が無しで、かつ対象がありを削除の場合
			if (isHeader)
			{	continue; }
		}
		else 
		{
			// 接頭語がありで、かつ対象がなしを削除の場合
			if (! isHeader)
			{	continue; }
		}
		
		// フルパス
		NSString *path = [rootFolder stringByAppendingPathComponent:fileName];
		
		NSError *error = nil;
		[manager removeItemAtPath:path error:&error];
		if (error)
		{
			NSLog (@"deleteRenameFileWithRootFolder Error　delete file/dir:%@ error->%@", 
				   path, error);
		}
	}
}

// 解凍されたファイルのサイズ確認
- (BOOL) checkUnZipFileWithPath:(NSString*)path fileLength:(NSUInteger)length
{
	NSFileManager *manager = [NSFileManager defaultManager];
	
	// ファイルサイズ確認
	NSError *error = nil;
	NSDictionary* attrTable 
		= [manager attributesOfItemAtPath:path error:&error];
	if (error)
	{	return (NO); }
	
	NSNumber *nfSize = [attrTable objectForKey:NSFileSize];
	BOOL stat = ([nfSize unsignedIntegerValue] > length);
		
	return (stat);
}

// 解凍されたファイルのサイズ確認
- (BOOL) checkUnZipFileWithRootFolder:(NSString*)rootFolder
{
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL stat = NO;
	
	for (NSInteger i = 0; i < 2; i++)
	{
		// データベースファイル：フルパス
		NSString *dbPath 
			= [rootFolder stringByAppendingPathComponent:
				(i==0)? DATABESE_FILE_NAME : DATABESE_FILE_NAME2];
		
		// ファイルサイズ確認
		NSError *error = nil;
		NSDictionary* attrTable 
			= [manager attributesOfItemAtPath:dbPath error:&error];
		if (error)
		{	continue; }
		
		NSNumber *nfSize = [attrTable objectForKey:NSFileSize];
		if ([nfSize unsignedIntegerValue] > 10)
		{	
			// 10 bytes以上あれば正常と見なす
			stat = YES;
			break;
		}
	}
	
	return (stat);

}

// 進捗状況をクライアントクラスに通知する
- (void) notifiProgress2Client:(NSUInteger)persent procKind:(ZIP_UNZIP_PROC_KIND)kind
{
	if ((self.delegate) &&
		([self.delegate respondsToSelector:
			@selector(DocumentsArchiver:progressPercent:ProcKind:)]))
	{
		// メインスレッドに通知
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate DocumentsArchiver:self 
							 progressPercent:persent
									ProcKind:kind];
		});		 
	}
}

// 圧縮対象全ファイル数
- (NSInteger) _getTotalTargetFiles:(NSString*)rootFolder cachesFolder:(NSString*)rootCachesFolder
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // Documentフォルダ内のファイル（ディレクトリ含む）一覧を取得
    NSArray *fileList
        = [manager contentsOfDirectoryAtPath:rootFolder error:NULL];
    
    NSInteger totalNum = [fileList count];
    fileList = nil;
                          
    NSArray *fileList2
        = [manager contentsOfDirectoryAtPath:rootFolder error:NULL];
    
    totalNum += [fileList2 count];
    fileList2 = nil;
    
    return (totalNum);
}


// 指定フォルダ内のサブフォルダまたはファイルを全て圧縮する
- (BOOL) _archiveFolderFileWithFolder:(NSString*)curentFolder 
                            zipAcrive:(ZipArchive*)archive isDelete:(BOOL)isDelete
                         totalFileNum:(NSInteger)totalNum fileCouner:(NSInteger*)pFileCnt
{
    BOOL stat = YES;
    
    NSString *specFolder 
        = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), curentFolder];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // Documentフォルダ内のファイル（ディレクトリ含む）一覧を取得
    NSArray *fileList
        = [manager contentsOfDirectoryAtPath:specFolder error:NULL];
    
    for (NSString *fileName in fileList)
    {
        BOOL dir;
        // フルパス
        NSString *path = [specFolder stringByAppendingPathComponent:fileName];
        
        // ファイルとディレクトリに分類する
        if (! [manager fileExistsAtPath:path isDirectory:&dir])
        {	continue; }			// 念のため
        
        if (dir )
        {
        // ディレクトリの場合
        ///////////////////////////////////////////////
            // NSLog (@"Folder: %@", path);
            
            // 進捗状況の通知
            if (((*pFileCnt)++) % 1 == 0)
            {	
                [self notifiProgress2Client:(*pFileCnt * 100) / totalNum
                                   procKind:DOC_ARCHIVE_PROC_ZIP]; 
            }
            
            // ディレクトリ下のファイルを全て取得して圧縮
            NSArray *dirFiles
                = [manager contentsOfDirectoryAtPath:path error:NULL];
            for (NSString *dirFile in dirFiles) {
                // フルパス
                BOOL dfDir;
                NSString *dfPath = [path stringByAppendingPathComponent:dirFile];
                if ( (! [manager fileExistsAtPath:dfPath isDirectory:&dfDir]) || (dfDir) )
                {	continue; }			// 念のためディレクトリ以外は除く
                
                // NSLog (@"Folder: %@ in file:%@", fileName, dirFile);
                
                if (! [archive addFileToZip:dfPath 
                                    newname:[NSString stringWithFormat:@"/%@/%@/%@", 
                                             curentFolder, fileName, dirFile]])
                {	
                    NSLog (@"add file to zip error:%@/%@/%@", curentFolder, fileName, dirFile); 
                    self.docArchiveError = DOC_ARCHIVE_ADD_ERROR;
                    stat = NO;
                    break;
                }
            }
        }
        else
        {
			// ファイルの場合
            // 圧縮ファイルの取り扱い
            if ([fileName hasSuffix:ARCHIVE_FILE_EXTENSION])
            {	
                if ( (isDelete) && (! [fileName hasPrefix:_archiveFileName]) )
                {
                    // 削除する：エラーでも続行  (但し、自分自身は除く)
                    [manager removeItemAtPath:path error:nil];
                }
                
                // 削除指定がない場合も含め対象より除く
                continue;
            }
            
            if (! [archive addFileToZip:path 
                                newname:[NSString stringWithFormat:@"/%@/%@", 
                                         curentFolder, fileName]])
            {	
                NSLog (@"add file to zip error:%@/%@", curentFolder, fileName);
                self.docArchiveError = DOC_ARCHIVE_ADD_ERROR;
                stat = NO;
                break;
            }
            
            // 進捗状況の通知
            if ((*pFileCnt)++ % 2 == 0)
            {	
                [self notifiProgress2Client:((*pFileCnt) * 100) / totalNum
                                   procKind:DOC_ARCHIVE_PROC_ZIP]; 
            }
        }
    }
   
    return (stat);
}

#pragma mark XML_parse_section

// 圧縮情報を取得
-(NSDictionary*) _getArchiveInfoWithPath:(NSString*)path
{
	if (_archiveInfo)
	{	[_archiveInfo release]; _archiveInfo = nil; }
	
	// _archiveInfo = [NSMutableDictionary dictionary];
	
	// NSXMLParserオブジェクトを作ってURLを指定する。
	NSURL *url = [NSURL fileURLWithPath:path];
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:url] autorelease];
	[parser setDelegate:self]; //　NSXMLParserDelegateを指定する。
	[parser parse];
	
	return (_archiveInfo);
}

- (void)parser:(NSXMLParser *)parser 
			didStartElement:(NSString *)elementName 
			  namespaceURI:(NSString *)namespaceURI 
			 qualifiedName:(NSString *)qName 
				attributes:(NSDictionary *)attributeDict 
{
	/*
	NSLog(@"<%@> 開始", elementName);
	for (id key in attributeDict) {
		NSLog(@"%@=%@", key, [attributeDict objectForKey:key]);
	}
	*/
	
	if (! [elementName isEqualToString:@"info"] )
	{	
		// 一旦、エラーとする
		self.docArchiveError = DOC_ARCHIVE_ARCH_INFO_ERROR;
		return; 
	}
	
	// 長さで正当性をチェック
	if ([attributeDict count] >= 5)
	{
		_archiveInfo = [attributeDict mutableCopy];
		[_archiveInfo retain];
		
		// ここでエラーを解除
		self.docArchiveError = DOC_ARCHIVE_NO_ERROR;
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	NSLog (@"parseErrorOccurred:%@", parseError);
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError {
    NSLog (@"validationErrorOccurred:%@", validationError);
}

#pragma mark life_cycle

// 初期化：圧縮
- (id) initWithArchiveFileName:(NSString*)fileName password:(NSString*)pwd  
				   archiveInfo:(NSDictionary*)info client:(id)client
{
	if ( (self = [super init] ) )
	{
		// 圧縮ファイル名の保存
		_archiveFileName = (fileName)? [fileName mutableCopy] : nil;
		// パスワードの保存: 省略時は空文字
		_password = ((pwd) && ([pwd length] > 0))? [pwd mutableCopy] : @"";
		// 圧縮情報
		if (info)
		{
			_archiveInfo = [info mutableCopy];
			[_archiveInfo retain];
		}
		else {
			_archiveInfo = nil;
		}

		
		self.delegate = client;
	}
	
	return (self);
}

// 初期化：情報取得・解凍
- (id) initWithPassword:(NSString*)pwd client:(id)client
{
	return ( [ self initWithArchiveFileName:nil password:pwd 
								archiveInfo:nil client:client] );
}

- (void)dealloc
{
	if (_archiveFileName)
	{	[_archiveFileName release]; }
	
	[_password release];
	
	if (_archiveInfo)
	{	[_archiveInfo release]; }
	
	[super dealloc];
}

#pragma mark public_methods

#ifdef VERSION111_3RD_SUBMIT_BEFORE
// 圧縮の実行(スレッド)
- (BOOL) _doArchiveWithOldAcrhDelete:(BOOL)isDelete
{
	BOOL stat = YES;
	ZipArchive *archive = nil;
	
	@try {
		_docArchiveError = DOC_ARCHIVE_NO_ERROR;
		
		// 対象となるrootフォルダ(1):　/Docmunetsフォルダ
		NSString *rootFolder 
			= [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), ROOT_FOLDER];
        
		// Archiveファイルの作成
		archive = [[ZipArchive alloc] init];
		if (! [self makeArchvieFileWithRootFolder:rootFolder zipArchive:archive] )
		{
			NSLog (@"ZipArcive create2 error");
			self.docArchiveError = DOC_ARCHIVE_OPEN_ERROR;
			return (NO);
		}
		
		// 圧縮情報ファイルの追加
		[self addArchiveInfoWithArchive:archive];
		
		NSFileManager *manager = [NSFileManager defaultManager];
		
		// Documentフォルダ内のファイル（ディレクトリ含む）一覧を取得
		NSArray *fileList
			= [manager contentsOfDirectoryAtPath:rootFolder error:NULL];
		
		// ファイルのみの一覧
		// NSMutableArray *fileNames = [NSMutableArray array];
		// ディレクトリ名をKeyとしたそのファイル一覧：ユーザごとの写真  
		// NSMutableDictionary *dirContens = [NSMutableDictionary dictionary];
		
		NSUInteger fileCnt = 0;
		for (NSString *fileName in fileList)
		{
			BOOL dir;
			// フルパス
			NSString *path = [rootFolder stringByAppendingPathComponent:fileName];
				
			// ファイルとディレクトリに分類する
			if (! [manager fileExistsAtPath:path isDirectory:&dir])
			{	continue; }			// 念のため
			
			if (dir )
			{
			// ディレクトリの場合
				// NSLog (@"Folder: %@", path);
				
				// 進捗状況の通知
				if (fileCnt++ % 1 == 0)
				{	
					[self notifiProgress2Client:(fileCnt * 100) / [fileList count]
									   procKind:DOC_ARCHIVE_PROC_ZIP]; 
				}
				
				// ディレクトリ下のファイルを全て取得して圧縮
				NSArray *dirFiles
					= [manager contentsOfDirectoryAtPath:path error:NULL];
				for (NSString *dirFile in dirFiles) {
					// フルパス
					BOOL dfDir;
					NSString *dfPath = [path stringByAppendingPathComponent:dirFile];
					if ( (! [manager fileExistsAtPath:dfPath isDirectory:&dfDir]) || (dfDir) )
					{	continue; }			// 念のためディレクトリ以外は除く
					
					// NSLog (@"Folder: %@ in file:%@", fileName, dirFile);

					if (! [archive addFileToZip:dfPath 
										newname:[NSString stringWithFormat:@"/%@/%@", 
												 fileName, dirFile]])
					{	
						NSLog (@"add file to zip error:%@/%@", fileName, dirFile); 
						self.docArchiveError = DOC_ARCHIVE_ADD_ERROR;
						stat = NO;
						break;
					}
				}
			}
			else
			{
			// ファイルの場合
				// 圧縮ファイルの取り扱い
				if ([fileName hasSuffix:ARCHIVE_FILE_EXTENSION])
				{	
					if ( (isDelete) && (! [fileName hasPrefix:_archiveFileName]) )
					{
						// 削除する：エラーでも続行  (但し、自分自身は除く)
						[manager removeItemAtPath:path error:nil];
					}
					
					// 削除指定がない場合も含め対象より除く
					continue;
				}
					
				if (! [archive addFileToZip:path 
									newname:[NSString stringWithFormat:@"/%@", 
											 fileName]])
				{	
					NSLog (@"add file to zip error:%@", fileName);
					self.docArchiveError = DOC_ARCHIVE_ADD_ERROR;
					stat = NO;
					break;
				}
				
				// 進捗状況の通知
				if (fileCnt++ % 2 == 0)
				{	
					[self notifiProgress2Client:(fileCnt * 100) / [fileList count]
									   procKind:DOC_ARCHIVE_PROC_ZIP]; 
				}
			}
		}
		
		[archive CloseZipFile2];
			
	}
	@catch (NSException* exception) {
		NSLog(@"doArchive: Caught %@: %@", [exception name], [exception reason]);
		stat = NO;
		_docArchiveError = DOC_ARCHIVE_UNKNOWN_ERROR;
	}
	
	if (archive)
	{	[archive release]; }
	
	[self notifiProgress2Client:100
					   procKind:DOC_ARCHIVE_PROC_ZIP]; 	
	return (stat);
}
#else
// 圧縮の実行(スレッド)
- (BOOL) _doArchiveWithOldAcrhDelete:(BOOL)isDelete
{
	BOOL stat = YES;
	ZipArchive *archive = nil;
	
	@try {
		_docArchiveError = DOC_ARCHIVE_NO_ERROR;
		
		// 対象となるrootフォルダ(1):　/Docmunetsフォルダ
		NSString *rootFolder 
            = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), ROOT_FOLDER];
        // 対象となるrootフォルダ(2):　/Cachesフォルダ
		NSString *rootCachesFolder 
            = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), DOWNLOAD_PICTURE_CACHES_FOLDER];
        
		// Archiveファイルの作成
		archive = [[ZipArchive alloc] init];
		if (! [self makeArchvieFileWithRootFolder:rootFolder zipArchive:archive] )
		{
			NSLog (@"ZipArcive create2 error");
			self.docArchiveError = DOC_ARCHIVE_OPEN_ERROR;
			return (NO);
		}
		
		// 圧縮情報ファイルの追加
		[self addArchiveInfoWithArchive:archive];
		
		// 圧縮対象全ファイル数
        NSInteger totalNum 
            = [self _getTotalTargetFiles:rootFolder cachesFolder:rootCachesFolder];
        NSInteger fileCnt = 0;
            
		// /Docmunetsフォルダ内のサブフォルダまたはファイルを全て圧縮する
        stat = [self _archiveFolderFileWithFolder:ROOT_FOLDER 
                                        zipAcrive:archive isDelete:isDelete 
                                     totalFileNum:totalNum fileCouner:&fileCnt];
        if (stat)
        {
            // /Cachesフォルダ内のサブフォルダまたはファイルを全て圧縮する
            stat = [self _archiveFolderFileWithFolder:DOWNLOAD_PICTURE_CACHES_FOLDER 
                                            zipAcrive:archive isDelete:isDelete 
                                         totalFileNum:totalNum fileCouner:&fileCnt];
        }
        
		[archive CloseZipFile2];
        
	}
	@catch (NSException* exception) {
		NSLog(@"doArchive: Caught %@: %@", [exception name], [exception reason]);
		stat = NO;
		_docArchiveError = DOC_ARCHIVE_UNKNOWN_ERROR;
	}
	
	if (archive)
	{	[archive release]; }
	
	[self notifiProgress2Client:100
					   procKind:DOC_ARCHIVE_PROC_ZIP]; 	
	return (stat);
}
#endif

// 圧縮の実行
- (BOOL) doArchiveWithOldAcrhDelete:(BOOL)isDelete
{
	__block BOOL stat = NO;
	
	// Global Queueの取得
	dispatch_queue_t queue = 
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	// スレッド処理
	dispatch_async(queue, ^{
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		stat = [self _doArchiveWithOldAcrhDelete:isDelete];
		
		[pool release];
		
		// スレッドの完了:メインスレッドに完了を通知
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if ((self.delegate) &&
				([self.delegate respondsToSelector:
					@selector(DocumentsArchiver:completeProcKind:result:)]))
			{
				// メインスレッドに通知
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate DocumentsArchiver:self 
									 completeProcKind:DOC_ARCHIVE_PROC_ZIP
											result:stat];
				});
			}

		});		
	});
	
	
	return (stat);
}

// 復元の実行 (スレッド）
- (BOOL) _doUnArchive
{
	BOOL stat = YES;
	ZipArchive *archive = nil;
	
	@try {
		_docArchiveError = DOC_ARCHIVE_NO_ERROR;
	
		// 復元する圧縮ファイルを取得:フルパス
		BOOL isFindInTemp;
		NSString *backUpFile = [self searchBackupFile: &isFindInTemp isRequestFullpath:YES];
		if (! backUpFile)
		{	
			self.docArchiveError = DOC_ARCHIVE_FILE_NOT_FOUND;
			return (NO);
		}
		NSLog(@"target backup file :%@", backUpFile);
		
		// 対象となるrootフォルダ
		NSString *rootFolder 
			= [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), ROOT_FOLDER]; 
		
		// ArchiveファイルのOPEN
		archive = [[ZipArchive alloc] init];

		if ([_password length] <= 0)
		{	stat = [archive UnzipOpenFile:backUpFile]; }
		else {
			stat = [archive UnzipOpenFile:backUpFile Password:_password]; 
		}
		if (! stat)
		{
			NSLog (@"UNZipArcive open error");
			self.docArchiveError = DOC_ARCHIVE_OPEN_ERROR;
			return (NO);
		}
        
        // 圧縮情報の取得
        BOOL isFind;
        NSDictionary* dictInfo = [self getArchiveInfoWithFindInTemp:&isFind];
        // ver111 submited 3rd以前の圧縮ファイルか？
        BOOL isOld = ( [dictInfo valueForKey:@"archiver_version"] == nil);
        // 解凍先のフォルダ
        NSString *targetFolder 
            = (isOld)? rootFolder : NSHomeDirectory();
		
		// 現状のrootフォルダ以下のフォルダ名とファイル名を一旦、リネームする
		[self rename4DeleteWithRootFolder:rootFolder];

        // 進捗状況表示の為のブロック関数設定
        ZipArchiveProgressUpdateBlock progressBlock = ^(int percentage, int filesProcessed, unsigned long numFiles) {
            [self notifiProgress2Client:percentage
                               procKind:DOC_ARCHIVE_PROC_UNZIP];
        };
        archive.progressBlock = progressBlock;
        
		// rootフォルダに解凍する
        if (![archive UnzipFileTo:targetFolder overWrite:YES]) {
            NSLog (@"unzip file error");
            self.docArchiveError = DOC_ARCHIVE_UNZIP_ERROR;
            stat = NO;
        }
//		if (! [archive UnzipFileTo:targetFolder overWrite:YES
//				   progressHandler: ^(NSUInteger progressPersent)
//			   {
//				   [self notifiProgress2Client:progressPersent
//									  procKind:DOC_ARCHIVE_PROC_UNZIP]; 	
//			   }] )
//		{
//			NSLog (@"unzip file error");
//			self.docArchiveError = DOC_ARCHIVE_UNZIP_ERROR;
//			stat = NO;
//		}
		
		[archive UnzipCloseFile];
		
		// 圧縮情報ファイルを削除
		NSString *aifPath = [rootFolder stringByAppendingPathComponent:ARCHIVE_INFO_FILE_NAME];
		[[NSFileManager defaultManager] removeItemAtPath:aifPath error:nil];
		
		// UnzipFileToメソッドがYESを返してもパスワード違いなどではファイルサイズが0となる
		if (stat && (! [self checkUnZipFileWithRootFolder:rootFolder] ))
		{	
			stat = NO;
			self.docArchiveError = DOC_ARCHIVE_PWD_COLLECT;
		}
		
		// 解凍に失敗していた場合は、解凍途中のものを削除し、リネームを元に戻す
		if (! stat)
		{
			// 解凍途中->削除対象の接頭語の無いもを全て削除:ZIPを除く
			[self deleteRenameFileWithRootFolder:rootFolder isTargetDelHeader:NO];
			
			// rootフォルダ以下のフォルダ名とファイル名のリネームを元に戻す
			[self restore2RenameWithRootFolder:rootFolder];
			
			if (archive)
			{	[archive release]; }
			
			return (NO);
		}

		// 解凍に成功した（Documentフォルダに展開された）のでリネームした現状のファイルを削除する
		[self deleteRenameFileWithRootFolder:rootFolder isTargetDelHeader:YES];
		
		// BackUpがTempフォルダにあった場合は、これを削除する
		if (isFindInTemp)
		{	
			NSError *error = nil;
			[[NSFileManager defaultManager] removeItemAtPath:backUpFile error:&error];
			if (error)
			{
				NSLog (@"doUnArcive Error　delete file:%@ error->%@", 
					   backUpFile, error);
			}
		}			
		  
	}
	@catch (NSException* exception) {
		NSLog(@"doUnArchive: Caught %@: %@", [exception name], [exception reason]);
		stat = NO;
		_docArchiveError = DOC_ARCHIVE_UNKNOWN_ERROR;
	}
	
	if (archive)
	{	[archive release]; }
		
	return (stat);
}

// 復元の実行 
- (BOOL) doUnArchive
{
	__block BOOL stat = NO;
	
	// Global Queueの取得
	dispatch_queue_t queue = 
	dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	// スレッド処理
	dispatch_async(queue, ^{
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		stat = [self _doUnArchive];
		
		[pool release];
		
		// スレッドの完了:メインスレッドに完了を通知
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if ((self.delegate) &&
				([self.delegate respondsToSelector:
				  @selector(DocumentsArchiver:completeProcKind:result:)]))
			{
				// メインスレッドに通知
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate DocumentsArchiver:self 
									completeProcKind:DOC_ARCHIVE_PROC_UNZIP
											  result:stat];
				});
			}
			
		});		
	});
	
	
	return (stat);	
}

// 圧縮情報の取得
- (NSDictionary*) _getArchiveInfoWithFindInTemp:(BOOL*)isFind
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	ZipArchive *archive = nil;
	NSDictionary *infoTable = nil;
	BOOL stat = YES;
	
	@try {
		_docArchiveError = DOC_ARCHIVE_NO_ERROR;
		
		// 復元する圧縮ファイルを取得:フルパス
		//		remarks:isFindのNULLチェックは呼び出し元で済み
		NSString *backUpFile = [self searchBackupFile:isFind isRequestFullpath:YES];
		if (! backUpFile)
		{	
			_docArchiveError = DOC_ARCHIVE_FILE_NOT_FOUND;
			return (nil);
		}
		NSLog(@"target backup file :%@", backUpFile);
		
		// 対象となるrootフォルダ:Tempフォルダ
		NSString *rootFolder = NSTemporaryDirectory();
			// = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), ROOT_FOLDER]; 
		
		// ArchiveファイルのOPEN
		archive = [[ZipArchive alloc] init];
		if ([_password length] <= 0)
		{	stat = [archive UnzipOpenFile:backUpFile]; }
		else {
			stat = [archive UnzipOpenFile:backUpFile Password:_password]; 
		}
		if (! stat)
		{
			NSLog (@"UNZipArcive open error");
			_docArchiveError = DOC_ARCHIVE_OPEN_ERROR;
			return (nil);
		}
		
		// for debug
		/*NSString *docFolder 
			= [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), ROOT_FOLDER];
		NSString *pathDoc = [docFolder stringByAppendingPathComponent:@"20110812_181115.zip"];
		[[NSFileManager defaultManager] copyItemAtPath:backUpFile toPath:pathDoc error:nil];*/
        
        // --------------------------------------------------
        // FIXME: ワーニング除去の為に変更した。(正常に動作しないので要修正)
        // getZipFileContents などを使うようにする？
        // DocumentsArchiver自体が使われていないので、削除も検討
        // --------------------------------------------------
        // 進捗状況表示の為のブロック関数設定
        ZipArchiveProgressUpdateBlock progressBlock = ^(int percentage, int filesProcessed, unsigned long numFiles) {
            [self notifiProgress2Client:percentage
                               procKind:DOC_ARCHIVE_PROC_UNZIP];
        };
        archive.progressBlock = progressBlock;
        
        // rootフォルダに解凍する
        if (![archive UnzipFileTo:rootFolder overWrite:YES]) {
            NSLog (@"unzip one file error");
            _docArchiveError = DOC_ARCHIVE_UNZIP_ERROR;
            stat = NO;
        }
				
//		// rootフォルダに解凍する
//		if (! [archive UnzipOneFileTo:rootFolder overwrite:YES targetFile:ARCHIVE_INFO_FILE_NAME
//				   progressHandler: ^(NSUInteger progressPersent)
//			   {
//				   return;
//			   }] )
//		{
//			NSLog (@"unzip one file error");
//			_docArchiveError = DOC_ARCHIVE_UNZIP_ERROR;
//			stat = NO;
//		}
		
		[archive UnzipCloseFile];
				
		// 対象となる圧縮情報ファイル
		NSString *aifPath = [rootFolder stringByAppendingPathComponent:ARCHIVE_INFO_FILE_NAME];
		// for debug
		/*NSString *docFolder 
		= [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), ROOT_FOLDER];
		NSString *pathDoc = [docFolder stringByAppendingPathComponent:ARCHIVE_INFO_FILE_NAME];
		[[NSFileManager defaultManager] copyItemAtPath:aifPath toPath:pathDoc error:nil];
		*/
		
		// ファイル長さチェック->パスワードの相違を確認
		if (! [self checkUnZipFileWithPath:aifPath fileLength:100] )
		{
			NSLog (@"archive info file pass word collect");
			_docArchiveError = DOC_ARCHIVE_PWD_COLLECT;
			stat = NO;
		}
		
		// 圧縮情報を取得
		if (stat)
		{	infoTable = [self _getArchiveInfoWithPath:aifPath]; }
		
		// 圧縮情報ファイルを削除
		[[NSFileManager defaultManager] removeItemAtPath:aifPath error:nil];
		
	}
	@catch (NSException* exception) {
		NSLog(@"doUnArchive: Caught %@: %@", [exception name], [exception reason]);
		stat = NO;
		_docArchiveError = DOC_ARCHIVE_UNKNOWN_ERROR;
	}
	
	if (archive)
	{	[archive release]; }
	
	[pool release];
	
	return (infoTable);
}

// 圧縮情報の取得
- (NSDictionary*) getArchiveInfoWithFindInTemp:(BOOL*)isFind
{
	BOOL isFindInTemp;
	if (! isFind)
	{	isFind = &isFindInTemp;}
	
	NSDictionary* dict = [self _getArchiveInfoWithFindInTemp:isFind];
	
	// Tempフォルダで不正なArchvieの場合は、ここで全て削除する
	while ( (*isFind) && (! dict) )
	{	
		_docArchiveError4Temp = _docArchiveError;
		
		BOOL isFindTmp;
		NSString *backUpFile = [self searchBackupFile:&isFindTmp isRequestFullpath:YES];
		if (! backUpFile)
		{	
			// 通常はありえない
			self.docArchiveError4Temp = DOC_ARCHIVE_FILE_NOT_FOUND;
			return (nil);
		}
		if (isFindTmp)
		{	[[NSFileManager defaultManager] removeItemAtPath:backUpFile error:nil]; }
		
		dict = [self _getArchiveInfoWithFindInTemp:isFind];
	}
	
	return (dict);
}

// 復元する圧縮ファイルを取得:パス情報なし
- (NSString*) searchBackupFile4Restore:(BOOL*) isFindInTemp isOnlyDouments:(BOOL)isOnly
{
	if (! isOnly)
	{
		return ([self searchBackupFile:isFindInTemp isRequestFullpath:NO]);
	}
	else 
	{
		return ([self searchBackupFile4Documents:NO]);	
	}

}

// Documentsフォルダより最新のバックアップファイルを取得
- (NSString*) getNewBackupFile2DocumentsFolder:(BOOL)isOnlyDouments
{
	return ([self searchBackupFile4Documents:isOnlyDouments]);	
}

@end
