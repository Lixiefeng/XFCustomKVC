//
//  NSObject+XFKVC.m
//  XFCustomKVC
//
//  Created by Aron.li on 2020/10/28.
//

#import "NSObject+XFKVC.h"
#import <objc/runtime.h>

@implementation NSObject (XFKVC)

- (void)xf_setValue:(nullable id)value forKey:(NSString *)key {
    if (key == nil || key.length == 0) {
        return;
    }
    // 1. 先依次查询有没有相关的方法：set<Key>:、_set<Key>:、setIs<Key>
    // 注意：key的首字母要大写
    NSString *Key = [NSString stringWithFormat:@"%@%@", [key substringToIndex:1].uppercaseString, [key substringFromIndex:1]];
    NSString *setKey = [NSString stringWithFormat:@"set%@", Key];
    NSString *_setKey = [NSString stringWithFormat:@"_set%@", key];
    NSString *setIsKey = [NSString stringWithFormat:@"setIs%@", key];
    // 调用方法
    if ([self xf_performSelectorWithMethodName:setKey value:value]) {
        return;
    } else if ([self xf_performSelectorWithMethodName:_setKey value:value]) {
        return;
    } else if ([self xf_performSelectorWithMethodName:setIsKey value:value]) {
        return;
    }
    
    // 2. 查看类方法accessInstanceVariablesDirectly是否为YES，如果为NO-->抛出异常
    if (![self.class accessInstanceVariablesDirectly]) {
        @throw [NSException exceptionWithName:@"LGUnknownKeyException" reason:[NSString stringWithFormat:@"****[%@ valueForUndefinedKey:]: this class is not key value coding-compliant for the key name.****", self] userInfo:nil];
    }
    
    // 3.为YES时，可以直接访问成员变量的来进行赋值，依次寻找变量 _<key>、 _is<Key>、 <key>、 is<Key>。
    // 找到则直接赋值，否则进入下一步。
    // 注意：key首字母的大小写
    NSString *_key = [NSString stringWithFormat:@"_%@", key];
    NSString *_isKey = [NSString stringWithFormat:@"_is%@",Key];
    NSString *isKey = [NSString stringWithFormat:@"is%@", Key];
    // 获取当前类中的成员变量 class_copyIvarList
    NSMutableArray *ivarList = [self xf_getIVarListName];
    if ([ivarList containsObject:_key]) {
        // 4.2 获取相应的 ivar
       Ivar ivar = class_getInstanceVariable([self class], _key.UTF8String);
        // 4.3 对相应的 ivar 设置值
       object_setIvar(self , ivar, value);
       return;
    }else if ([ivarList containsObject:_isKey]) {
       Ivar ivar = class_getInstanceVariable([self class], _isKey.UTF8String);
       object_setIvar(self , ivar, value);
       return;
    }else if ([ivarList containsObject:key]) {
       Ivar ivar = class_getInstanceVariable([self class], key.UTF8String);
       object_setIvar(self , ivar, value);
       return;
    }else if ([ivarList containsObject:isKey]) {
       Ivar ivar = class_getInstanceVariable([self class], isKey.UTF8String);
       object_setIvar(self , ivar, value);
       return;
    }
    
    // 仍然找不到，则抛异常
    @throw [NSException exceptionWithName:@"LGUnknownKeyException" reason:[NSString stringWithFormat:@"****[%@ %@]: this class is not key value coding-compliant for the key name.****",self,NSStringFromSelector(_cmd)] userInfo:nil];
}

