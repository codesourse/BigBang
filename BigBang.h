//
//  BigBang.h
//
//  Created by jsb-xiakj on 2017/5/18.
//  Copyright © 2017年 xaikejie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
@interface BigBang : NSObject
+(void)hookClass:(NSString*)hookString;
@end
