//
//  CommonPopupInfo.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/06.
//
//

/*
 ** IMPORT
 */
#import <Foundation/Foundation.h>

/*
 ** INTERFACE
 */
@interface CommonPopupInfo : NSObject

/*
 ** PROPERTY
 */
@property(nonatomic, copy) NSString* CommonId;			// 共通ID
@property(nonatomic, copy) NSString* strTitle;			// セルに表示されるタイトル
@property(nonatomic, assign) NSTimeInterval updateTime;	// 更新日時
@property(nonatomic, assign) BOOL selected;				// 該当セルの選択フラグ

/**
 初期化
 */
- (id) init;

@end
