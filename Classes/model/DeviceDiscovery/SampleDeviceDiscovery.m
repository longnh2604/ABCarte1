/**
 * @file  SampleDeviceDiscovery.m
 * @brief CameraRemoteSampleApp
 *
 * Copyright 2014 Sony Corporation
 */

#import "SampleDeviceDiscovery.h"
#import "UdpRequest.h"
#import "DeviceInfo.h"
#import "DeviceList.h"

@implementation SampleDeviceDiscovery {
    id _viewDelegate;
    UdpRequest *_udpRequest;
    DeviceInfo *_deviceInfo;
    NSXMLParser *_rssParser;
    NSMutableArray *_articles;
    BOOL _isParsingService;
    BOOL _isErrorParsing;
    BOOL _isCameraDevice;
    NSString *_currentServiceName;
    NSMutableString *_elementValue;
    int _parseStatus; // 0->friendlyName, 1->version, 2-> ServiceType, 3->
                      // ActionList URL
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [_udpRequest release];

    [super dealloc];
}

- (void)discover:(id)delegate
{
    _viewDelegate = delegate;
    if (_udpRequest == nil) {
        _udpRequest = [[UdpRequest alloc] init];
    }
    [_udpRequest search:self];
}

/*
 * delegate implementation
 */
- (void)didReceiveDdUrl:(NSString *)ddUrl
{
    if (ddUrl != nil) {
        [self parseXMLFileAtURL:ddUrl];
    } else {
        [_viewDelegate didReceiveDeviceList:NO];
    }
}

- (void)parseXMLFileAtURL:(NSString *)url
{
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSData *xmlFile = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:nil
                                                        error:nil];
    _articles = [[NSMutableArray alloc] init];
    _isErrorParsing = NO;
    _parseStatus = -1;
    _rssParser = [[NSXMLParser alloc] initWithData:xmlFile];
    [_rssParser setDelegate:self];
    [_rssParser setShouldProcessNamespaces:NO];
    [_rssParser setShouldReportNamespacePrefixes:NO];
    [_rssParser setShouldResolveExternalEntities:NO];
    [_rssParser parse];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
#ifdef DEBUG
    NSLog(@"SampleDeviceDiscovery File found and parsing started");
#endif
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
#ifdef DEBUG
    NSString *errorString =
        [NSString stringWithFormat:@"Error code %li", (long)[parseError code]];
    NSLog(@"SampleDeviceDiscovery Error parsing XML: %@", errorString);
#endif
    _isErrorParsing = YES;
}

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qName
         attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"device"]) {
        _deviceInfo = [[DeviceInfo alloc] init];
        _isCameraDevice = NO;
    }
    if ([elementName isEqualToString:@"friendlyName"]) {
        _parseStatus = 0;
    }
    if ([elementName isEqualToString:@"av:X_ScalarWebAPI_Version"]) {
        _parseStatus = 1;
    }
    if ([elementName isEqualToString:@"av:X_ScalarWebAPI_Service"]) {
        _isParsingService = YES;
    }
    if ([elementName isEqualToString:@"av:X_ScalarWebAPI_ServiceType"]) {
        _parseStatus = 2;
    }
    if ([elementName isEqualToString:@"av:X_ScalarWebAPI_ActionList_URL"]) {
        _parseStatus = 3;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // Note that it's a irresponsible rule for the sample application.
    if (_parseStatus == 0) {
        [_deviceInfo setFriendlyName:string];
    }
    if (_parseStatus == 1) {
        [_deviceInfo setVersion:string];
    }
    if (_parseStatus == 2 && _isParsingService) {
        _currentServiceName = [string copy];
        if ([@"camera" isEqualToString:_currentServiceName]) {
            _isCameraDevice = YES;
        }
    }
    if (_parseStatus == 3 && _isParsingService) {
        [_deviceInfo addService:_currentServiceName serviceUrl:[string copy]];
        _currentServiceName = nil;
    }
}

- (void)parser:(NSXMLParser *)parser
    didEndElement:(NSString *)elementName
     namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"device"]) {
        if (_isCameraDevice) {
            [DeviceList addDevice:_deviceInfo];
        }
        _isCameraDevice = NO;
    }
    if ([elementName isEqualToString:@"friendlyName"]) {
        _parseStatus = -1;
    }
    if ([elementName isEqualToString:@"av:X_ScalarWebAPI_Version"]) {
        _parseStatus = -1;
    }
    if ([elementName isEqualToString:@"av:X_ScalarWebAPI_Service"]) {
        _isParsingService = NO;
    }
    if ([elementName isEqualToString:@"av:X_ScalarWebAPI_ServiceType"]) {
        _parseStatus = -1;
    }
    if ([elementName isEqualToString:@"av:X_ScalarWebAPI_ActionList_URL"]) {
        _parseStatus = -1;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
#ifdef DEBUG
    NSLog(@"SampleDeviceDiscovery parserDidEndDocument");
    if (_isErrorParsing == NO) {
        NSLog(@"SampleDeviceDiscovery XML processing done!");
    } else {
        NSLog(@"SampleDeviceDiscovery Error occurred during XML processing");
    }
#endif
    if ([DeviceList getSize] > 0) {
        [_viewDelegate didReceiveDeviceList:YES];
    } else {
        [_viewDelegate didReceiveDeviceList:NO];
    }
}

@end
