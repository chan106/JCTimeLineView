//
//  ViewController.m
//  JCTimeLineView
//
//  Created by Chan on 2019/8/3.
//  Copyright © 2019 JOVISION. All rights reserved.
//

#import "ViewController.h"
#import "JCTimeLineView/JCTimeLineView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet JCTimeLineView *timeLineView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //时间刻度颜色那些，可以自由设置，具体属性见 JCTimeLineView.h
    self.timeLineView.timePaintingArray = @[@"01:00:12-02:00:01",
                                            @"02:00:12-02:50:01",
                                            @"03:00:12-03:01:01",
                                            @"04:00:12-04:50:01",
                                            @"05:00:12-05:40:01",
                                            @"06:00:12-06:20:01",
                                            @"07:00:12-07:50:01",
                                            @"08:00:12-09:00:01",
                                            @"12:00:12-14:00:01",
                                            @"14:10:12-14:11:01",
                                            @"14:20:12-14:50:01",
                                            @"15:00:12-16:00:01",
                                            @"16:00:12-18:00:01",
                                            @"18:10:12-19:00:01",
                                            @"20:00:12-22:00:01",
                                            @"22:00:12-23:50:01"];
}

- (IBAction)switchAction:(UISlider *)sender {
    [self.timeLineView adjustTimeLineScale:sender.value];
}

@end
