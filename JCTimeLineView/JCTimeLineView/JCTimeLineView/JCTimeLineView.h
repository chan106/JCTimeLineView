//
//  JCTimeLineView.h
//  CloudPlay
//
//  Created by Chan on 2019/8/2.
//  Copyright © 2019 JOVISION. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JCTimeLineView;

NS_ASSUME_NONNULL_BEGIN

@protocol JCTimeLineDelegate <NSObject>

/**
 滚动时间轴回调

 @param timeLineView timeLineView
 @param time 时间 xx:xx:xx
 @param secValue 时间：秒，相对于00：00：00分的秒数
 */
- (void)timeLine:(JCTimeLineView *) timeLineView
    scrollToTime:(NSString *) time
    timeSecValue:(NSInteger) secValue;

@end

@interface JCTimeLineView : UIView

@property (nonatomic, weak) id <JCTimeLineDelegate> delegate;

/** 时间轴底部直线颜色，默认为 grayColor */
@property (nonatomic, strong) UIColor *timeLineBottomColor;
/** 时间轴刻度直线颜色，默认为 grayColor */
@property (nonatomic, strong) UIColor *timeLineDrawColor;
/** 时间轴指针直线颜色，默认为 redColor */
@property (nonatomic, strong) UIColor *timeLineMarkColor;
/** 时间轴刻度文字颜色，默认为 grayColor */
@property (nonatomic, strong) UIColor *timeLineTextColor;
/** 时间轴刻度文字字体，默认为 系统10号 */
@property (nonatomic, strong) UIFont  *timeLineTextFont;
/** 时间轴刻度文字富文本，默认为 上述字体和颜色 */
@property (nonatomic, strong) NSDictionary *timeLineTextAttributes;

/**
 需要绘制的已有的时间
 时间格式要求是xx:xx-xx:xx
 起点时间-终点时间
 */
@property (nonatomic, strong) NSArray <NSString *> *timePaintingArray;
/** 需要渲染的时间，默认为 orangeColor */
@property (nonatomic, strong) UIColor *timePaintingColor;

/**
 调节时间轴缩放大小

 @param scale 0 ~ 1之间
 */
- (void)adjustTimeLineScale:(CGFloat) scale;

@end

NS_ASSUME_NONNULL_END
