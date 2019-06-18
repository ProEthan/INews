//
//  ViewController.m
//  QRScan
//
//  Created by Jerry on 16/10/10.
//  Copyright © 2016年 yejunyou. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+YYExtension.h"
#import "QRCodeScanBottom.h"
#import "QRCodeScanFailView.h"


#define BOTTOM_VIEW_HEIGHT  100.0f
#define SCAN_CROP_SIZE      200
#define SCAN_BOX_SIZE       240

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    UIImageView * scanline;         // 扫描线
    CGFloat scanLineStartCY;        // 扫描线最初的中心点y轴位置
    NSTimer * scanTimer;            // 扫描动画timer
    BOOL isScanUp;                  // 扫描方向
    BOOL isLightOn;                 // 闪光灯是否打开
    UIView *_contentView;           // 用来扫描失败时，隐藏扫描ui
    QRCodeScanBottom *bottomView;   // 底部 “相册” “灯光”
    QRCodeScanFailView *_failView;  // 识别/扫描失败view
    
    // iOS7QRCode
    AVCaptureMetadataOutput* _output;
    AVCaptureSession * _session;
    AVCaptureVideoPreviewLayer* _preview;
    AVCaptureDevice * _device;
    BOOL _isRead;
}
@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:35.0/255.0 green:35.0/255.0 blue:35.0/255.0 alpha:1];
    [self setTitle:@"扫描二维码"];
    
    [self setupScanCoverAndLine];//初始化界面
    [self setupBottomViews];
    [self checkPermissionAndInitCamera];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    scanTimer = nil;
    if (_session)
    {
        [_preview removeFromSuperlayer];
        for(AVCaptureInput *input in _session.inputs) {
            [_session removeInput:input];
        }
        
        for(AVCaptureOutput *output in _session.outputs) {
            [_session removeOutput:output];
        }
        [_output setMetadataObjectsDelegate:nil queue:dispatch_get_main_queue()];
        [_session stopRunning];
        _session = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkPermissionAndInitCamera];
    [self startScan];
    _isRead = NO;
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopScan];
    [self turnOffLight];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - 扫描相关设置
// 检查相机是否授权
- (void)checkPermissionAndInitCamera{
    if (![self isCanUseCamera]) {
        [[[UIAlertView alloc] initWithTitle:@"无法使用相机哦" message:@"请在iPhone的“设置-隐私-相机”中,允许访问相机" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"好的", nil] show];
        return;
    }
    
    NSString *mediaType = AVMediaTypeVideo; // Or AVMediaTypeAudio
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    switch (authStatus)
    {
        case AVAuthorizationStatusAuthorized:
        {
            [self setupCamera];
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if(granted){
                        [self setupCamera];
                    }
                });
            }];
            break;
        }
            
        default:break;
    }
}

- (BOOL)isCameraAvailable;
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    return [videoDevices count] > 0;
}

- (BOOL)isCanUseCamera{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        return NO;
    }
    return YES;
}


- (void)setupCamera
{
    if ([self isCameraAvailable]) {
        [self performSelector:@selector(setupIOS7Camera) withObject:nil afterDelay:0.2f];
        return;
    }
}

-(void)setupIOS7Camera
{
    if (!_device) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
    
    // Output
    if (!_output) {
        _output = [[AVCaptureMetadataOutput alloc] init];
    }
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Session
    if(!_session){
        _session = [[AVCaptureSession alloc]init];
    }
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:input])
    {
        [_session addInput:input];
    }
    
    if ([_session canAddOutput:_output])
    {
        [_session addOutput:_output];
    }
    // QRCode扫描设置
    if ([_output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
        _output.metadataObjectTypes = [NSArray arrayWithObject:AVMetadataObjectTypeQRCode];
    }
    
    CGSize size = self.view.bounds.size;
    size.height += 44;          //44 是顶部工具条的高度
    CGRect cropRect = CGRectMake(((CGRectGetWidth(self.view.frame) - SCAN_BOX_SIZE) / 2), ((CGRectGetHeight(self.view.frame) - SCAN_BOX_SIZE - BOTTOM_VIEW_HEIGHT) / 2) + 44 - 10, SCAN_BOX_SIZE, SCAN_BOX_SIZE - 10);
    _output.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                        cropRect.origin.x/size.width,
                                        cropRect.size.height/size.height,
                                        cropRect.size.width/size.width);
    
    // Preview
    if (!_preview) {
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    }
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview.frame = CGRectMake(0, 0, self.view.yy_width, self.view.yy_height);
    [self.view.layer insertSublayer:_preview atIndex:0];
    
    [_session startRunning];
}

