//
//  ShopSelectPopup.m
//  iPadCamera
//
//  Created by 強 片山 on 12/05/11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "../Common.h"

#import "ShopSelectPopup.h"

#import "ShopManager.h"
#import "ShopItem.h"

// ボタンの選択状態を表すビット
#define BUTTON_STATE_PUSH	(NSInteger)0x10000000

@implementation ShopSelectPopup

@synthesize isMultiSelect;
@synthesize isJapanese;

#pragma mark local_methods

// ボタンの選択状態の設定
-(void) _setButtonState:(UIButton*)button isSelect:(BOOL)state
{
	if (state)
	{
		// ボタンを非選択状態にする
		button.tag &= ~BUTTON_STATE_PUSH;
		[button setBackgroundImage:
		 [UIImage imageNamed:@"button_normal_w160Xh32.png"] 
						  forState:UIControlStateNormal];
	}
	else
	{
		// ボタンを選択状態にする
		button.tag |= BUTTON_STATE_PUSH;
		[button setBackgroundImage:
		 [UIImage imageNamed:@"button_push_w160Xh32.png"] 
						  forState:UIControlStateNormal];
	}
}

// 店舗リストページ作成
- (void) _setNewPage:(NSArray*)items
{
    UIScrollView *tempPage = [[UIScrollView alloc]init];
    tempPage.frame = CGRectMake((_numPage) * 560 , 0,560, 225);
#ifdef ___demomode
    // 展示会用の仮処理
    NSMutableArray *sampBtns = [NSMutableArray array];

    [sampBtns addObject:btnShop1];
    [sampBtns addObject:btnShop2];
    [sampBtns addObject:btnShop3];
    [sampBtns addObject:btnShop4];
    [sampBtns addObject:btnShop5];
    [sampBtns addObject:btnShop6];
    [sampBtns addObject:btnShop7];
    [sampBtns addObject:btnShop8];
    [sampBtns addObject:btnShop9];
    [sampBtns addObject:btnShop10];
    [sampBtns addObject:btnShop11];
    [sampBtns addObject:btnShop12];
#else

#endif
    NSInteger itemNum = 0;
    for (NSInteger idx = 0; idx < [items count]; idx++)
    {
        ShopItem *item = [items objectAtIndex:idx];
        
        // 選択があるかを確認
        BOOL isSelect = NO;
        for (NSString* sID in _selectedShopItemList)
        {
            NSInteger iID = [sID intValue];
            if (iID == item.shopID)
            {
                isSelect = YES;
                break;
            }
        }
        
        UIButton *btn = nil;
        if(idx == 0 && _numPage == 0){
                // 共通店舗
                btn = btnCommonShop;
        }else if(idx == 1 && _numPage == 0){
                // アカウント店舗
                btn = btnMyShop;
        }else{
#ifdef ___demomode
                // その他の子店舗：展示会用の仮設定
                if ((idx - 2) < 12) {
                    btn = [sampBtns objectAtIndex:(idx - 2)];
                }
#else
                btn = [UIButton buttonWithType:UIButtonTypeCustom];
                if (itemNum == 0) {
                    btn.frame = CGRectMake(20, 20,160, 32);
                }else{
                    btn.frame = CGRectMake(((itemNum) % 3 )*180 +20, ((itemNum / 3) * 48 + 20),160, 32);                  
                }
                [btn addTarget:self action:@selector(onShopButton:) forControlEvents:UIControlEventTouchUpInside];
                [tempPage addSubview:btn];
                tempPage.contentSize = CGSizeMake(560, (((itemNum)/ 3) * 48 )+ 68);
                itemNum++;
#endif
        }
        if (! btn)
        {   continue; }     // 念のため
        
        // ボタンを表示
        btn.hidden = NO;
        // ボタン名称の設定
        [btn setTitle:item.shopName forState:UIControlStateNormal];
        // ボタンのタグの基本設定
        btn.tag = item.shopID;
        // ボタンの選択状態の設定
        [self _setButtonState:btn isSelect: !isSelect];
        [_btnList addObject:btn];
        
    }
    if(itemNum > 0){
        [_pages addObject:tempPage];
        [pageScrollView addSubview:tempPage];
        _numPage++;
        pageScrollView.contentSize = CGSizeMake((_numPage * 560), 225);
    }
    [tempPage release];
}

-(void)moveRightPage{
    if (pageScrollView.tracking) {
        return;
    }
    _nowLevel = (pageScrollView.contentOffset.x / 560) + 1;
    if(_nowLevel < _numPage){
    _nowLevel++;
    [pageScrollView setContentOffset:CGPointMake((((_nowLevel - _initLevel)) * 560), 0) animated:YES];
    }
}

