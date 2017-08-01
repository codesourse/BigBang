//
//  BigBang.m
//  Created by jsb-xiakj on 2017/5/18.
//

#import "BigBang.h"
#define BIGBANG @"BigBang_"

#define WRAP_AND_RETURN(type) \
do { \
type val = 0; \
[invocation getArgument:&val atIndex:(NSInteger)index]; \
return @(val); \
} while (0)

#define WRAP_GET_VALUE(type) \
do { \
type val = 0; \
[invocation getReturnValue:&val]; \
return @(val); \
} while (0)

@implementation BigBang

+(void)hookClass:(NSString*)hookString
{
    Class hookClass = NSClassFromString(hookString);
    unsigned int outCount = 0;
    Method *methods = class_copyMethodList(hookClass, &outCount);
    for (int i = 0; i < outCount; i++) {
        Method method = methods[i];
        SEL methodSel = method_getName(method);
        const char *typeEncoding = method_getTypeEncoding(method);
        IMP imp = method_getImplementation(method);
        if ([BigBang isMsgForwardIMP:imp]) {
            continue;
        }
        //过滤系统的隐藏函数
        NSString *selString=NSStringFromSelector(methodSel);
        
        NSString *fuctionString =  @".cxx_destruct|dealloc|_isDeallocating|release|autorelease|retain|Retain|_tryRetain|copy|nsis_descriptionOfVariable:|respondsToSelector:|class|methodSignatureForSelector:|allowsWeakReference|etainWeakReference|init";
        
        if ([selString hasPrefix:@"."]||[fuctionString containsString:selString]) {
            continue;
        }
        NSString *hookedName = [BigBang methodLogMethodName:selString];
        // printf("%s:%s\n",[hookString UTF8String],[hookedName UTF8String]);
        class_addMethod(hookClass, NSSelectorFromString(hookedName), imp, typeEncoding);
        //将旧地址指向forward invocaton
        class_replaceMethod(hookClass, methodSel, [BigBang getMsgForwardIMP:hookClass sel:methodSel], typeEncoding);
    }
    
    IMP forwardInvocationImpl = imp_implementationWithBlock(^(id object, NSInvocation *invocation) {
        //NSLog(@"hookString=%@",hookString);
        NSString *newSelectorName = [BigBang methodLogMethodName:NSStringFromSelector(invocation.selector)];
        invocation.selector = NSSelectorFromString(newSelectorName);
        @try {
            NSString *objString=[NSString stringWithFormat:@"%@",object];
            NSUInteger number = invocation.methodSignature.numberOfArguments;
            newSelectorName=[newSelectorName stringByReplacingOccurrencesOfString:BIGBANG withString:@""];
            NSString *returnType=[NSString stringWithUTF8String:invocation.methodSignature.methodReturnType];
            returnType=[returnType stringByReplacingOccurrencesOfString:@"v" withString:@"void"];
            returnType=[returnType stringByReplacingOccurrencesOfString:@"B" withString:@"BOOL"];
            returnType=[returnType stringByReplacingOccurrencesOfString:@"q" withString:@"NSNumber"];
            returnType=[returnType stringByReplacingOccurrencesOfString:@"@" withString:@"id"];
           
            id obj =[BigBang getReturnValueInvocatein:invocation];
            NSString *retObj=[NSString stringWithFormat:@"%@",obj];
            NSMutableString *muString=[[NSMutableString alloc] init];
            for (long i=2; i<number; i++) {
 
                NSObject *ret = [BigBang argumentAtIndex:i withInvocatein:invocation];
                NSString *classString = NSStringFromClass(ret.class);
                [muString appendFormat:@"\nvalue%ld:%@-->%@",i-1,classString,ret];
            }
            
            printf("-(%s)%s(have %ld value)\nreturn:%s%s\nobject:%s\n ##########################################\n",[returnType UTF8String],[newSelectorName UTF8String],number-2,[retObj UTF8String],[muString UTF8String],[objString UTF8String]);
        } @catch (NSException *exception) {
            NSLog(@"%@",[exception description]);
        } @finally {
            
        }

        [invocation invoke];
    });
    class_addMethod(hookClass, @selector(forwardInvocation:), forwardInvocationImpl, "v@:@");
    free(methods);
    NSString *superClassString = NSStringFromClass(object_getClass(hookClass));
    if (![superClassString isEqualToString:hookString]) {
        if (!class_isMetaClass(hookClass)) {
            [BigBang hookClass:superClassString];
        }
    }
}

