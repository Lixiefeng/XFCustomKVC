//
//  XFPerson.m
//  XFCustomKVC_Example
//
//  Created by Aron.li on 2020/10/29.
//  Copyright © 2020 Aron1987@126.com. All rights reserved.
//

#import "XFPerson.h"

@interface XFPerson ()

@property (nonatomic, copy) NSArray *extArray;

@end

@implementation XFPerson

- (instancetype)init {
    if (self  = [super init]) {
        self.extArray = @[@"1", @"2", @"3"];
    }
    return self;
}

//- (NSUInteger)countOfArrayHobbies { // 必须实现
//  NSLog(@"%s", __func__);
//  return self.extArray.count;
//}
//
//// 下面两个方法，实现其中一个
//- (id)objectInArrayHobbiesAtIndex:(NSNumber *)index { // 优先调用
//  NSLog(@"%s", __func__);
//  return self.extArray[index.integerValue];
//}

//- (NSUInteger)countOfSetProperties {
//    NSLog(@"%s", __func__);
//    return self.extArray.count;
//}
//
//- (NSEnumerator *)enumeratorOfSetProperties {
//    NSLog(@"%s", __func__);
//    return self.extArray.objectEnumerator;
//}
//
//- (id)memberOfSetProperties:(id)object {
//    NSLog(@"%s", __func__);
//    return self.extArray;
//}

@end
