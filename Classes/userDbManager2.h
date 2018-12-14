//
//  userDbManager2.h
//  iPadCamera
//
//  Created by TMS on 2016/02/15.
//
//

#import <Foundation/Foundation.h>

@interface userDbManager2 : NSObject
{
    NSString *dbPath;
}
//初期化(コンストラクタ)
- (id)init;

/**
 DELC Sasage
 デモユーザーではないユーザーの数を返す
 */
- (NSInteger)getCountStoreUsers;
/**
 DELC Sasage
 デモユーザーではないユーザーの数を返す
 */
- (NSArray *)getDemoUserIds;
/**
 デモユーザの画像をすべて取得
 */
- (NSArray *)getDemoPictures;
/**
 デモユーザの動画をすべて取得
 */
- (NSArray *)getDemoVideos;
/*
 
 最新のDBの情報を既存DBにマージする
*/
- (BOOL)mergeDB:(NSString *)otherDbPath;
@end