+ (id)argumentAtIndex:(NSUInteger)index
       withInvocatein:(NSInvocation *)invocation
{
    const char *argType = [invocation.methodSignature getArgumentTypeAtIndex:index];
    if (argType[0] == 'r') {
        argType++;
    }
    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        __autoreleasing id returnObj;
        [invocation getArgument:&returnObj atIndex:(NSInteger)index];
        return returnObj;
    } else if (strcmp(argType, @encode(char)) == 0) {
        WRAP_AND_RETURN(char);
    } else if (strcmp(argType, @encode(int)) == 0) {
        WRAP_AND_RETURN(int);
    } else if (strcmp(argType, @encode(short)) == 0) {
        WRAP_AND_RETURN(short);
    } else if (strcmp(argType, @encode(long)) == 0) {
        WRAP_AND_RETURN(long);
    } else if (strcmp(argType, @encode(long long)) == 0) {
        WRAP_AND_RETURN(long long);
    } else if (strcmp(argType, @encode(unsigned char)) == 0) {
        WRAP_AND_RETURN(unsigned char);
    } else if (strcmp(argType, @encode(unsigned int)) == 0) {
        WRAP_AND_RETURN(unsigned int);
    } else if (strcmp(argType, @encode(unsigned short)) == 0) {
        WRAP_AND_RETURN(unsigned short);
    } else if (strcmp(argType, @encode(unsigned long)) == 0) {
        WRAP_AND_RETURN(unsigned long);
    } else if (strcmp(argType, @encode(unsigned long long)) == 0) {
        WRAP_AND_RETURN(unsigned long long);
    } else if (strcmp(argType, @encode(float)) == 0) {
        WRAP_AND_RETURN(float);
    } else if (strcmp(argType, @encode(double)) == 0) {
        WRAP_AND_RETURN(double);
    } else if (strcmp(argType, @encode(BOOL)) == 0) {
        WRAP_AND_RETURN(BOOL);
    } else if (strcmp(argType, @encode(char *)) == 0) {
        WRAP_AND_RETURN(const char *);
    } else if (strcmp(argType, @encode(void (^)(void))) == 0) {
        __unsafe_unretained id block = nil;
        [invocation getArgument:&block atIndex:(NSInteger)index];
        return [block copy];
    } else {
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(argType, &valueSize, NULL);
        
        unsigned char valueBytes[valueSize];
        [invocation getArgument:valueBytes atIndex:(NSInteger)index];
        
        return [NSValue valueWithBytes:valueBytes objCType:argType];
    }
    
    return nil;
    
#undef WRAP_AND_RETURN
}

+ (id)getReturnValueInvocatein:(NSInvocation *)invocation
{

    const char *returnType = invocation.methodSignature.methodReturnType;
    // Skip const type qualifier.
    if (returnType[0] == 'r') {
        returnType++;
    }
    
    if (strcmp(returnType, @encode(id)) == 0 || strcmp(returnType, @encode(Class)) == 0 || strcmp(returnType, @encode(void (^)(void))) == 0) {
        __autoreleasing id returnObj;
        [invocation getReturnValue:&returnObj];
        return returnObj;
    } else if (strcmp(returnType, @encode(char)) == 0) {
        WRAP_GET_VALUE(char);
    } else if (strcmp(returnType, @encode(int)) == 0) {
        WRAP_GET_VALUE(int);
    } else if (strcmp(returnType, @encode(short)) == 0) {
        WRAP_GET_VALUE(short);
    } else if (strcmp(returnType, @encode(long)) == 0) {
        WRAP_GET_VALUE(long);
    } else if (strcmp(returnType, @encode(long long)) == 0) {
        WRAP_GET_VALUE(long long);
    } else if (strcmp(returnType, @encode(unsigned char)) == 0) {
        WRAP_GET_VALUE(unsigned char);
    } else if (strcmp(returnType, @encode(unsigned int)) == 0) {
        WRAP_GET_VALUE(unsigned int);
    } else if (strcmp(returnType, @encode(unsigned short)) == 0) {
        WRAP_GET_VALUE(unsigned short);
    } else if (strcmp(returnType, @encode(unsigned long)) == 0) {
        WRAP_GET_VALUE(unsigned long);
    } else if (strcmp(returnType, @encode(unsigned long long)) == 0) {
        WRAP_GET_VALUE(unsigned long long);
    } else if (strcmp(returnType, @encode(float)) == 0) {
        WRAP_GET_VALUE(float);
    } else if (strcmp(returnType, @encode(double)) == 0) {
        WRAP_GET_VALUE(double);
    } else if (strcmp(returnType, @encode(BOOL)) == 0) {
        WRAP_GET_VALUE(BOOL);
    } else if (strcmp(returnType, @encode(char *)) == 0) {
        WRAP_GET_VALUE(const char *);
    } else if (strcmp(returnType, @encode(void)) == 0) {
        return nil;
    } else {
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(returnType, &valueSize, NULL);
        
        unsigned char valueBytes[valueSize];
        [invocation getReturnValue:valueBytes];
        
        return [NSValue valueWithBytes:valueBytes objCType:returnType];
    }
    
    return nil;
    
#undef WRAP_AND_RETURN
}


+ (NSString *)methodLogMethodName:(NSString *)selName {
    return [BIGBANG stringByAppendingFormat:@"%@",selName];
}

+ (IMP)getMsgForwardIMP:(Class)logedClass sel:(SEL)selector {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    Method method = class_getInstanceMethod(logedClass, selector);
    const char *encoding = method_getTypeEncoding(method);
    BOOL methodReturnsStructValue = encoding[0] == _C_STRUCT_B;
    if (methodReturnsStructValue) {
        @try {
            NSUInteger valueSize = 0;
            NSGetSizeAndAlignment(encoding, &valueSize, NULL);
            
            if (valueSize == 1 || valueSize == 2 || valueSize == 4 || valueSize == 8) {
                methodReturnsStructValue = NO;
            }
        } @catch (NSException *e) {}
    }
    if (methodReturnsStructValue) {
        msgForwardIMP = (IMP)_objc_msgForward_stret;
    }
#endif
    return msgForwardIMP;
}

+ (BOOL)isMsgForwardIMP:(IMP)impl {
    return impl == _objc_msgForward
#if !defined(__arm64__)
    || impl == (IMP)_objc_msgForward_stret
#endif
    ;
}



@end
