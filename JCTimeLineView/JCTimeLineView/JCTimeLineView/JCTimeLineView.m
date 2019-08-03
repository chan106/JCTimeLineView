//
//  JCTimeLineView.m
//  CloudPlay
//
//  Created by Chan on 2019/8/2.
//  Copyright © 2019 JOVISION. All rights reserved.
//

#import "JCTimeLineView.h"

/**
 时间轴最小刻度单位

 - JCTimeLineWidthType10Min: 10分钟
 - JCTimeLineWidthType5Min:  5分钟
 - JCTimeLineWidthType2Min:  2分钟
 - JCTimeLineWidthType1Min:  1分钟
 - JCTimeLineWidthType30Sec: 30秒
 - JCTimeLineWidthType15Sec: 15秒
 */
typedef NS_ENUM(NSInteger, JCTimeLineWidthType) {
    JCTimeLineWidthType10Min     = 6,
    JCTimeLineWidthType5Min      = 12,
    JCTimeLineWidthType2Min      = 30,
    JCTimeLineWidthType1Min      = 60,
    JCTimeLineWidthType30Sec     = 120,
    JCTimeLineWidthType15Sec     = 240
};

#define kJCTimeLineMaxHour          24
#define kJCTimeLineBottomSpace      20

@interface JCTimeLineView ()<UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *contentView;
@property (nonatomic, strong) UIView *centerLine;

@property (nonatomic, strong) NSMutableArray <CALayer *> *timeLineLayerArray;
@property (nonatomic, strong) NSMutableArray <CATextLayer *> *timeLineTextLayerArray;
@property (nonatomic, strong) NSMutableArray <NSString *> *timeLineTextArray;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *timeLineTextWidthArray;
@property (nonatomic, assign) JCTimeLineWidthType widthType;
@property (nonatomic, assign) CGFloat startX;
@property (nonatomic, assign) CGFloat contentViewWidth;
@property (nonatomic, assign) NSInteger itemCount;
@property (nonatomic, assign) NSInteger halfHourCount;
@property (nonatomic, assign) NSInteger minTimeCount;
@property (nonatomic, assign) NSInteger showCount;
@property (nonatomic, assign) NSInteger secUnit;

@property (nonatomic, strong) NSMutableArray <CALayer *> *timePaintingLayerArray;
@property (nonatomic, assign) NSInteger currentSec;
@property (nonatomic, assign) BOOL isNeedScrollData;
@property (nonatomic, strong) UILabel *timeLabel;

@end

@implementation JCTimeLineView

#pragma mark Public Api
/**
 调节时间轴缩放大小
 
 @param scale 0 ~ 1之间
 */
- (void)adjustTimeLineScale:(CGFloat)scale{
    //真实区间是 1 ~ 200
    scale *= 200;
    if (scale <= 1) {
        scale = 1;
    }else if (scale >= 200){
        scale = 200;
    }
    NSLog(@"%f",scale);
    self.scrollView.scrollEnabled = NO;
    UIView *view = self.contentView;
    //扩大、缩小倍数
    CGRect frame = view.frame;
    frame.size.width = scale * self.width * 0.5;
    if (frame.size.width <= 2*self.width) {
        frame.size.width = 2*self.width;
    }else if (frame.size.width >= 200*self.width){
        frame.size.width = 200*self.width;
    }
    view.frame = frame;
    self.scrollView.contentSize = frame.size;
    self.contentViewWidth = frame.size.width;
    [self reloadTimeLine];
    self.scrollView.scrollEnabled = YES;
}

#pragma mark DrawRect
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentView];
    [self addSubview:self.centerLine];
    [self addSubview:self.timeLabel];
    [self reloadTimeLine];
}

