# BigBang

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
