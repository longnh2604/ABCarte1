/**
 * @file  HttpSynchronousRequest.m
 * @brief CameraRemoteSampleApp
 *
 * Copyright 2014 Sony Corporation
 */

#import "HttpSynchronousRequest.h"

@implementation HttpSynchronousRequest

- (NSData *)call:(NSString *)url postParams:(NSString *)params
{
    //2015/10/5 TMS 内臓カメラ設定変更時の通信処理対応
    if([url length] > 0 && url != nil){
        NSURL *aUrl = [NSURL URLWithString:url];
        NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:aUrl
                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                            timeoutInterval:60.0];
        [request setHTTPMethod:@"POST"];
        NSString *postString = params;
        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:&response
                                                         error:&error];
        
        if (error == nil) {
            return data;
        }
        return nil;
    }else{
        return nil;
    }
}

@end