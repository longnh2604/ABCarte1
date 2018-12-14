//
//  TemplateInfoListManager.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/05.
//
//

/*
 ** IMPORT
 */
#import <Foundation/Foundation.h>
#import "TemplateInfo.h"

/*
 ** INTERFACE
 */
@interface TemplateInfoListManager : NSObject
{
	NSMutableDictionary* _dicTemplateInfo;		// テンプレートの情報リスト
}

/*
 ** PROPERTY
 */
@property(nonatomic, copy) NSDictionary* dicTemplateInfo;

/**
 initWithDelegate
 初期化
 */
- (id) initWithDelegate:(id) delegate;

/**
 全てのデータを削除する
 */
- (void) removeAllObjects;

/**
 setTemplateInfo
 テンプレート情報を設定する
 @param templInfo テンプレート情報
 @return YES:成功 NO:失敗
 */
- (BOOL) setTemplateInfo:(TemplateInfo*) templInfo;

/**
 テンプレート情報を設定する（複数版）
 @param templateList テンプレート情報
 @return YES:成功 NO:失敗
 */
- (BOOL) setTemplateList:(NSMutableArray*) templateList;

/**
 getCategoryTitle
 全てのカテゴリーのタイトルを取得する
 */
- (NSArray*) getCategoryTitle;

/**
 getSectionCount
 セクション数の取得
 */
- (NSInteger) getSectionCounts;

/**
 getTemplateInfoCountsWithSection
 セクション内のテンプレート数を取得
 @param section セクション
 @return テンプレートの数
 */
- (NSInteger) getTemplateInfoCountsWithSection:(NSInteger) section;

/**
 getSectionTitle
 セクションのタイトルを取得する
 @param section セクション
 @return セクションのタイトル
 */
- (NSString*) getSectionTitle:(NSInteger) section;

/**
 getTemplateInfoBySection
 セクションと行からテンプレート情報を取得する
 @param section セクション
 @param row 行
 @return テンプレート情報
 */
- (TemplateInfo*) getTemplateInfoBySection:(NSInteger) section RowNum:(NSInteger) row;

/**
 removeTemplateInfoBySection
 セクションと行からテンプレート情報を取得する
 @param section セクション
 @param row 行
 @return テンプレート情報
 */
- (void) removeTemplateInfoBySection:(NSInteger) section RowNum:(NSInteger) row;

/**
 UnselectedAll
 全てのテンプレート情報を選択解除状態にする
 */
- (void) UnselectedAll;

/**
 選択されている列と行を取得する
 @param section 列
 @param row 行
 return YES:選択しているものあり NO:なし
 */
- (BOOL) getSelectedInfo:(NSInteger*) section RowNum:(NSInteger*) row;

/**
 列と行を選択する
 @param section 列
 @param row 行
*/
- (void) selecteInfo:(NSInteger) section RowNum:(NSInteger) row;

@end
