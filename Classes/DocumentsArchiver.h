//
//  DocumentsArchiver.h
//  ZipArchiveStub
//
//  Created by MacBook on 11/08/02.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// 圧縮・解凍のエラー内容定義: NSUInteger
typedef enum {
	DOC_ARCHIVE_NO_ERROR		= 0x0000,				//　エラーなし
	DOC_ARCHIVE_ARCH_ERROR		= 0x1000,				//　圧縮のエラー
	DOC_ARCHIVE_UNARCH_ERROR	= 0x2000,				//　解凍のエラー
	DOC_ARCHIVE_UNKNOWN_ERROR	= 0x8000,				//　その他のエラー
	
	DOC_ARCHIVE_OPEN_ERROR		
		= DOC_ARCHIVE_ARCH_ERROR | DOC_ARCHIVE_UNARCH_ERROR | 0x0010,	//　圧縮・解凍時のOPENエラー
	DOC_ARCHIVE_ADD_ERROR		= DOC_ARCHIVE_ARCH_ERROR | 0x0020,		//　圧縮時のAddエラー
	DOC_ARCHIVE_FILE_NOT_FOUND	= DOC_ARCHIVE_UNARCH_ERROR | 0x0040,	//　復元する圧縮ファイルなし
	DOC_ARCHIVE_UNZIP_ERROR		= DOC_ARCHIVE_UNARCH_ERROR | 0x0080,	//　解凍エラー
	DOC_ARCHIVE_PWD_COLLECT		= DOC_ARCHIVE_UNARCH_ERROR | 0x0100,	//　パスワード相違
	DOC_ARCHIVE_ARCH_INFO_ERROR	= DOC_ARCHIVE_UNARCH_ERROR | 0x0200,	//　圧縮情報エラー
} DOC_ARCHIVE_ERROR;

// 圧縮・解凍の処理種別
typedef enum {
	DOC_ARCHIVE_PROC_ZIP		= 0x0010,				// 圧縮処理
	DOC_ARCHIVE_PROC_UNZIP		= 0x0100,				// 解凍処理
	DOC_ARCHIVE_PROC_UNKNOWN	= 0xffff,				// 未定義の処理
	
} ZIP_UNZIP_PROC_KIND;

#define DOC_ARCHIVER_VERSION       111                 // DocumentsArchiverバージョン

@protocol DocumentsArchiverDelegate;

///
/// Documentsフォルダの圧縮・解凍を行う
///
@interface DocumentsArchiver : NSObject <NSXMLParserDelegate>
{
	
	NSString		*_archiveFileName;				// 圧縮ファイル名
	NSString		*_password;						// 空文字で省略
	NSMutableDictionary	*_archiveInfo;				// 圧縮情報
	
	DOC_ARCHIVE_ERROR	_docArchiveError;			// エラー内容
	DOC_ARCHIVE_ERROR	_docArchiveError4Temp;		// Tempフォルダエラー内容：ファイルアップロード用
}
@property(nonatomic) DOC_ARCHIVE_ERROR	docArchiveError;
@property(nonatomic) DOC_ARCHIVE_ERROR	docArchiveError4Temp;
@property(nonatomic, assign)	id<DocumentsArchiverDelegate> delegate;

// 初期化：圧縮
- (id) initWithArchiveFileName:(NSString*)fileName password:(NSString*)pwd  
				   archiveInfo:(NSDictionary*)info client:(id)client;

// 初期化：情報取得・解凍
- (id) initWithPassword:(NSString*)pwd client:(id)client;

// 圧縮の実行
- (BOOL) doArchiveWithOldAcrhDelete:(BOOL)isDelete;

// 復元の実行
- (BOOL) doUnArchive;

// 圧縮情報の取得
- (NSDictionary*) getArchiveInfoWithFindInTemp:(BOOL*)isFind;

// 復元する圧縮ファイルを取得:パス情報なし
- (NSString*) searchBackupFile4Restore:(BOOL*) isFindInTemp isOnlyDouments:(BOOL)isOnly;

// Documentsフォルダより最新のバックアップファイルを取得
- (NSString*) getNewBackupFile2DocumentsFolder:(BOOL)isOnlyDouments;

@end

///
/// Documentsフォルダの圧縮・解凍のdelegate
/// 
@protocol DocumentsArchiverDelegate<NSObject>

@optional

// 処理の完了
- (void) DocumentsArchiver:(id)sender 
		  completeProcKind:(ZIP_UNZIP_PROC_KIND) kind result:(BOOL)stat;

// 処理の進捗
- (void) DocumentsArchiver:(id)sender 
		   progressPercent:(NSUInteger)percent ProcKind:(ZIP_UNZIP_PROC_KIND) kind;

@end