-(void)moveLeftPage{
    if (pageScrollView.tracking) {
        return;
    }
    _nowLevel = ((int)pageScrollView.contentOffset.x / 560) + 1;
    if (_nowLevel > _initLevel) {
        _nowLevel--;
        [pageScrollView setContentOffset:CGPointMake(((_nowLevel - _initLevel) * 560), 0) animated:YES];

    }
}
-(void)createAllPage:(NSInteger)carrLevel{
    NSMutableArray *reqArray = [NSMutableArray array];
    for (ShopItem* item in _allShopList) {
        if (item.shopLevel == carrLevel) {
            [reqArray addObject:item];
        }
    }
    while ([reqArray count] > 0) {
        [self _setNewPage:reqArray];
        carrLevel++;
        [reqArray removeAllObjects];
        for (ShopItem* item in _allShopList) {
            if (item.shopLevel == carrLevel) {
                [reqArray addObject:item];
            }
        }
    }
}

-(NSArray*)getButtonState{
#ifdef ___demomode
    // 展示会用の仮処理
    _btnList = [NSArray arrayWithObjects:
                btnCommonShop, btnMyShop,
                btnShop1, btnShop2, btnShop3, btnShop4, btnShop5, 
                btnShop6, btnShop7, btnShop8, btnShop9, btnShop10,
                btnShop11, btnShop12, nil
                ];
#endif
    
    NSMutableArray *seletedShops = [NSMutableArray array];
    
    // 選択されているボタンを取り出す
    for (UIButton* btn in _btnList)
    {
        // 選択状態であればリストに加える
        if ((btn.tag & BUTTON_STATE_PUSH) != 0)
        {
            // タグ=店舗IDのみを取り出す
            NSInteger sID =btn.tag & ~BUTTON_STATE_PUSH;
            
            [seletedShops addObject:[NSString stringWithFormat:@"%ld", (long)sID]];
        }
        
    }
    
    return (seletedShops);
}

//親の状態を変更した場合、子も連動させる
-(void) _setChildButtonState:(UIButton *)selectBtn
                       state:(BOOL)state{
    //親ボタンのID取得
    SHOPID_INT parID;
    if ((selectBtn.tag & BUTTON_STATE_PUSH) != 0){
        parID = selectBtn.tag & ~BUTTON_STATE_PUSH;
    }else {
        parID = (SHOPID_INT)selectBtn.tag;
    }

    NSInteger crrLevel = [[ShopManager defaultManager]getShopLevelWithShopID:parID ];
    crrLevel++;
    NSMutableArray* childList = [[NSMutableArray alloc]init];
    NSMutableArray *parIdList = [[NSMutableArray alloc]init];

    [childList addObjectsFromArray:[[ShopManager defaultManager]getChildShopList:parID level:crrLevel]  ];

    NSInteger crrChildID = 0;
    
    NSInteger crrBtnID = 0;
    while ([childList count] > 0) {
        for (ShopItem *childitem in childList) {
            for (UIButton* crrBtn in _btnList) {
                crrChildID = childitem.shopID;
                if ((crrBtn.tag & BUTTON_STATE_PUSH) != 0){
                    crrBtnID =crrBtn.tag & ~BUTTON_STATE_PUSH;
                }else {
                    crrBtnID =crrBtn.tag;
                }
                if (crrChildID == crrBtnID) {
                    [self _setButtonState:crrBtn isSelect:state];
                }
            }
            [parIdList addObject:[NSNumber numberWithInteger:crrChildID]];
        }

        [childList removeAllObjects];
        crrLevel++;
        [childList addObjectsFromArray:[[ShopManager defaultManager] getMultiChildShopList:parIdList
                                                                                     level:crrLevel ]];
        [parIdList removeAllObjects];

    }
    [parIdList release];
    [childList release];
}

// alert表示
- (void) alertDisp:(NSString*) message alertTitle:(NSString*) altTitle
{
	
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:altTitle
							  message:message
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil
							  ];
	[alertView show];
	[alertView release];	
}

#pragma mark life_cycle

/* 店舗複数選択タイプによる初期化
 * @param   shopTable   レベル毎の現在選択されている店舗itemの一覧：key=レベル
 * @param   popupID     popupID
 * @param   callBack    OKでコールバックするクライアントクラス（呼び出し側）
 * @return  本クラスのインスタンス
 * @remarks この初期化により単一選択の設定となる
 */