#pragma mark ReloadTimeLineView
- (void)reloadTimeLine{
    
    JCTimeLineWidthType widthType;
    BOOL isChangeWidthType = NO;
    
    if (self.contentViewWidth < self.width*4) {
        //每10分钟1格
        widthType = JCTimeLineWidthType10Min;
    }else if (self.contentViewWidth >= self.width * 4 &&
              self.contentViewWidth < self.width * 8){
        //每5分钟一格
        widthType = JCTimeLineWidthType5Min;
    }else if (self.contentViewWidth >= self.width * 8 &&
              self.contentViewWidth < self.width * 18){
        //每2分钟一格
        widthType = JCTimeLineWidthType2Min;
    }else if (self.contentViewWidth >= self.width * 18 &&
              self.contentViewWidth < self.width * 30){
        //每1分钟一格
        widthType = JCTimeLineWidthType1Min;
    }else if (self.contentViewWidth >= self.width * 30 &&
              self.contentViewWidth < self.width * 150){
        //每30秒一格
        widthType = JCTimeLineWidthType30Sec;
    }else{
        //每15秒一格
        widthType = JCTimeLineWidthType15Sec;
    }
    
    if (self.widthType != widthType) {
        isChangeWidthType = YES;
        self.itemCount = kJCTimeLineMaxHour * widthType;
        self.widthType = widthType;
    }
    
    if (self.timeLineLayerArray == nil) {
        self.timeLineLayerArray = [NSMutableArray array];
        self.timeLineTextLayerArray = [NSMutableArray array];
        self.timeLineTextArray = [NSMutableArray array];
        self.timeLineTextWidthArray = [NSMutableArray array];
        self.startX = 0.5 * self.width - 0.5;
        self.itemCount = kJCTimeLineMaxHour * widthType;
        self.showCount = 18;
        self.secUnit = 600;
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:!isChangeWidthType];
    //计算最小刻度宽
    CGFloat itemWidth = (self.contentViewWidth - self.width) / self.itemCount;
    //如果改变了刻度模式，移除所有刻度及文字
    if (isChangeWidthType == YES) {
        for (CALayer *layer in self.timeLineLayerArray) {
            [layer removeFromSuperlayer];
        }
        for (CATextLayer *layer in self.timeLineTextLayerArray) {
            [layer removeFromSuperlayer];
        }
        [self.timeLineLayerArray removeAllObjects];
        [self.timeLineTextLayerArray removeAllObjects];
        [self.timeLineTextArray removeAllObjects];
        [self.timeLineTextWidthArray removeAllObjects];
        //重新计算时间X轴数据
        if (widthType == JCTimeLineWidthType10Min) {
            self.showCount = 18;
            self.secUnit = 600;
            self.secUnit = 600;
        }else if (widthType == JCTimeLineWidthType5Min){
            self.showCount = 12;
            self.secUnit = 300;
        }else if (widthType == JCTimeLineWidthType2Min){
            self.showCount = 15;
            self.secUnit = 120;
        }else if (widthType == JCTimeLineWidthType1Min){
            self.showCount = 15;
            self.secUnit = 60;
        }else if (widthType == JCTimeLineWidthType30Sec){
            self.showCount = 10;
            self.secUnit = 30;
        }else if (widthType == JCTimeLineWidthType15Sec){
            self.showCount = 8;
            self.secUnit = 15;
        }
    }
    
    NSInteger textLayerIndex = 0;
    for (NSInteger i = 0; i < (self.itemCount+1); i++) {
        CALayer *lineLayer;
        if (isChangeWidthType == YES) {
            lineLayer = [CALayer layer];
            lineLayer.backgroundColor = [self.timeLineDrawColor CGColor];
            [self.contentView.layer addSublayer:lineLayer];
            [self.timeLineLayerArray addObject:lineLayer];
        }else{
            lineLayer = self.timeLineLayerArray[i];
        }
        
        CGFloat height = 10;
        if (i % widthType == 0) {
            height = 25;//时刻度
        }else if (i % (widthType/2) == 0){
            height = 15;//中等刻度
        }else{
            height = 10;//最小刻度
        }
        lineLayer.frame = CGRectMake(self.startX + itemWidth * i,
                                     self.height - kJCTimeLineBottomSpace - height,
                                     1,
                                     height);
        
        //绘制时间文字
        NSInteger sec = i * self.secUnit;
        if (i % self.showCount == 0) {
            CATextLayer *textLayer;
            NSInteger stringWidth = 0;
            if (isChangeWidthType == YES) {
                NSString *string = [NSString stringWithFormat:@"%02ld:%02ld",(sec/3600),(sec%3600/60)];
                CGSize stringSize = [string boundingRectWithSize:CGSizeMake(30, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin) attributes:self.timeLineTextAttributes context:nil].size;
                [self.timeLineTextArray addObject:string];
                [self.timeLineTextWidthArray addObject:[NSNumber numberWithInteger:stringSize.width]];
                stringWidth = stringSize.width;
                textLayer = [[CATextLayer alloc] init];
                textLayer.string = [[NSAttributedString alloc] initWithString:string
                                                                   attributes:self.timeLineTextAttributes];
                textLayer.contentsScale = [UIScreen mainScreen].scale;//寄宿图的像素尺寸和视图大小的比例,不设置为屏幕比例文字就会像素化
                [self.contentView.layer addSublayer:textLayer];
                [self.timeLineTextLayerArray addObject:textLayer];
            }else{
                textLayer = self.timeLineTextLayerArray[textLayerIndex];
                stringWidth = self.timeLineTextWidthArray[textLayerIndex].integerValue;
                textLayerIndex++;
            }
            textLayer.frame = CGRectMake((self.startX + itemWidth * i) - (stringWidth * 0.5),
                                         self.height - kJCTimeLineBottomSpace,
                                         stringWidth,
                                         kJCTimeLineBottomSpace);
        }
    }
    [CATransaction commit];
    
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    //绘制已有时间区
    if (self.timePaintingLayerArray == nil) {
        self.timePaintingLayerArray = [NSMutableArray array];
    }
    for (NSInteger i = 0; i < self.timePaintingArray.count; i++) {
        NSString *timeRange = self.timePaintingArray[i];
        NSString *startTime = [timeRange componentsSeparatedByString:@"-"].firstObject;
        NSString *endTime = [timeRange componentsSeparatedByString:@"-"].lastObject;
        //将时间转成对应的坐标点
        NSInteger startHourSec = [startTime componentsSeparatedByString:@":"][0].integerValue * 3600;
        NSInteger startMinSec = [startTime componentsSeparatedByString:@":"][1].integerValue * 60;
        NSInteger startSec = [startTime componentsSeparatedByString:@":"][2].integerValue;
        startSec = startHourSec + startMinSec + startSec;
        
        NSInteger endHourSec = [endTime componentsSeparatedByString:@":"][0].integerValue * 3600;
        NSInteger endMinSec = [endTime componentsSeparatedByString:@":"][1].integerValue * 60;
        NSInteger endSec = [endTime componentsSeparatedByString:@":"][2].integerValue;
        endSec = endHourSec + endMinSec + endSec;
        
        CALayer *timelayer;
        if (self.timePaintingLayerArray.count != self.timePaintingArray.count) {
            timelayer = [[CALayer alloc] init];
            timelayer.backgroundColor = [self.timePaintingColor CGColor];
            [self.contentView.layer addSublayer:timelayer];
            [self.timePaintingLayerArray addObject:timelayer];
        }else{
            timelayer = self.timePaintingLayerArray[i];
        }
        timelayer.frame = CGRectMake(self.startX + itemWidth * ((CGFloat)startSec / self.secUnit),
                                     0,
                                     (endSec - startSec) / (CGFloat)self.secUnit * itemWidth,
                                     2 * kJCTimeLineBottomSpace);
    }
    [CATransaction commit];
    
    //还原content
    self.scrollView.contentOffset = CGPointMake(itemWidth * ((CGFloat)self.currentSec / (CGFloat)self.secUnit), 0);
}

