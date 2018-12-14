//
//  ShopSelectPopup.h
//  iPadCamera
//
//  Created by 強 片山 on 12/05/11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "../PopUpViewContollerBase.h"

//#define ___demomode
@class ShopItem;

@interface ShopSelectPopup : PopUpViewContollerBase {
    
    // 店舗一覧
    NSDictionary*       _shopTable;

    // 選択されている店舗一覧
    NSArray*            _selectedShopItemList;
    
    // OKが押される前に選択されている店舗一覧
    NSMutableArray*     _tempSelectedShopItemList;
    
    //アカウント店舗より下層にある店舗一覧
    NSMutableArray*     _allShopList;
    //動的ボタンリスト
    NSMutableArray*      _btnList;
    
    //現在表示階層
    NSInteger           _nowLevel;
    //最低表示可能階層
    NSInteger           _initLevel;
    
    //現在作成されたページ数
    NSInteger           _numPage;
    
    //動的ページリスト
    NSMutableArray*     _pages;
    
    NSString*           _titleString;
    /* ------------------------------------ */
    
    IBOutlet UILabel			*lblTitle;			// Titleラベル
	
	//IBOutlet UIScrollView		*scrollView;		// スクロールView
    IBOutlet UIScrollView       *pageScrollView;    // 左右ページView
    
	IBOutlet UIView				*conteinerView;		// 選択ボタンのコンテナView
    IBOutlet UIView             *pageView;          // ページView
    IBOutlet UIButton           *btnPgUpperLevel;   //　上位レベルへの遷移ボタン　：　展示会用に非表示
    IBOutlet UIButton           *btnPgLowerLevel;   //　下位レベルへの遷移ボタン　：　展示会用に非表示
    
    IBOutlet UIButton           *btnMyShop;         // アカウント店舗ボタン
    IBOutlet UIButton           *btnCommonShop;     // 店舗共通ボタン
    
    IBOutlet UIButton           *btnOK;             // OKボタン
    IBOutlet UIButton           *btnCancel;         // キャンセルボタン
    
    /* 以下のボタンは、展示会用に仮設定 */
    IBOutlet UIButton           *btnShop1;          // 店舗1
    IBOutlet UIButton           *btnShop2;          // 店舗2
    IBOutlet UIButton           *btnShop3;          // 店舗3
    IBOutlet UIButton           *btnShop4;          // 店舗4
    IBOutlet UIButton           *btnShop5;          // 店舗5
    IBOutlet UIButton           *btnShop6;          // 店舗6
    IBOutlet UIButton           *btnShop7;          // 店舗7
    IBOutlet UIButton           *btnShop8;          // 店舗8
    IBOutlet UIButton           *btnShop9;          // 店舗9
    IBOutlet UIButton           *btnShop10;         // 店舗10
    IBOutlet UIButton           *btnShop11;         // 店舗11
    IBOutlet UIButton           *btnShop12;         // 店舗12
    
    /* ------------------------------------ */

}

// 複数の選択が可能か：デフォルト=YES
@property (nonatomic) BOOL isMultiSelect;
@property (nonatomic) BOOL isJapanese;


/* 店舗複数選択タイプによる初期化
 * @param   shopTable   レベル毎の現在選択されている店舗itemの一覧：key=レベル
 * @param   popupID     popupID
 * @param   callBack    OKでコールバックするクライアントクラス（呼び出し側）
 * @return  本クラスのインスタンス
 * @remarks この初期化により単一選択の設定となる
 */
- (id) initMultiSelectWithSelected:(NSDictionary*)shopTable     
                           popUpID:(NSUInteger)popUpID 
                                 callBack:(id)callBackDelegate;

/* 店舗単一選択タイプによる初期化
 * @param   shop        現在選択されている店舗item
 * @param   popupID     popupID
 * @param   callBack    OKでコールバックするクライアントクラス（呼び出し側）
 * @return  本クラスのインスタンス
 * @remarks この初期化により単一選択の設定となる
 */
- (id) initSingleSelectWithSelected:(ShopItem*)shopItem     
                           popUpID:(NSUInteger)popUpID 
                          callBack:(id)callBackDelegate;

/* 店舗一覧選択タイプによる初期化
 * @param   shopIDs   現在選択されている店舗IDの一覧 : nilでShopManagerより取得
 * @param   popupID     popupID
 * @param   callBack    OKでコールバックするクライアントクラス（呼び出し側）
 * @return  本クラスのインスタンス
 * @remarks この初期化により単一選択の設定となる
 */
- (id) initMultiSelectWithItems:(NSArray*)shopIDs   
                            popUpID:(NSUInteger)popUpID 
                       callBack:(id)callBackDelegate;

/* ------------------------------------ */

// 各店舗ボタン
- (IBAction)onShopButton:(id)sender;

// 上位レベルへの遷移ボタン
- (IBAction)onPgUpperLevel:(id)sender;

// 下位レベルへの遷移ボタン
- (IBAction)onPgLowerLevel:(id)sender;

-(void)setLabel:(NSString *)string;

@end


