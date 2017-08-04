# BigBang

性能损耗


| 状态            | 平均耗时       | 次数    |
| -------------  |:-------------:| -----:|
| 不加之前        | 0.000213s     | 20000次 |
| 函数副本方法     | 0.000579s      | 20000次 |
| 存IMP指针方法    | 0.000216s     | 20000次 |

不同设备之间会存在差异

函数副本方法：

所有方法都加上 BigBang_前缀
副本方法IMP指针使用原方法的

存IMP指针方法

将IMP指针转成long 存入字典中

```objc
        //缓存
        _IMP imp = method_getImplementation(method);
        
        NSNumber *pNumber = [NSNumber numberWithLong:(long)imp];
        
        [impDict setObject:pNumber forKey:NSStringFromSelector(methodSel)];
        
        //使用
        NSNumber *pNumber = [impDict objectForKey:NSStringFromSelector(invocation.selector)];
        
        long *p = (long *)[pNumber longValue];
        
        _IMP imp = (_IMP)p;
        
        [invocation invokeUsingIMP:imp];
```


勾某个类的所有方法的，查看所有方法的执行顺序

使用方法

[BigBang hookClass:@"A_ManageViewController"];

常规使用：

放在只执行一次的函数里，防止多次勾一个函数
如

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions

hook：

__attribute__((constructor)) static void entry()

放这里面

打日志的printf 改成 nslog

在终端那个应用里面就能看到日志


![avatar](B0EEAE8F-5C95-4556-9848-B2072CAA1D96.png)  

微信

[BigBang hookClass:@"WCPayLogicMgr"];

[BigBang hookClass:@"WCRedEnvelopesLogicMgr"];

[BigBang hookClass:@"ContactUpdateHelper"];

[BigBang hookClass:@"WCRedEnvelopesNetworkHelper"];

[BigBang hookClass:@"WCRedEnvelopesReceiveHomeView"]

![avatar](0B7E92FC-D33C-4253-9C81-B291FA07F3AB.png)  
