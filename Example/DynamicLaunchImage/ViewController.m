//
//  NOViewController.m
//  DynamicLaunchImage
//
//  Created by seth on 08/27/2020.
//  Copyright (c) 2020 seth. All rights reserved.
//

#import "ViewController.h"
#import "LaunchImageHelper.h"

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    BOOL _autoExit;
    UILabel *_infoLabel;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _autoExit = YES;
#ifdef DEBUG
    // 仅用于测试，观察启动图
    sleep(1.5);
#endif
}

- (IBAction)markToAutoExit:(UIButton *)sender {
    _autoExit = !_autoExit;
    sender.selected = _autoExit;
}

// 打开相册
- (IBAction)useImageFromPhotoAlbum:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

// 从DynamicLaunchScreen截图替换
- (IBAction)useSnapshotFromDynamicSB:(id)sender {
    UIImage *portraitImage = [LaunchImageHelper snapshotStoryboardForPortrait:@"DynamicLaunchScreen"];
    UIImage *landscapeImage = [LaunchImageHelper snapshotStoryboardForLandscape:@"DynamicLaunchScreen"];
    [LaunchImageHelper changePortraitLaunchImage:portraitImage landscapeLaunchImage:landscapeImage];
    [self exitIfNeeded];
}

// 恢复为初始LaunchScreen
- (IBAction)backToNormal:(id)sender {
    UIImage *portraitImage = [LaunchImageHelper snapshotStoryboardForPortrait:@"LaunchScreen"];
    UIImage *landscapeImage = [LaunchImageHelper snapshotStoryboardForLandscape:@"LaunchScreen"];
    [LaunchImageHelper changePortraitLaunchImage:portraitImage landscapeLaunchImage:landscapeImage];
    [self exitIfNeeded];
}

- (void)showInfo:(NSString *)info {
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
        _infoLabel.center = self.view.center;
        _infoLabel.textAlignment = 1;
        _infoLabel.backgroundColor = [UIColor blackColor];
        _infoLabel.textColor = [UIColor whiteColor];
        _infoLabel.layer.cornerRadius = 5.0;
        _infoLabel.layer.masksToBounds = YES;
        [self.view addSubview:_infoLabel];
    }
    _infoLabel.text = info;
    _infoLabel.hidden = NO;
}

- (void)exitIfNeeded {
    if (_autoExit) {
        self.view.userInteractionEnabled = NO;
        [self showInfo:@"即将自动退出..."];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exit(0);
        });
    } else {
        [self showInfo:@"替换完成，请重启应用"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _infoLabel.hidden = YES;
        });
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *selectedImage = info[UIImagePickerControllerOriginalImage];
    [LaunchImageHelper changePortraitLaunchImage:selectedImage landscapeLaunchImage:selectedImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        [self exitIfNeeded];
    }];
}

@end
