//
//  SecretMemoInfo.h
//  iPadCamera
//
//  Created by TMS on 2016/06/24.
//
//

/*
 ** IMPORT
 */
#import <Foundation/Foundation.h>

/*
 ** INTERFACE
 */
@interface SecretMemoInfo : NSObject
{
    NSString* _userId;
    NSString* _secretMemoId;
    NSString* _memo;
    NSDate* _sakuseibi;
    /*
	NSString* _tmplId;				// テンプレートのID
	NSString* _strTemplateTitle;	// テンプレートのタイトル
	NSDate* _dateTemplateUpdate;	// テンプレートの更新日時
	NSString* _strTemplateBody;		// テンプレートの本文
	NSString* _categoryId;			// カテゴリーID
	NSString* _categoryName;		// カテゴリー名
	NSMutableArray* _pictureUrls;	// 画像の場所
	BOOL _selected;					// テンプレートの選択状態
     */
}

/*
 ** PROPERTY
 */

@property(nonatomic, copy) NSString* userId;
@property(nonatomic, copy) NSString* secretMemoId;
@property(nonatomic, copy) NSString* memo;
@property(nonatomic, copy) NSDate* sakuseibi;

@end