#pragma mark - PinchActionHandler
- (void)pinchAction:(UIPinchGestureRecognizer *) sender{
    if (sender.state == UIGestureRecognizerStateBegan ||
        sender.state == UIGestureRecognizerStateChanged){
        self.scrollView.scrollEnabled = NO;
        UIView *view = [sender view];
        //扩大、缩小倍数
        CGRect frame = view.frame;
        frame.size.width = sender.scale * frame.size.width;
        if (frame.size.width <= 2*self.width) {
            frame.size.width = 2*self.width;
        }else if (frame.size.width >= 200*self.width){
            frame.size.width = 200*self.width;
        }
        view.frame = frame;
        self.scrollView.contentSize = frame.size;
        self.contentViewWidth = frame.size.width;
        sender.scale = 1;
        [self reloadTimeLine];
        self.scrollView.scrollEnabled = YES;
    }
}

#pragma mark UIGestureRecognizerDelegate
// 允许多个手势并发
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self.isNeedScrollData) {
        self.currentSec = scrollView.contentOffset.x / (self.contentViewWidth - self.width) * 86400;
        self.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",self.currentSec/3600,self.currentSec%3600/60,self.currentSec%3600%60];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(timeLine:scrollToTime:timeSecValue:)]) {
            [self.delegate timeLine:self scrollToTime:self.timeLabel.text timeSecValue:self.currentSec];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isNeedScrollData = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    self.isNeedScrollData = decelerate;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    self.isNeedScrollData = NO;
}

#pragma mark Getter
- (UIScrollView *)scrollView{
    if (_scrollView == nil) {
        self.width = CGRectGetWidth(self.frame);
        self.height = CGRectGetHeight(self.frame);
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.contentSize = CGSizeMake(2 * self.width, self.height);
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.delegate = self;
        [self addSubview:_scrollView];
        [self addConstraints:@[[NSLayoutConstraint constraintWithItem:_scrollView
                                                            attribute:(NSLayoutAttributeLeft)
                                                            relatedBy:(NSLayoutRelationEqual)
                                                               toItem:self
                                                            attribute:(NSLayoutAttributeLeft)
                                                           multiplier:1 constant:0],
                               [NSLayoutConstraint constraintWithItem:_scrollView
                                                            attribute:(NSLayoutAttributeTop)
                                                            relatedBy:(NSLayoutRelationEqual)
                                                               toItem:self
                                                            attribute:(NSLayoutAttributeTop)
                                                           multiplier:1 constant:0],
                               [NSLayoutConstraint constraintWithItem:_scrollView
                                                            attribute:(NSLayoutAttributeRight)
                                                            relatedBy:(NSLayoutRelationEqual)
                                                               toItem:self
                                                            attribute:(NSLayoutAttributeRight)
                                                           multiplier:1 constant:0],
                               [NSLayoutConstraint constraintWithItem:_scrollView
                                                            attribute:(NSLayoutAttributeBottom)
                                                            relatedBy:(NSLayoutRelationEqual)
                                                               toItem:self
                                                            attribute:(NSLayoutAttributeBottom)
                                                           multiplier:1 constant:0]]];
    }
    return _scrollView;
}