// 创建底部控件view
- (void)setupBottomViews
{
    if (bottomView != nil) return;
    
    bottomView = [[QRCodeScanBottom alloc] init];
    bottomView.yy_x = 0;
    bottomView.yy_y = CGRectGetMaxY(self.view.frame) - 2 * BOTTOM_VIEW_HEIGHT;
    bottomView.yy_width = self.view.yy_width;
    bottomView.yy_height = BOTTOM_VIEW_HEIGHT;
    [self.view addSubview:bottomView];
    
    [bottomView.albumn addTarget:self action:@selector(onAlbumnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView.light addTarget:self action:@selector(onLightClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupQRCodeFailView
{
//    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"QRCodeScanFailView" owner:nil options:nil];
//    if (views.count > 0) {
//        _failView = views[0];
//        CGRect bottomFrame = self.view.frame;
//        bottomFrame.origin.y -= 64;
//        _failView.frame = bottomFrame;
//        [self.view addSubview:bottomView];
//        [_failView didClickCommitButton:^{
//            
//            _contentView.hidden = NO;
//            [self setupIOS7Camera];
//            [self startScan];
//            _isRead = NO;
//            _failView = nil;
//        }];
//    }
//    [self.view addSubview:_failView];
//    [self.view bringSubviewToFront:bottomView];
//    _failView.hidden = YES;
}

- (void)setupScanCoverAndLine
{
    isScanUp = NO;
    _contentView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_contentView];
    
    // 扫描框
    UIImageView* scanBoxView = [[UIImageView alloc] init];
    scanBoxView.image = [UIImage imageNamed:@"QRCode_ScanBox"];
    scanBoxView.yy_x = (self.view.yy_width - SCAN_BOX_SIZE) / 2;
    scanBoxView.yy_y = (self.view.yy_height - SCAN_BOX_SIZE) / 2;
    scanBoxView.yy_width = SCAN_BOX_SIZE;
    scanBoxView.yy_height = SCAN_BOX_SIZE;
    [_contentView addSubview:scanBoxView];
    
    // 扫描线
    scanLineStartCY = scanBoxView.yy_y + 10;
    CGRect frame = self.view.frame;
    scanline = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame) - 240) / 2, scanLineStartCY, 240, 3)];
    scanline.image = [UIImage imageNamed:@"QRCode_ScanLine"];
    [_contentView addSubview:scanline];
    
    // Cover
    CGRect boxFrame = scanBoxView.frame;
    UIColor *bgColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7];
    int width = CGRectGetWidth(frame);
    int height = CGRectGetHeight(frame);
    int boxY = CGRectGetMinY(boxFrame);
    int boxX = CGRectGetMinX(boxFrame);
    int boxHeight = CGRectGetHeight(boxFrame);
    int boxWidth = CGRectGetWidth(boxFrame);
    
    UIView *bg;
    bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, boxY)];
    bg.backgroundColor = bgColor;
    [_contentView addSubview:bg];
    bg = [[UIView alloc] initWithFrame:CGRectMake(0, boxY, boxX, boxHeight)];
    bg.backgroundColor = bgColor;
    [_contentView addSubview:bg];
    bg = [[UIView alloc] initWithFrame:CGRectMake(boxX + boxWidth, boxY, width - boxX - boxWidth, boxHeight)];
    bg.backgroundColor = bgColor;
    [_contentView addSubview:bg];
    bg = [[UIView alloc] initWithFrame:CGRectMake(0, boxY + boxHeight, width, height - boxY - boxHeight + BOTTOM_VIEW_HEIGHT)];
    bg.backgroundColor = bgColor;
    [_contentView addSubview:bg];
    
    // Message
    NSString *text = @"将取景框对准二维码即可自动扫描";
    UIFont *font = [UIFont systemFontOfSize:14];
    CGSize size = [text sizeWithFont:font];
    CGRect labelFrame = CGRectMake((width - size.width) / 2, boxY + boxHeight + 10, size.width, size.height);
    
    UILabel* label = [[UILabel alloc] initWithFrame:labelFrame];
    label.backgroundColor = [UIColor clearColor];
    label.textColor =[UIColor whiteColor];
    label.text = text;
    label.font = font;
    label.textAlignment = NSTextAlignmentCenter;
    [_contentView addSubview:label];
}

