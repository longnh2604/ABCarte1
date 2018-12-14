//
//  SendMailHistoryInfo.h
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
@interface SendMailHistoryInfo : NSObject
{
	NSString* _strMailTitle;	// 送信タイトル
	NSInteger _countSendMail;	// 送信メール数
	NSInteger _countSendError;	// 送信メールのエラー数
}

/*
 ** PROPERTY
 */
@property(nonatomic, copy) NSString* strMailTitle;
@property(nonatomic, assign) NSInteger countSendMail;
@property(nonatomic, assign) NSInteger countSendError;

@end