- (UIImageView *)contentView{
    if (_contentView == nil) {
        _contentView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 2 * self.width, self.height)];
        _contentView.userInteractionEnabled = YES;
        [self.scrollView addSubview:_contentView];
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
        pinch.delegate = self;
        [_contentView addGestureRecognizer:pinch];
        CALayer *bottomLine = [[CALayer alloc] init];
        bottomLine.frame = CGRectMake(0, self.height - kJCTimeLineBottomSpace, self.width, 1);
        bottomLine.backgroundColor = self.timeLineBottomColor.CGColor;
        self.contentViewWidth = _contentView.frame.size.width;
        [self.layer addSublayer:bottomLine];
    }
    return _contentView;
}

- (UIView *)centerLine{
    if (_centerLine == nil) {
        _centerLine = [[UIView alloc] initWithFrame:CGRectZero];
        _centerLine.backgroundColor = self.timeLineMarkColor;
        _centerLine.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_centerLine];
        [self addConstraints:@[[NSLayoutConstraint constraintWithItem:_centerLine
                                                            attribute:(NSLayoutAttributeCenterX)
                                                            relatedBy:(NSLayoutRelationEqual)
                                                               toItem:self
                                                            attribute:(NSLayoutAttributeCenterX)
                                                           multiplier:1 constant:0],
                               [NSLayoutConstraint constraintWithItem:_centerLine
                                                            attribute:(NSLayoutAttributeTop)
                                                            relatedBy:(NSLayoutRelationEqual)
                                                               toItem:self
                                                            attribute:(NSLayoutAttributeTop)
                                                           multiplier:1 constant:0],
                               [NSLayoutConstraint constraintWithItem:_centerLine
                                                            attribute:(NSLayoutAttributeBottom)
                                                            relatedBy:(NSLayoutRelationEqual)
                                                               toItem:self
                                                            attribute:(NSLayoutAttributeBottom)
                                                           multiplier:1 constant:0],
                               [NSLayoutConstraint constraintWithItem:_centerLine
                                                            attribute:(NSLayoutAttributeWidth)
                                                            relatedBy:(NSLayoutRelationEqual)
                                                               toItem:nil
                                                            attribute:(NSLayoutAttributeNotAnAttribute)
                                                           multiplier:1 constant:1]]];
    }
    return _centerLine;
}

- (UILabel *)timeLabel{
    if (_timeLabel == nil) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabel.textColor = [UIColor grayColor];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:_timeLabel];
        [self addConstraints:@[[NSLayoutConstraint constraintWithItem:_timeLabel attribute:(NSLayoutAttributeCenterX) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeCenterX) multiplier:1 constant:0],
                               [NSLayoutConstraint constraintWithItem:_timeLabel attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeTop) multiplier:1 constant:0]]];
    }
    return _timeLabel;
}

#pragma mark - DefaultSetting

- (UIColor *)timeLineBottomColor{
    if (_timeLineBottomColor == nil) {
        _timeLineBottomColor = [UIColor grayColor];
    }
    return _timeLineBottomColor;
}

- (UIColor *)timeLineDrawColor{
    if (_timeLineDrawColor == nil) {
        _timeLineDrawColor = [UIColor grayColor];
    }
    return _timeLineDrawColor;
}

- (UIColor *)timeLineMarkColor{
    if (_timeLineMarkColor == nil) {
        _timeLineMarkColor = [UIColor redColor];
    }
    return _timeLineMarkColor;
}

- (UIColor *)timeLineTextColor{
    if (_timeLineTextColor == nil) {
        _timeLineTextColor = [UIColor grayColor];
    }
    return _timeLineTextColor;
}

- (UIFont *)timeLineTextFont{
    if (_timeLineTextFont == nil) {
        _timeLineTextFont = [UIFont systemFontOfSize:10];
    }
    return _timeLineTextFont;
}

- (NSDictionary *)timeLineTextAttributes{
    if (_timeLineTextAttributes == nil) {
        _timeLineTextAttributes = @{NSForegroundColorAttributeName:self.timeLineTextColor,
                                    NSFontAttributeName:self.timeLineTextFont};
    }
    return _timeLineTextAttributes;
}

- (UIColor *)timePaintingColor{
    if (_timePaintingColor == nil) {
        _timePaintingColor = [UIColor orangeColor];
    }
    return _timePaintingColor;
}

@end