#pragma mark - 我的相册/灯光
- (IBAction)onAlbumnClicked:(id)sender
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        //1.初始化相册拾取器
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        //2.设置代理
        controller.delegate = self; // 需要遵循两个代理协议
        //3.设置资源：
        controller.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        //4.转场动画
        controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:controller animated:YES completion:NULL];
        
    }else{
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"设备不支持访问相册，请在设置->隐私->照片中进行设置！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
    }
}

- (IBAction)onLightClicked:(id)sender
{
    [self toggleLight];
}

- (IBAction)onMyQRCodeClicked:(id)sender
{
    
}

// 开灯
- (void)toggleLight
{
    isLightOn = !isLightOn;
    if (!isLightOn) {
        
        [_session beginConfiguration];
        [_device lockForConfiguration:nil];
        if (_device.torchMode == AVCaptureTorchModeOn) {
            [_device setTorchMode:AVCaptureTorchModeOff];
            [_device setFlashMode:AVCaptureFlashModeOff];
        }
        [_device unlockForConfiguration];
        [_session commitConfiguration];
        
    } else {
        
        if ([_device hasTorch] && [_device hasFlash]) {
            [_session beginConfiguration];
            [_device lockForConfiguration:nil];
            [_device setTorchMode:AVCaptureTorchModeOn];
            [_device setFlashMode:AVCaptureFlashModeOn];
            [_device unlockForConfiguration];
            [_session commitConfiguration];
        }
    }
}

// 关灯
- (void)turnOffLight
{
    isLightOn = NO;
    
    [_session beginConfiguration];
    [_device lockForConfiguration:nil];
    if (_device.torchMode == AVCaptureTorchModeOn) {
        [_device setTorchMode:AVCaptureTorchModeOff];
        [_device setFlashMode:AVCaptureFlashModeOff];
    }
    [_device unlockForConfiguration];
    [_session commitConfiguration];
    
}
#pragma mark - 扫描动画
// 开始扫描动画
- (void)startScan
{
    if (scanTimer != nil) {
        [scanTimer invalidate];
    }
    scanTimer = [NSTimer timerWithTimeInterval:0.02f target:self selector:@selector(scanAnimation) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:scanTimer forMode:NSRunLoopCommonModes];
}

// 停止动画
- (void)stopScan
{
    [scanTimer invalidate];
    scanTimer = nil;
}

// 扫描动画
-(void)scanAnimation
{
    if (!isScanUp) {
        scanline.center = CGPointMake(scanline.center.x, scanline.center.y + 2);
        if (scanline.center.y >= (scanLineStartCY + SCAN_BOX_SIZE - 20)) {
            isScanUp = YES;
        }
    } else {
        scanline.center = CGPointMake(scanline.center.x, scanline.center.y - 2);
        if (scanline.center.y <= scanLineStartCY) {
            isScanUp = NO;
        }
    }
}

- (void)stopReading
{
    [_session stopRunning];
//    _session = nil;
    
    for(AVCaptureInput *input in _session.inputs) {
        [_session removeInput:input];
    }
    
    for(AVCaptureOutput *output in _session.outputs) {
        [_session removeOutput:output];
    }
    
    [_preview removeFromSuperlayer];
}

- (void)showFailView
{
    [self setupQRCodeFailView];
    if (!_contentView.hidden) {
        _contentView.hidden = YES;
        _failView.hidden = NO;
        _isRead = YES;
    }
}


#pragma mark - 扫描结果处理
- (void)handleScanResult:(NSString *)stringValue
{
    [[[UIAlertView alloc] initWithTitle:stringValue message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];
}

#pragma mark - imagePickerControllerDelegate

// 取消选取图片
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (picker) {
        [picker dismissViewControllerAnimated:YES completion:^{
            picker.delegate = nil;
            [picker removeFromParentViewController];
        }];
    }
}

// 选中了一张图
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //1.获取选择的图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //2.初始化一个监测器
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyLow }];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [picker removeFromParentViewController];
        //监测到的结果数组
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        if (features.count >=1) {
            /**结果对象 */
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            NSString *scannedResult = feature.messageString;
            [self handleScanResult:scannedResult];
        }
        else{
            UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"该图片没有包含一个二维码！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
// 扫描结果输出
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (!_isRead) {
        if (metadataObjects && [metadataObjects count] >0)
        {
            AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
            if ([[metadataObject type] isEqualToString:AVMetadataObjectTypeQRCode]) {
                
                NSString* result = metadataObject.stringValue;
                
                [self handleScanResult:result];
                _isRead = YES;
            }
        }
    }
}

@end
