/**
 * @file  SampleStreamingDataManager.m
 * @brief CameraRemoteSampleApp
 *
 * Copyright 2014 Sony Corporation
 */
#import "SampleStreamingDataManager.h"

BOOL isCancel;

@implementation SampleStreamingDataManager {
    BOOL _isStarted;
    NSString *_streamingUrl;
    NSMutableData *_receiveData;
    NSURLConnection *_connection;
    NSURL *_url;
    id<SampleStreamingDataDelegate> _viewDelegate;
}

- (void)start:(NSString *)url
    viewDelegate:(id<SampleStreamingDataDelegate>)viewDelegate
{
    if (!_isStarted) {
        @synchronized(self)
        {
            _isStarted = YES;
            _receiveData = [[NSMutableData alloc] init];
        }
        _streamingUrl = url;
        _viewDelegate = viewDelegate;
#ifdef DEBUG
        NSLog(@"SampleStreamingDataManager : start : _url = %@", _streamingUrl);
#endif
        _url = [NSURL URLWithString:_streamingUrl];
        [self readStream:_url];
        isCancel = NO;
    }
}

- (void)readStream:(NSURL *)url
{
#ifdef DEBUG
    NSLog(@"SampleStreamingDataManager : readStream : url = %@", url);
#endif
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:url
                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                            timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    _connection = [[NSURLConnection alloc] initWithRequest:request
                                                  delegate:self
                                          startImmediately:NO];
    [_connection start];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveResponse:(NSURLResponse *)response
{
    @synchronized(self)
    {
        [_receiveData setLength:0];
    }
    [self performSelectorInBackground:@selector(getPackets) withObject:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    @synchronized(self)
    {
        [_receiveData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection
    didFailWithError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"SampleStreamingDataManager didFailWithError %@", error);
#endif
    if (error.code==-1017) {
        return;
    }
    [self stop];
    [_viewDelegate didStreamingStopped];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
}

/*
 * Start getting JPEG packets
 */
- (void)getPackets
{
    while (true && _isStarted) {
        @autoreleasepool
        {
            [self getJPEGPacket];
        }
    }
}

/*
 * Get a single JPEG packet
 */
- (void)getJPEGPacket
{
    uint8_t startByte[1];
    [self readBytes:1 buffer:startByte];

    uint8_t payloadType[1];
    [self readBytes:1 buffer:payloadType];

    uint8_t sequenceNumber[2];
    [self readBytes:2 buffer:sequenceNumber];

    uint8_t timeStamp[4];
    [self readBytes:4 buffer:timeStamp];

    // read for JPEG image
    [self getPayload:((payloadType[0] & 0x01) == 0x01)];
}

/*
 * Get payload data of JPEG image
 */
- (void)getPayload:(BOOL)isImage
{
    NSInteger jpegDataSize = 0;
    NSInteger jpegPaddingSize = 0;

    // check for first 4 bytes
    [self detectPayloadHeader];

    // get JPEG data size
    uint8_t jData[3];
    [self readBytes:3 buffer:jData];
    jpegDataSize = [self bytesToInt:jData count:3];

    // get JPEG padding size
    uint8_t jPad[1];
    [self readBytes:1 buffer:jPad];
    jpegPaddingSize = [self bytesToInt:jPad count:1];

    // remove 120 bytes from stream
    uint8_t b1[120];
    [self readBytes:120 buffer:b1];

    // read JPEG image
    uint8_t jpegData[jpegDataSize];
    [self readBytes:jpegDataSize buffer:jpegData];

    if (isImage) {
        NSData *imageData =
            [[NSData alloc] initWithBytes:jpegData length:jpegDataSize];
        UIImage *tempImage = [UIImage imageWithData:imageData];
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           if (!isCancel) {
                               [_viewDelegate didFetchImage:tempImage];
                           } else {
                               _viewDelegate = nil;
                           }
                       });
        [imageData release];
    }

    // remove JPEG padding data
    uint8_t padData[jpegPaddingSize];
    [self readBytes:jpegPaddingSize buffer:padData];
}

/*
 * Detect payload header
 */
- (void)detectPayloadHeader
{
    while (true && _isStarted) {
        BOOL isValid = YES;
        @synchronized(self)
        {
            if (_receiveData != NULL && _receiveData.length < 4) {
                isValid = NO;
            }
        }
        if (isValid) {
            break;
        }
        else
        {
            // Wait to receive more data into _receiveData
            sleep(0.01);
        }
    }
    uint8_t checkByte[4];
    checkByte[0] = 0x24;
    checkByte[1] = 0x35;
    checkByte[2] = 0x68;
    checkByte[3] = 0x79;

    NSData *checkData = [NSData dataWithBytes:checkByte length:4];
    BOOL isFound = NO;

    NSRange found = NSMakeRange(0, 4);

    @synchronized(self)
    {
        if (_isStarted) {
            found = [_receiveData rangeOfData:checkData
                                      options:NSDataSearchAnchored
                                        range:found];
        }
    }

    if (found.location != NSNotFound && _isStarted) {
        @synchronized(self)
        {
            // remove extra bytes from the beginning
            [_receiveData replaceBytesInRange:NSMakeRange(0, 4)
                                    withBytes:NULL
                                       length:0];
        }
        return;
    }

    // In case the data is corrupted and first 4 bytes are not checkBytes, this
    // loop will find the checkBytes.
    // NOTE : not used in general cases
    while (!isFound && _isStarted) {
        long maxRangeLength = 0;
        @synchronized(self)
        {
            maxRangeLength = _receiveData.length;
        }
        NSRange currentRange = NSMakeRange(0, maxRangeLength);

        @synchronized(self)
        {
            found = [_receiveData rangeOfData:checkData
                                      options:NSDataSearchBackwards
                                        range:currentRange];
        }
        if (found.location != NSNotFound) {
            NSRange lastFound = found;

            // search if there is checkBytes before the lastFound
            // while (found.location!=NSNotFound && found.location > 4 &&
            // _isStarted)
            //{
            //    maxRangeLength = found.location-1;
            //    lastFound = found;
            //    currentRange = NSMakeRange(0, maxRangeLength);
            //    @synchronized(self)
            //    {
            //        found = [_receiveData rangeOfData:checkData
            //        options:NSDataSearchBackwards range:currentRange];
            //    }
            //}
            isFound = YES; // found latest checkBytes
            @synchronized(self)
            {
                // remove extra bytes from the beginning
                [_receiveData
                    replaceBytesInRange:NSMakeRange(0, lastFound.location + 4)
                              withBytes:NULL
                                 length:0];
            }
        }
        else
        {
            // Wait to receive more data into _receiveData
            sleep(0.1);
        }
    }
    return;
}

/*
 * Read bytes from _receiveData
 */
- (void)readBytes:(NSInteger)length buffer:(uint8_t *)buffer
{
    // remove specified length from _receiveData
    while (true && _isStarted) {
        BOOL isValid = NO;
        @synchronized(self)
        {
            if (_receiveData != NULL && _receiveData.length > length) {
                isValid = YES;
            }
        }
        if (isValid) {
            break;
        }
        else
        {
            // Wait to receive more data into _receiveData
            sleep(0.5);
        }
    }

    // ASSERT : length is sufficient
    @synchronized(self)
    {
        if (_receiveData != NULL && _isStarted) {
            [_receiveData getBytes:buffer length:length];
            [_receiveData replaceBytesInRange:NSMakeRange(0, length)
                                    withBytes:NULL
                                       length:0];
        }
    }
}

- (NSInteger)bytesToInt:(uint8_t *)bytes count:(NSInteger)count
{
    NSInteger val = 0;
    for (int i = 0; i < count; i++) {
        val = (val << 8) | (bytes[i] & 0xff);
    }
    return val;
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [super dealloc];
}

- (void)stop
{
    @synchronized(self)
    {
        _isStarted = NO;
        _viewDelegate = nil;
        if (_receiveData) {
            [_receiveData release];
            _receiveData = nil;
        }
    }
    [_connection cancel];
}

- (BOOL)isStarted
{
    return _isStarted;
}

+ (void)isCancel:(BOOL)value
{
    isCancel = value;
}

@end
