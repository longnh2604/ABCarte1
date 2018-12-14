//
//  ReferenceWeb.h
//  iPadCamera
//
//  Created by MacBook on 13/04/24.
//
//

#import <UIKit/UIKit.h>

// 参考資料page URL
// #define REFERENCE_PAGE_URL      @"http://192.168.99.173/BmkReference/"

#ifdef NEWS_CUSTOM
#define REFERENCE_PAGE_URL      @"http://calulu.jp/NewsReference/"
#endif
#ifdef BRANCHE_CUSTOM
#define REFERENCE_PAGE_URL      @"http://calulu.jp/BrancheReference/"
#endif
#ifdef AIKI_CUSTOM
#define REFERENCE_PAGE_URL      @"http://calulu4bmk.jp/BmkReference/"
#endif

#ifndef REFERENCE_PAGE_URL
#define REFERENCE_PAGE_URL      @"http://dmy.com/Reference/"
#endif

@interface ReferenceWeb : NSObject <UIWebViewDelegate> {
    UIWebView *webView;
    UIView *maskView;
    UIImageView *prevWndView;       // ページ遷移アニメーション用ImageVie
    
    BOOL    _isFirstLoad;           // 初回ページロードフラグ:初期値=YES 読み込みで=NO
    BOOL    _isReqest2Rotataiton;   // デバイス回転時にWebViewがリクエストされたフラグ
    BOOL    _isRequestCompleted;    // リクエストの完了フラグ
    BOOL    webAccessFlag;          // 参考資料キャッシュ制御用
    CGRect  temp_rect;              // 画面サイズ一時保存用
    UIView  *parentView;            // 呼び出し元Viewの一時保存用
}

@property(nonatomic, copy) NSString* backUrl;          // 戻り先のURL

// 参考資料Webページ表示
-(void) showReferencePageWithParent:(UIView*)myview;

// Web画面表示
- (void) showWebPage:(NSString *)url parentView:(UIView*)myview;

// 表示更新（画面回転時）
-(void) refresh:(BOOL)isPortrait;
-(void) reload;

@end
