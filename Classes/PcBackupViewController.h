//
//  PcBackupViewController.h
//  iPadCamera
//
//  Created by MacBook on 11/08/05.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// MFMailComposeViewControllerのサポート：要 MessageUI.framework
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

// データの復元の完了時のハンドラ定義
typedef void (^restoreComplete)(id sender);

// メールの送受信を行う設定ファイルのキー
#define MAIL_SEND_RECV_ENABLE_KEY       @"mailSendRecvEnable"

///
/// PCバックアップと復元のViewコントローラ
///
@interface PcBackupViewController : UIViewController 
	<UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
{
	
	IBOutlet UILabel		*lblTitle;						// タイトル
	
	IBOutlet UIView			*vwBackupContiner;				// バックアップの作成コンテナView
	IBOutlet UIButton		*btnPcMailSend;					// PCへメール送信ボタン （バックアップ）
	IBOutlet UIButton		*btnMailSetting;				// メールアドレス設定ボタン
	IBOutlet UIView			*vwBackupNowState;				// 現在の状況コンテナView
	IBOutlet UILabel		*lblBackUserTotal;				// お客様総数  （バックアップ）
	IBOutlet UILabel		*lblBackPictureTotal;			// 写真総枚数  （バックアップ）
	IBOutlet UILabel		*lblBackHistTotal;				// カルテ総件数 （バックアップ）
	IBOutlet UITextField	*txtBackMemo;					// 作成時のメモ （バックアップ）
	IBOutlet UIButton		*btnBackupMake;					// バックアップの作成ボタン
	
	IBOutlet UIView			*vwRestoreContiner;				// データの復元コンテナView
	IBOutlet UIButton		*btnRestorePcMailSend;			// PCへメール送信ボタン（復元）
	IBOutlet UIButton		*btnPcRecvDataDelete;			// PC転送データ削除ボタン
	IBOutlet UILabel		*lblRestoreDataSource;			// 復元データの出所（iPad or PC transefer data）
	IBOutlet UILabel		*lblRestorePcTransDataError;	// PC転送データの復元データエラー
	IBOutlet UIView			*vwRestoreData;					// 復元される情報コンテナView
	IBOutlet UILabel		*lblRestoreCreateDate;			// 作成日時  （復元）
	IBOutlet UILabel		*lblRestoreMemo;				// メモ  （復元）
	IBOutlet UILabel		*lblRestoreUserTotal;			// お客様総数  （復元）
	IBOutlet UILabel		*lblRestorePictureTotal;		// 写真総枚数  （復元）
	IBOutlet UILabel		*lblRestoreHistTotal;			// カルテ総件数 （復元）
	IBOutlet UIButton		*btnRestoreData;				// データの復元ボタン
	
	IBOutlet UIView			*vwWaitMessageContiner;			// 処理待機のコンテナ
	IBOutlet UILabel		*lblWaitMessage;				// 処理待機メッセージ（データのバックアップ中...）
	IBOutlet UIActivityIndicatorView *actIndicator;
	IBOutlet UIProgressView	*prgWaitProgress;				// 処理待機のProgressBar
	
	UIBarButtonItem			*btnPrevBackView;				// 前画面へ戻る
	
	NSString*				_password;						// バックアップ用パスワード
	restoreComplete			_hRestorecomplete;				// データの復元の完了時のハンドラ
	
	UIPopoverController		*popoverMailSend;				// メールアドレス設定ポップアップコントローラ
}

@property(nonatomic, assign) id delegate;

// メールアドレス設定
- (IBAction) OnMailAddressSet:(id)sender;
// PCへメール送信
- (IBAction) OnPcMailSend:(id)sender;

// バックアップを作成
- (IBAction) OnBackUpMake:(id)sender;

// PC転送データを削除
- (IBAction) OnPcRecvDataDelete:(id)sender;
// 復元情報の更新
- (IBAction) OnUpadteRestoreInfo:(id)sender;
// データの復元
- (IBAction) OnDataRestore:(id)sender;

// 前画面に戻る
- (IBAction) OnBackView:(id)sender;

// テキスト編集：リターンキー
- (IBAction) onTextDidEndOnExit:(id)sender;

// 初期化
- (id) initWithPassword:(NSString*)password
			  ownerView:(id)owner
			restoreCompleteHandler:(restoreComplete)handler;

// 復元される情報の設定
- (void) restoreInfoSetting;

@end
