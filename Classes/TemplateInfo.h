//
//  TemplateInfo.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/05.
//
//

/*
 ** IMPORT
 */
#import <Foundation/Foundation.h>

/*
 ** INTERFACE
 */
@interface TemplateInfo : NSObject
{
	NSString* _tmplId;				// テンプレートのID
	NSString* _strTemplateTitle;	// テンプレートのタイトル
	NSDate* _dateTemplateUpdate;	// テンプレートの更新日時
	NSString* _strTemplateBody;		// テンプレートの本文
	NSString* _categoryId;			// カテゴリーID
	NSString* _categoryName;		// カテゴリー名
	NSMutableArray* _pictureUrls;	// 画像の場所
	BOOL _selected;					// テンプレートの選択状態
}

/*
 ** PROPERTY
 */
@property(nonatomic, copy) NSString* tmplId;
@property(nonatomic, copy) NSString* strTemplateTitle;
@property(nonatomic, copy) NSDate* dateTemplateUpdate;
@property(nonatomic, copy) NSString* strTemplateBody;
@property(nonatomic, copy) NSString* categoryId;
@property(nonatomic, copy) NSString* categoryName;
@property(nonatomic, assign) NSMutableArray* pictureUrls;
@property(nonatomic, assign) BOOL selected;

/**
 init
 */
- (id) init;

/**
 画像の場所を削除する
 */
- (BOOL) removePictUrlByUrl:(NSString*) url;

/**
 テンプレートの本文を作って返す
 */
- (NSString*) makeTemplateBody;

@end
