//
//  Common.h
//  iPadCamera
//
//  Created by MacBook on 11/03/28.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
// ダイアログ表示のイベントハンドラ定義：はい・いいえタイプ版
typedef void (^CMN_onCloseDialogYesNo)(id sender, id param, BOOL isYesClick);
#endif

#import <Foundation/Foundation.h>

@class UIView;
@class UIColor;

///
/// 共通クラス
///
@interface Common : NSObject {
    
}

// Contorlの角を丸める
+ (void)cornerRadius4Control:(UIView*)view;

// 女性（または男性）の名前色を取得
+ (UIColor*) getNameColorWithSex:(BOOL)isMen;

// スクロールViewの背景色を取得
+ (UIColor*) getScrollViewBackColor;

// ユーザ情報の背景色を取得
+ (UIColor*) getUserInfoBackColor;

// TextFieldの入力文字数を制限する:shouldChangeCharactersInRangeイベント対応
+ (BOOL)checkInputTextLengh:(UITextField *)textField inRange:(NSRange)range 
		  replacementString:(NSString *)string
				  maxLength:(NSInteger)length;

// 数値入力TextFieldの入力文字種別と文字数を制限する:shouldChangeCharactersInRangeイベント対応
+ (BOOL)checkNumericInputTextLengh:(UITextField *)textField inRange:(NSRange)range 
				 replacementString:(NSString *)string
						 maxLength:(NSInteger)length;

// CaLuLuホームページを開く
+ (void) openCaluLuHomePage;

// 日付を数値(yyyymmdd)に変更する
+ (NSUInteger) convDate2Uint:(NSDate*)date;

// view画面をフラッシュする
+ (void)flashViewWindowWithParentView:(UIView*)view  flashView:(UIView*)flashView;

// soundの再生
+ (BOOL) playSoundWithResouceName:(NSString*)resName ofType:(NSString*)type;
// SystemSoundの再生
+ (BOOL) playSystemSoundWithResouceName:(NSString*)resName ofType:(NSString*)type 
								soundID:(UInt32*)outSoundID;

// メモのラベルを設定ファイルから読み込む
+ (NSDictionary*) getMemoLabelsFromDefault;

// 日付を和暦で取得
+ (NSString*) getDateStringByLocalTime:(NSDate*) date;

// 画像がportrait（縦長）かrandscape（横長）かを判定
+ (BOOL) isImagePortrait:(UIImage*)img;

// sqlite日付形式からNSDateに変換する
+ (NSDate*) convertDate2Sqlite:(NSString*)dateStr;

// POSIX時刻を日付文字に変更する
+ (NSString*) convertPOSIX2String:(NSTimeInterval) timePosi;

// ダイアログを表示する
+ (void) showDialogWithTitle:(NSString*)title message:(NSString*)msg;
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
// はい・いいえのダイアログを表示する
+ (void) showYesNoDialogWithTitle:(NSString *)title message:(NSString *)msg
                      isYesNoType:(BOOL)isYesNo
                    callbackParam:(id)param hCloseDialog:(CMN_onCloseDialogYesNo)hProc;
#endif
// 日付をNSTimeIntervalで取得する
+ (NSTimeInterval) getLocaleDate:(NSDate*)date;

// UUIDの取得
+ (NSString*) getUUID;

// チェックサムの生成
+ (NSInteger) getCheckSumWithText:(NSString*) text;

+ (void)reloadMemo;

@end

///
/// 共通で使用するprotocol
///


// 長押しのprotocol
@protocol LongTotchDelegate<NSObject>

-(void) OnLongTotch:(id)sender;

@end