- (id) initMultiSelectWithSelected:(NSDictionary*)shopTable     
                           popUpID:(NSUInteger)popUpID 
                          callBack:(id)callBackDelegate
{
    if ( (self = [super initWithPopUpViewContoller:popUpID
                                 popOverController:nil callBack:callBackDelegate] ) )
    {
        // メンバの保存
        _shopTable = [shopTable mutableCopy];
        _selectedShopItemList = nil;
        
        self.isMultiSelect = YES;
        
#ifndef CALULU_IPHONE
		self.contentSizeForViewInPopover = CGSizeMake(560.0f, 280.0f);
#endif
    }
    
    return  (self);
}


/* 店舗単一選択タイプによる初期化
 * @param   shop        現在選択されている店舗item
 * @param   popupID     popupID
 * @param   callBack    OKでコールバックするクライアントクラス（呼び出し側）
 * @return  本クラスのインスタンス
 * @remarks この初期化により単一選択の設定となる
 */
- (id) initSingleSelectWithSelected:(ShopItem*)shopItem     
                            popUpID:(NSUInteger)popUpID 
                           callBack:(id)callBackDelegate
{
    if ( (self = [super initWithPopUpViewContoller:popUpID
                                 popOverController:nil callBack:callBackDelegate
                                           nibName:@"shopSelectPopup"] ) )
    {
        // メンバの保存
        _shopTable = nil;
        _selectedShopItemList = nil;
        _titleString = nil;
        
        self.isMultiSelect = NO;
        isJapanese = YES;
        
        if (shopItem !=nil) {
            _selectedShopItemList  = [[NSArray alloc]initWithObjects:[NSString stringWithFormat:@"%d",shopItem.shopID], nil ];
        }else {

        }
        
#ifndef CALULU_IPHONE
		self.contentSizeForViewInPopover = CGSizeMake(560.0f, 370.0f);
#endif
    }
    
    return  (self);
}

/* 店舗一覧選択タイプによる初期化
 * @param   shopIDs   現在選択されている店舗IDの一覧 : nilでShopManagerより取得
 * @param   popupID     popupID
 * @param   callBack    OKでコールバックするクライアントクラス（呼び出し側）
 * @return  本クラスのインスタンス
 * @remarks この初期化により単一選択の設定となる
 */
- (id) initMultiSelectWithItems:(NSArray*)shopIDs   
                        popUpID:(NSUInteger)popUpID 
                       callBack:(id)callBackDelegate
{
    if ( (self = [super initWithPopUpViewContoller:popUpID
                                 popOverController:nil callBack:callBackDelegate
                                           nibName:@"shopSelectPopup"] ) )
    {
        // メンバの保存
        _shopTable = nil;
        _selectedShopItemList = (shopIDs)?
            [shopIDs mutableCopy] : [ [[ShopManager defaultManager] getSeletedShopIDs] mutableCopy];
        
        self.isMultiSelect = YES;
        isJapanese = YES;
        
#ifndef CALULU_IPHONE
		self.contentSizeForViewInPopover = CGSizeMake(560.0f, 370.0f);
#endif
    }
    
    return  (self);

}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //変数初期化
    _btnList = [[NSMutableArray alloc]init];
    _tempSelectedShopItemList = [[NSMutableArray alloc]init];
    _pages = [[NSMutableArray alloc]init];
    _allShopList = [[NSMutableArray alloc]init];
    _numPage = 0;
    
    if (_titleString) {
        lblTitle.text = _titleString;
    }
    
    // 選択可能な店舗Itemの一覧を取得
    NSArray *items = [[ShopManager defaultManager] getChilidShopItemsByAccountShop];
    //初期階層を設定
    _initLevel = [[ShopManager defaultManager] getShopLevelWithShopID:[[ShopManager defaultManager]getAccountShopID]];
    _nowLevel = _initLevel;
    
    //全ショップリスト作成
    [_allShopList removeAllObjects];
    [_allShopList addObjectsFromArray:[[ShopManager defaultManager] getAllShopList:_initLevel + 1]];
    [self _setNewPage:items];
    // 子店舗をすべて登録メニュー画面作成
    // 子・孫店舗のボタンを下に重ねて生成している。
    // 中間層の店舗だけを有効にしようとしても、重なった下位層の店舗も同時に有効になってしまうため、コメントアウト
