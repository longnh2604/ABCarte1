/**
 * @file  SampleDeviceDiscovery.h
 * @brief CameraRemoteSampleApp
 *
 * Copyright 2014 Sony Corporation
 */

//#import "SampleDeviceListViewController.h"
#import "camaraViewController.h"

@protocol SampleDiscoveryDelegate <NSObject>

- (void)didReceiveDdUrl:(NSString *)ddUrl;

@end

@interface SampleDeviceDiscovery
    : NSObject <SampleDiscoveryDelegate, NSXMLParserDelegate>

- (void)discover:(id)delegate;

@end