- (nullable id)xf_valueForKey:(NSString *)key {
    if (key == nil  || key.length == 0) {
        return nil;
    }
    // 1. 以 get<Key>, <key>, is<Key> 以及 _<key> 的顺序查找对象中是否有对应的方法。
    NSString *Key = [NSString stringWithFormat:@"%@%@", [key substringToIndex:1].uppercaseString, [key substringFromIndex:1]];
    NSString *getKey = [NSString stringWithFormat:@"get%@",Key];
    NSString *isKey = [NSString stringWithFormat:@"is%@", Key];
    NSString *_key = [NSString stringWithFormat:@"%@", key];
    NSString *_isKey = [NSString stringWithFormat:@"_is%@",Key];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self respondsToSelector:NSSelectorFromString(getKey)]) {
        id value = [self performSelector:NSSelectorFromString(getKey)];
        return [self xf_validateValue:value];
    }else if ([self respondsToSelector:NSSelectorFromString(key)]) {
        id value = [self performSelector:NSSelectorFromString(key)];
        return [self xf_validateValue:value];
    }else if ([self respondsToSelector:NSSelectorFromString(isKey)]) {
        id value = [self performSelector:NSSelectorFromString(isKey)];
        return [self xf_validateValue:value];
    }else if ([self respondsToSelector:NSSelectorFromString(_key)]) {
        id value = [self performSelector:NSSelectorFromString(_key)];
        return [self xf_validateValue:value];
    }
    
    // 2. 查找是否有 countOf<Key> 和 objectIn<Key>AtIndex: 方法
    NSString *countOfKey = [NSString stringWithFormat:@"countOf%@",Key];
    NSString *objectInKeyAtIndex = [NSString stringWithFormat:@"objectIn%@AtIndex:",Key];
    
    if ([self respondsToSelector:NSSelectorFromString(countOfKey)]) {
        if ([self respondsToSelector:NSSelectorFromString(objectInKeyAtIndex)]) {
            int number = (int)[self performSelector:NSSelectorFromString(countOfKey)];
            NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:1];
            for (int i = 0; i < number; i++) {
                id objc = [self performSelector:NSSelectorFromString(objectInKeyAtIndex) withObject:@(i)];
                [mArray addObject:objc];
            }
            return mArray;
        }
    }
    
    // 3. 查找名为 countOf<Key>，enumeratorOf<Key> 和 memberOf<Key> 这三个方法
    NSString *enumeratorOfKey = [NSString stringWithFormat:@"enumeratorOf%@", Key];
    NSString *memberOfKey = [NSString stringWithFormat:@"memberOf%@:", Key];
    if ([self respondsToSelector:NSSelectorFromString(countOfKey)]) {
        if ([self respondsToSelector:NSSelectorFromString(enumeratorOfKey)]) {
            NSEnumerator *enumrator = [self performSelector:NSSelectorFromString(enumeratorOfKey)];
            NSMutableArray *mArray = [NSMutableArray array];
            id value;
            while ((value = [enumrator nextObject]) != nil) {
                id validateValue = [self xf_validateValue:value];
                [mArray addObject:validateValue];
            }
            return mArray;
        }
        if ([self respondsToSelector:NSSelectorFromString(memberOfKey)]) {
            id member = [self performSelector:NSSelectorFromString(memberOfKey) withObject:Key];
            return [self xf_validateValue:member];
        }
    }
#pragma clang diagnostic pop
    
    // 4. 判断类方法 accessInstanceVariablesDirectly 结果
    if (![self.class accessInstanceVariablesDirectly] ) {
        @throw [NSException exceptionWithName:@"LGUnknownKeyException" reason:[NSString stringWithFormat:@"****[%@ valueForUndefinedKey:]: this class is not key value coding-compliant for the key name.****",self] userInfo:nil];
    }
    
    // 5.找相关实例变量进行赋值
    // 5.1 定义一个收集实例变量的可变数组
    NSMutableArray *mArray = [self xf_getIvarListName];
    // _<key> _is<Key> <key> is<Key>
    // _name -> _isName -> name -> isName
    if ([mArray containsObject:_key]) {
        Ivar ivar = class_getInstanceVariable([self class], _key.UTF8String);
        return object_getIvar(self, ivar);;
    }else if ([mArray containsObject:_isKey]) {
        Ivar ivar = class_getInstanceVariable([self class], _isKey.UTF8String);
        return object_getIvar(self, ivar);;
    }else if ([mArray containsObject:key]) {
        Ivar ivar = class_getInstanceVariable([self class], key.UTF8String);
        return object_getIvar(self, ivar);;
    }else if ([mArray containsObject:isKey]) {
        Ivar ivar = class_getInstanceVariable([self class], isKey.UTF8String);
        return object_getIvar(self, ivar);;
    }

    return @"";
}

#pragma mark - private methods

- (BOOL)xf_performSelectorWithMethodName:(NSString *)methodName value:(id)value {
    SEL methodSel = NSSelectorFromString(methodName);
    if ([self respondsToSelector:methodSel]) {
        // Warnning: PerformSelector may cause a leak because its selector is unknown
        // 可参考 https://www.jianshu.com/p/6517ab655be7

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:methodSel withObject:value];
#pragma clang diagnostic pop
        
        return YES;
    }
    return NO;
}

- (NSMutableArray *)xf_getIVarListName {
    NSMutableArray *list = [NSMutableArray array];
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([self class], &count);
    for (int i = 0; i< count; i++) {
        Ivar ivar = ivars[i];
        // 获取成员变量名称
        const char *ivarNameChar = ivar_getName(ivar);
        NSString *ivarName = [NSString stringWithUTF8String:ivarNameChar];
        [list addObject:ivarName];
    }
    // 记得释放
    free(ivars);
    return list;
}

- (id)xf_validateValue:(id)value {
    if ([value isKindOfClass:[NSObject class]]) {
        return value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)value;
        return number;
    } else {
        NSValue *valueObj = (NSValue *)value;
        return valueObj;
    }
}

- (NSMutableArray *)xf_getIvarListName {
    NSMutableArray *array = [NSMutableArray array];
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([self class], &count);
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        const char *cName = ivar_getName(ivar);
        NSString *varName = [NSString stringWithUTF8String:cName];
        [array addObject:varName];
    }
    free(ivars);
    return array;
}



@end
