/**
 * @file  HttpAsynchronousRequest.m
 * @brief CameraRemoteSampleApp
 *
 * Copyright 2014 Sony Corporation
 */

#import "HttpAsynchronousRequest.h"

@implementation HttpAsynchronousRequest {
    id<HttpAsynchronousRequestParserDelegate> _parserDelegate;
    NSMutableData *_receiveData;
    NSString *_apiName;
    NSURLConnection *nsurlConnect;
}

BOOL isCancel = NO;
NSMutableArray *urlArry = nil;

/*
 * 通信停止時に、既に登録されているNSURLConnectionをキャンセルする
 * さらに、デリゲートをnilにしておく
 */
+ (void)setCancel:(BOOL)val
{
    isCancel = val;
    if (isCancel) {
        // 登録されている通信のキャンセル
        for (HttpAsynchronousRequest *con in urlArry) {
            [con nsurlCancel];
        }
#ifdef DEBUG
        NSLog(@"Connection cancel [%ld]", (long)[urlArry count]);
#endif
        [urlArry removeAllObjects];
        urlArry = nil;
    }
}

- (void)nsurlCancel
{
    [nsurlConnect cancel];
    _parserDelegate = nil;
    if (_receiveData) {
        [_receiveData setLength:0];
    }
}

- (void)call:(NSString *)url
        postParams:(NSString *)params
           apiName:(NSString *)apiName
    parserDelegate:(id<HttpAsynchronousRequestParserDelegate>)parserDelegate
{
    if (isCancel) {
        return;
    }
    //2015/10/5 TMS 内臓カメラ設定変更時の通信処理対応
    if([url length] > 0 && url != nil){
        _parserDelegate = parserDelegate;
        _apiName = apiName;
        _receiveData = [NSMutableData data];
        [_receiveData retain];
        NSURL *aUrl = [NSURL URLWithString:url];
        NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:aUrl
                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                            timeoutInterval:60.0];
        [request setHTTPMethod:@"POST"];
        NSString *postString = params;
        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        nsurlConnect =
        [[NSURLConnection alloc] initWithRequest:request
                                        delegate:self
                                startImmediately:NO];
        [nsurlConnect start];
        
        // 通信を開始したオブジェクトの登録
        if (!urlArry) {
            urlArry = [[NSMutableArray alloc] initWithObjects:self, nil];
        } else {
            [urlArry addObject:self];
        }
    }
}

- (void)connection:(NSURLConnection *)connection
    didReceiveResponse:(NSURLResponse *)response
{
    [_receiveData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_receiveData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
    didFailWithError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"HttpAsynchronousRequest didFailWithError = %@", error);
#endif
    NSString *errorResponse =
        @"{\"id\":0, \"error\":[16,\"Transport Error\"]}";
    [_parserDelegate
        parseMessage:[errorResponse dataUsingEncoding:NSUTF8StringEncoding]
             apiName:_apiName];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (isCancel) {
#ifdef DEBUG
        NSLog(@"receive cancel!!");
#endif
        return;
    }
    NSInteger conn = [urlArry indexOfObject:self];
    if (conn != NSNotFound) {
        if (_parserDelegate) {  // setCancelで通信がキャンセルされていた場合にデリゲートを呼ばないように
            [_parserDelegate parseMessage:_receiveData apiName:_apiName];
        }
        // NSURLConnection オブジェクトの削除
        [urlArry removeObjectAtIndex:conn];
    }
}

@end
