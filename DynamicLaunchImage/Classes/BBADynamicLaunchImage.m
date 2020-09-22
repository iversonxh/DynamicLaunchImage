//
//  BBADynamicLaunchImage.m
//  LaunchScreen
//
//  Created by seth on 2020/8/25.
//  Copyright © 2020 seth. All rights reserved.
//

#import "BBADynamicLaunchImage.h"

@implementation BBADynamicLaunchImage

/// 系统启动图缓存路径
+ (NSString *)launchImageCacheDirectory {

    NSString *bundleID = [NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"];
    NSFileManager *fm = [NSFileManager defaultManager];

    // iOS13之前
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *snapshotsPath = [[cachesDirectory stringByAppendingPathComponent:@"Snapshots"] stringByAppendingPathComponent:bundleID];
    if ([fm fileExistsAtPath:snapshotsPath]) {
        return snapshotsPath;
    }
    
    // iOS13
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    snapshotsPath = [NSString stringWithFormat:@"%@/SplashBoard/Snapshots/%@ - {DEFAULT GROUP}", libraryDirectory, bundleID];
    if ([fm fileExistsAtPath:snapshotsPath]) {
        return snapshotsPath;
    }
    
    return nil;
}

/// 系统缓存启动图后缀名
+ (BOOL)isSnapShotName:(NSString *)name {
    // 新系统后缀
    NSString *snapshotSuffixs = @".ktx";
    if ([name hasSuffix:snapshotSuffixs]) {
        return YES;
    }
    // 老系统后缀
    snapshotSuffixs = @".png";
    if ([name hasSuffix:snapshotSuffixs]) {
        return YES;
    }
    return NO;
}

/// 替换启动图
+ (BOOL)replaceLaunchImage:(UIImage *)replacementImage {
    return [self replaceLaunchImage:replacementImage compressionQuality:0.8 customValidation:nil];
}

/// 替换启动图
+ (BOOL)replaceLaunchImage:(UIImage *)replacementImage compressionQuality:(CGFloat)quality {
    return [self replaceLaunchImage:replacementImage compressionQuality:quality customValidation:nil];
}

/// 替换启动图
+ (BOOL)replaceLaunchImage:(UIImage *)replacementImage
        compressionQuality:(CGFloat)quality
          customValidation:(BBACustomValicationBlock)validationBlock {
    if (!replacementImage) return NO;
    
    // 转为jpeg
    NSData *data = UIImageJPEGRepresentation(replacementImage, quality);
    if (!data) return NO;
    
    // 检查图片尺寸是否等同屏幕分辨率
    if (![self checkImageMatchScreenSize:replacementImage]) {
        return NO;
    }
    
    // 获取系统缓存启动图路径
    NSString *cacheDir = [self launchImageCacheDirectory];
    if (!cacheDir) return NO;
    
    // 工作目录
    NSString *cachesParentDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *tmpDir = [cachesParentDir stringByAppendingPathComponent:@"_tmpLaunchImageCaches"];
    
    // 清理工作目录
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:tmpDir]) {
        [fm removeItemAtPath:tmpDir error:nil];
    }
    
    // 移动系统缓存目录内容至工作目录
    BOOL moveResult = [fm moveItemAtPath:cacheDir toPath:tmpDir error:nil];
    if (!moveResult) return NO;

    // 操作工作目录
    // 记录需要操作的图片名
    NSMutableArray *cacheImageNames = [NSMutableArray array];
    for (NSString *name in [fm contentsOfDirectoryAtPath:tmpDir error:nil]) {
        if ([self isSnapShotName:name]) {
            [cacheImageNames addObject:name];
        }
    }
    
    // 写入替换图片
    for (NSString *name in cacheImageNames) {
        NSString *filePath = [tmpDir stringByAppendingPathComponent:name];
        // 自定义校验
        BOOL result = YES;
        if (validationBlock) {
            NSData *cachedImageData = [NSData dataWithContentsOfFile:filePath];
            UIImage *cachedImage = [self imageFromData:cachedImageData];
            if (cachedImage) {
                result = validationBlock(cachedImage, replacementImage);
            }
        }
        if (result) {
            [data writeToFile:filePath atomically:YES];
        }
    }

    // 还原系统缓存目录
    moveResult = [fm moveItemAtPath:tmpDir toPath:cacheDir error:nil];

    // 清理工作目录
    if ([fm fileExistsAtPath:tmpDir]) {
        [fm removeItemAtPath:tmpDir error:nil];
    }
    
    return YES;
}

/// 获取image对象
+ (UIImage *)imageFromData:(NSData *)data {
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (source) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        if (imageRef) {
            UIImage *originImage = [UIImage imageWithCGImage:imageRef];
            CFRelease(imageRef);
            CFRelease(source);
            return originImage;
        }
    }
    return nil;
}

/// 获取图片大小
+ (CGSize)getImageSize:(NSData *)imageData {
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    if (imageRef) {
        CGFloat width = CGImageGetWidth(imageRef);
        CGFloat height = CGImageGetHeight(imageRef);
        CFRelease(imageRef);
        CFRelease(source);
        return CGSizeMake(width, height);
    }
    return CGSizeZero;
}

/// 检查图片大小
+ (BOOL)checkImageMatchScreenSize:(UIImage *)image {
    CGSize screenSize = CGSizeApplyAffineTransform([UIScreen mainScreen].bounds.size,
                                                   CGAffineTransformMakeScale([UIScreen mainScreen].scale,
                                                                              [UIScreen mainScreen].scale));
    CGSize imageSize = CGSizeApplyAffineTransform(image.size,
                                                  CGAffineTransformMakeScale(image.scale, image.scale));
    if (CGSizeEqualToSize(imageSize, screenSize)) {
        return YES;
    }
    if (CGSizeEqualToSize(CGSizeMake(imageSize.height, imageSize.width), screenSize)) {
        return YES;
    }
    return NO;
}

@end
