//
//  OKDImageFileManager.h
//  Pattoru
//
//  Created by MacBook on 11/01/28.
//  Copyright 2011 Okada denshi.Co.Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKDDirectoryOprater.h"
#import "def64bit_common.h"
///
/// Imageファイル管理クラス：Imageの入出力を管理する
///
@interface OKDImageFileManager : NSObject 
{
	@private
	NSString	*_folder;				// フォルダ名
	OKDDirectoryOprater *_directoryOpr;	// ディレクトリ操作：/Documentフォルダ内
    OKDDirectoryOprater *_cachesdirOpr;	// ディレクトリ操作：/Cachesフォルダ内
    USERID_INT          _userID;        // userIDの保存（userID指定コンストラクタのみ有効）
}

@property(nonatomic, readonly, copy) NSString *folderName;
@property(nonatomic, assign)BOOL readError;

// 初期化（コンストラクタ）
//   folder = フォルダ名：HomeDirectoryは除く
- (id) initWithFolder:(NSString *)folder;

// 初期化（コンストラクタ）
//   userID = ユーザID
- (id) initWithUserID:(USERID_INT)userID;

// 初期化（コンストラクタ）: Cachesフォルダを対象とする
//   userID = ユーザID
- (id) initWithUserIDInCachesFolder:(USERID_INT)userID;

//2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
// 初期化（コンストラクタ）
// NSHomeDirectory()までの初期化
- (id) initWithAppHome;

/**
 * サムネイルの生成(ユーザデータディレクトリを走査して廻る)
 */
- (void)makeThumnails:(NSInteger)folder;

// Imageの保存：実サイズ版と縮小版の保存
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) saveImage:(UIImage *)image;

// Imageの保存：実サイズ版と縮小版の保存＋連射などで同じファイル名にならないようにチェックを行う
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) saveImageWithCheckSameFileName:(UIImage *)image lastFileName:(NSString *)lastFname;

// Imageの保存：実サイズ版と縮小版の保存(パスなし・拡張子なしファイル名指定)
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) saveImageWithFileName:(UIImage *)image fnPathExtNo:(NSString*)fn;

// Movieの保存：実サイズ版と縮小版の保存(パスなし・拡張子なしファイル名指定)
//		戻り値：パスなしの実サイズ版のファイル名
- (NSString*) saveMovieWithFileName:(NSData *)data fnPathExtNo:(NSString*)fn;

// 実サイズ版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getRealSizeImage:(NSString *)fileName;
// イメージの取得
- (UIImage *)getImage:(NSString *)fileName;
// サイズを指定して実サイズ版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getRealSizeImageWithSize:(NSString *)fileName fitSize:(CGSize)size;

// サイズを指定してイメージの取得 : 実サイズ→サムネイルサイズの順で取得する
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getSizeImageWithSize:(NSString *)fileName fitSize:(CGSize)size;


// テンプレート用実サイズ版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getTemplateRealSizeImage:(NSString *)fileName;
//
// テンプレート用縮小版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getThumbnailSizeImage:(NSString *)fileName;

// テンプレート用の縮小版イメージの取得
//    fileNmae : ファイル名：パスなし　拡張子あり
- (UIImage *) getTemplateThumbnailSizeImage:(NSString *)fileName;

// イメージ（実サイズ版と縮小版の両方）の削除
//		fileName:削除するファイル名（拡張子は実サイズ版：パスなし）
- (BOOL) deleteImageBothByRealSize:(NSString*)fileName;

// イメージ（実サイズ版と縮小版の両方）の移動またはコピー
//		fileName:移動するファイル名（拡張子は実サイズ版：パスなし）
//		dstFolderName:移動先のフォルダ名（HomeDirectoryは除く）
//		isMove  YES:移動  NO:コピー
- (DIR_OPRATE_RESULT) moveCopyImageBoth:(NSString*)fileName 
			 dstFolderName:(NSString*)dstFolder isMoce:(BOOL)isMove;

// Document以下のフォルダを付与してファイル名を取得する
-(NSString*) getDocumentFolderFilename:(NSString*)fileName;

// 指定フォルダ（ユーザ）の全てのイメージ（実サイズ版と縮小版の両方）の削除
- (BOOL) deleteAllImageWithIsDelFolder:(BOOL)isDelFolder;

// ファイル名のみでの存在確認:Document以下のファイルのみを確認する
- (BOOL) isExsitFileWithOutPath:(NSString*)aFile isThumbnail:(BOOL)thumbnail;

@end
