//
//  NSObject+XFKVC.h
//  XFCustomKVC
//
//  Created by Aron.li on 2020/10/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (XFKVC)

- (void)xf_setValue:(nullable id)value forKey:(NSString *)key;

- (nullable id)xf_valueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