//    [self createAllPage:(_nowLevel + 2)];
    
    // titleの角を丸める
	[Common cornerRadius4Control:lblTitle];
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion>=7.0) {
        [btnOK setBackgroundColor:[UIColor whiteColor]];
        [[btnOK layer] setCornerRadius:6.0];
        [btnOK setClipsToBounds:YES];
        [[btnOK layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[btnOK layer] setBorderWidth:1.0];

        [btnCancel setBackgroundColor:[UIColor whiteColor]];
        [[btnCancel layer] setCornerRadius:6.0];
        [btnCancel setClipsToBounds:YES];
        [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[btnCancel layer] setBorderWidth:1.0];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if (isJapanese) {
        [btnOK setTitle:@"O K" forState:UIControlStateNormal];
        [btnCancel setTitle:@"キャンセル" forState:UIControlStateNormal];
    } else {
        [btnOK setTitle:@"O K" forState:UIControlStateNormal];
        [btnCancel setTitle:@"Cancel" forState:UIControlStateNormal];
    }
}

- (void) dealloc
{
    if (_shopTable) {
        [_shopTable release];
    }
    if (_selectedShopItemList) {
        [_selectedShopItemList release];        
    }
    if (_btnList) {
        [_btnList release];
    }
    if (_pages) {
        [_pages release];
    }
    if (_allShopList) {
        [_allShopList release];
    }
    
    if(_tempSelectedShopItemList){
        [_tempSelectedShopItemList release];
    }
    [btnOK release];
    [btnCancel release];
    [super dealloc];
}

#pragma mark PopUpViewContollerBase_override

/** delegate objectの設定:設定ボタンのclick時にコールされる
 * @param       なし
 * @return      NSArray* 選択された店舗IDの一覧
 */

- (id) setDelegateObject
{
    NSMutableArray *resultList = [[NSMutableArray alloc]initWithArray:[self getButtonState]];
    if ([resultList count] == 0){
        [resultList addObject:[NSString stringWithFormat:@"%d", [[ShopManager defaultManager]getAccountShopID]]];
    }
    return resultList;
}

#pragma mark control_events

// 各店舗ボタン
- (IBAction)onShopButton:(id)sender
{
    UIButton *button = (UIButton*)sender;
	
	// touch前の選択状態
	BOOL select = ((button.tag & BUTTON_STATE_PUSH) != 0);
    
    //マルチモードの場合、ボタンが押された場合、子IDも連動して動作。
    if(isMultiSelect){
        // ボタンの選択状態の設定
        [self _setButtonState:button isSelect:select];

        NSInteger count = 0;
        for(UIButton* btn in _btnList){
            if ((btn.tag & BUTTON_STATE_PUSH) != 0) {
                count++;
            }
        }
        if (count == 0) {
            // 全未選択にならないようにする
            [self _setButtonState:button isSelect:NO];
        }
        
        //アカウント店舗のボタンの場合、連動を行わない
        NSInteger buttonId = 0;
        if ((button.tag & BUTTON_STATE_PUSH) != 0){
            buttonId =button.tag & ~BUTTON_STATE_PUSH;
        }else {
            buttonId=button.tag;
        }
        
        // 子IDの連動
//        if(buttonId != [[ShopManager defaultManager]getAccountShopID]){
//            [self _setChildButtonState:button state:select];
//        }
    }else {
        //すべてのボタン選択解除
        for(UIButton* btn in _btnList){
            [self _setButtonState:btn isSelect:YES];
        }
        // ボタンの選択状態の設定
        [self _setButtonState:button isSelect:NO];
    }
}

// 上位レベルへの遷移ボタン
- (IBAction)onPgUpperLevel:(id)sender
{
    [self moveRightPage];
}

// 下位レベルへの遷移ボタン
- (IBAction)onPgLowerLevel:(id)sender
{
    [self moveLeftPage];
}

// 設定ボタンクリック
- (IBAction) OnSetButton:(id)sender
{
    if (!isMultiSelect && [[self getButtonState] count] == 0) {
        [self alertDisp:@"選択された店舗がありません。\n(誠に恐れ入りますが\n再操作をお願いいたします)" alertTitle:@"店舗の選択"];       
    }else {
      	if (delegate != nil) 
        {
            // callback Objectの設定 : nilでイベント中断
            if ( (_delegateObject = [self setDelegateObject]) == nil)
            {	return; }
            
            // クライアントクラスへcallback
            [delegate OnPopUpViewSet:_popUpID setObject:_delegateObject];
        }	
        
        [self closeByPopoverContoller];  
    }
}
#pragma mark public_methods

/*
 * ポップアップのタイトル文字の保持
 */
-(void)setLabel:(NSString *)string
{
    _titleString = string;
}

- (void)viewDidUnload {
    [btnOK release];
    [btnCancel release];
    btnOK = nil;
    btnCancel = nil;
    [super viewDidUnload];
}
@end
