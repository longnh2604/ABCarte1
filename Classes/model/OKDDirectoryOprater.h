//
//  OKDDirectoryOprater.h
//  Pattoru
//
//  Created by MacBook on 11/02/03.
//  Copyright 2011 okada-denshi-Co.Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

// ディレクトリ操作結果の定義
typedef enum
{
	RESULT_OK			= 0x0000,		// 操作成功
	CHECK_ERROR			= 0x1001,		// ディレクトリ確認失敗
	EXIST_DIRECTORY		= 0x0011,		// 既にそのディレクトリは存在する
	EXIST_FILE			= 0x0018,		// 既にそのファイルは存在する
	NOT_DIRECTORY		= 0x0010,		// そのディレクトリは存在しない
	RESULT_ERROR		= 0x1010,		// 操作失敗
	UNKNOWN_ERROR		= 0x1100,		// 予期しないエラー
} DIR_OPRATE_RESULT;

///
/// ディレクトリ（フォルダ）操作クラス 
///
@interface OKDDirectoryOprater : NSObject 
{
	NSString		*_folderName;		// 対象となるフォルダ名：フルパスで管理する
}

@property(nonatomic, copy) NSString *folderName;

// 初期化
//	folderName:対象となるフォルダ名 　= nilでrootフォルダが対象となる
-(id) initWithFolderName:(NSString*)folderName;

// Cachesフォルダでの初期化
//	folderName:対象となるフォルダ名 　= nilでrootフォルダが対象となる
-(id) initWithCachesFolderName:(NSString*)folderName;

// フォルダの確認と作成
//	isMakeEnfoce	:存在しない場合に作成するか	YES=作成する NO=作成しない
-(DIR_OPRATE_RESULT) chkFolderMake:(BOOL)isMakeEnfoce;

// フォルダの確認（別名）
-(DIR_OPRATE_RESULT) chkAnotherFolder:(NSString*)anotherFolder;

// 指定フォルダ以下のフォルダ（またはファイル）一覧の取得
-(NSArray*)	getFilesWithFolderName;

// フォルダの削除
-(DIR_OPRATE_RESULT) deleteFolderWithFolderName;

// フォルダ名の変更
-(DIR_OPRATE_RESULT) renameFolder:(NSString*)newFolderName;

// Document以下のフォルダを付与してファイル名を取得する
-(NSString*) getDocumentFolderFilenameWithUID:(NSString*)uidFolderName 
							 fileNameNoFolder:(NSString*)fileName;

@end
