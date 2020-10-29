//
//  XFViewController.m
//  XFCustomKVC
//
//  Created by Aron1987@126.com on 10/28/2020.
//  Copyright (c) 2020 Aron1987@126.com. All rights reserved.
//

#import "XFViewController.h"
#import <NSObject+XFKVC.h>
#import "XFPerson.h"

@interface XFViewController ()

@end

@implementation XFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    XFPerson *person = [[XFPerson alloc] init];
    [person xf_setValue:@"大师班牛逼" forKey:@"name"];
    NSLog(@"=-=-person.name = %@", person.name);
    
//    person.arrayHobbies = @[@"跑步", @"网游", @"手游", @"室内锻炼"];
//    NSSet *setHobbies = [[NSSet alloc] initWithArray:person.arrayHobbies];
//    person.setProperties = setHobbies;
//    id arrValue = [person xf_valueForKey:@"arrayHobbies"];
//    NSLog(@"=-=-person.arrayHobbies = %@", arrValue);
    id setValue = [person xf_valueForKey:@"setProperties"];
    NSLog(@"=-=-person.setProperties = %@", setValue);

    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
