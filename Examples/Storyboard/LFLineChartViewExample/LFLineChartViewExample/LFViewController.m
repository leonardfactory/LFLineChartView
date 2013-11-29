//
//  LFViewController.m
//  LFLineChartViewExample
//
//  Created by Leonardo on 29/11/13.
//  Copyright (c) 2013 LeonardFactory. All rights reserved.
//

#import "LFViewController.h"

// Importing our custom LineChartView
#import "LFExampleLineChartView.h"

@interface LFViewController ()

@end

@implementation LFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    LFExampleLineChartView *lineChartView = [[LFExampleLineChartView alloc] initWithFrame:self.view.frame andItems:@[@1.4,@2.1,@2.3,@2.5,@0.8,@0.9,@1.5]];
    [self.view addSubview:lineChartView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
