---
title: "干活日志"
date: 2020-11-25
description: "记录一下每天干了啥"
categories: [
  "折腾"
]
---

~~正经人谁写日记啊~~

# 2021

## 1月

### 2021/1/1

1. 说着搞复习还是睡了一整天，好困
2. MASS项目打工，当个乙方还得帮人改需求就很麻
3. vim适应不能，写代码速度--，学一下trick

### 2021/1/2

1. dnspod突然开始要求实名，被迫搬家。试了几家之后发现he.net还不错，立刻迁移
2. 配了一上午vim，大物挂科预定

### 2021/1/6

1. 现场拟合完了马原，无情的辩证统一生成器竟是我
2. 看etcd源码，拟合一下工程写法

### 2021/1/20

1. 重新开始读etcd

### 2021/1/23

1. 读了一点docker的底层原理，代码太多了读不动
2. 学graphql，明天把casbin学一下怎么做权限控制
3. 看etcd的raft，啃得头疼

### 2021/1/24

1. 折腾了一下安卓的兼容性，targetsdkversion还有native几个架构的兼容性之类的
2. 继续看etcd

### 2021/1/25

1. 对着casbin文档拟合了一下，看了看demo感觉很香
2. 继续看etcd

### 2021/1/26

1. 终于想起来学了一下mongodb，然后看了一些PG的特性，各有比较香的地方
2. 继续看etcd

### 2021/1/28

1. 脑子一抽又跑去看了B，B+和红黑，和innodb的一些底层
2. 日经etcd
3. 不能再摸鱼了，明天开始搓网盘

## 2月

颓废的1月结束嘞，开始干活

### 2021/2/1

1. 把vscode的vim也配起来了，rls换成了rust analyzer，体验好了很多

2. 想起来js里import和require之类的一堆坑一直没捋明白 ，找了两篇文章

   [深入解析ES Module（一）：禁用export default object](https://zhuanlan.zhihu.com/p/40733281)

   [深入解析ES Module（二）：彻底禁用default export](https://zhuanlan.zhihu.com/p/97335917)

   想起来给之前写的toc.js统一成typescript，搞了半天发现之前已经做过这事了QwQ

   开搓之前要记得fetch（

3. 把top的jq代码全部拿原生重写了，js真就是*山堆起来的语言啊麻了

   1. 原生没有提供获取element绝对位置的方法，需要用offset手动累加

      ```js
      function getAbsTop(element: HTMLElement): number{
        var actualTop = element.offsetTop;
        var current = element.offsetParent as HTMLElement;
        while (current !== null){
          actualTop += (current.offsetTop+current.clientTop);
          current = current.offsetParent as HTMLElement;
        }
        return actualTop
      }
      ```

   2. `querySelectorAll`返回nodelist类型，这玩意是类array，有forEach但没map，需要`Array.prototype.map.call`手动call，震撼我妈

### 2021/2/3

1. 脑子一抽又跑去学组原，看了一天MESI protocol之类的东西
2. 明天把RS码和RTC验证一下，再不开工来不及了

### 2021/2/4

1. RS和RTC跑通了，启动ctrlCV大法
2. quasar v2刚出beta，去玩一玩

### 2021/2/5

1. 准备分享会，碰巧看到一个minIO的洞，这玩意刚好也能拿来参考搓网盘，开始审代码

### 2021/2/9

1. 看到p牛文章分析了一个MinIO的SSRF洞，这个项目本身和这个洞都挺有意思

   开始读MinIO代码

2. 区块链打工，学到go的map其实是个引用——再加上编译器的逃逸分析，直接在函数里开map然后return出来并不会有性能问题

### 2021/2/10

1. 学了一下Padding oracle attack

2. 读etcd储存层boltdb的代码，照着codedump过了一遍基本struct和bucket

   go的黑魔法还挺多的

### 2021/2/11

1. 学了一下sync.Mutex的底层实现

   抄一个CAS的汇编解析

   ```assembly
   // bool Cas(int32 *val, int32 old, int32 new)
   // Atomically:
   //	if(*val == old){
   //		*val = new;
   //		return 1;
   //	} else
   //		return 0;
   // 这里参数及返回值大小加起来是17，是因为一个指针在amd64下是8字节，
   // 然后int32分别是占用4字节，最后的返回值是bool占用1字节，所以加起来是17
   TEXT runtime∕internal∕atomic·Cas(SB),NOSPLIT,$0-17 
   	// 为什么不把*val指针放到AX中呢？因为AX有特殊用处，
   	// 在下面的CMPXCHGL里面，会从AX中读取要比较的其中一个数
   	// PS:没看懂FP是啥
   	MOVQ	ptr+0(FP), BX
   	// 所以AX要用来存参数old
   	MOVL	old+8(FP), AX
   	// 把new中的数存到寄存器CX中
   	MOVL	new+12(FP), CX
   	// 注意这里了，这里使用了LOCK前缀，所以保证操作是原子的
   	LOCK
   	// 0(BX) 可以理解为 *val
   	// 把 AX中的数 和 第二个操作数 0(BX)——也就是BX寄存器所指向的地址中存的值 进行比较
   	// 如果相等，就把 第一个操作数 CX寄存器中存的值 赋给 第二个操作数 BX寄存器所指向的地址
   	// 并将标志寄存器ZF设为1
   	// 否则将标志寄存器ZF清零
   	CMPXCHGL	CX, 0(BX)
   	// SETE的作用是：
   	// 如果Zero Flag标志寄存器为1，那么就把操作数设为1
   	// 否则把操作数设为0
   	// 也就是说，如果上面的比较相等了，就返回true，否则为false
   	// ret+16(FP)代表了返回值的地址
   	SETEQ	ret+16(FP)
   	RET
   ```

   最初的朴素锁实现：

   ```go
   // Lock locks m.
   // If the lock is already in use, the calling goroutine
   // blocks until the mutex is available.
   func (m *Mutex) Lock() {
       // Fast path: grab unlocked mutex. 快速上锁，当前 state 为 0，说明没人锁。CAS 上锁后直接返回
       if atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked) {
           if raceenabled {
               raceAcquire(unsafe.Pointer(m))
           }
           return
       }
   
       awoke := false // 被唤醒标记，如果是被别的 goroutine 唤醒的那么后面会置 true
       for {
           old := m.state // 老的 m.state 值
           new := old | mutexLocked // 新值要置 mutexLocked 位为 1
           if old&mutexLocked != 0 { // 如果 old mutexLocked 位不为 0，那说明有人己经锁上了，那么将 state 变量的 waiter 计数部分 +1
               new = old + 1<<mutexWaiterShift
           }
           if awoke {
               // The goroutine has been woken from sleep,
               // so we need to reset the flag in either case. 如果走到这里 awoke 为 true, 说明是被唤醒的，那么清除这个 mutexWoken 位，置为 0
               new &^= mutexWoken
           }
           // CAS 更新，如果 m.state 不等于 old，说明有人也在抢锁，那么 for 循环发起新的一轮竞争。
           if atomic.CompareAndSwapInt32(&m.state, old, new) {
               if old&mutexLocked == 0 { // 如果 old mutexLocked 位为 1，说明当前 CAS 是为了更新 waiter 计数。如果为 0，说明是抢锁成功，那么直接 break 退出。
                   break
               }
               runtime_Semacquire(&m.sema) // 此时如果 sema <= 0 那么阻塞在这里等待唤醒，也就是 park 住。走到这里都是要休眠了。
               awoke = true  // 有人释放了锁，然后当前 goroutine 被 runtime 唤醒了，设置 awoke true
           }
       }
   
       if raceenabled {
           raceAcquire(unsafe.Pointer(m))
       }
   }
   
   // Unlock unlocks m.
   // It is a run-time error if m is not locked on entry to Unlock.
   //
   // A locked Mutex is not associated with a particular goroutine.
   // It is allowed for one goroutine to lock a Mutex and then
   // arrange for another goroutine to unlock it.
   func (m *Mutex) Unlock() {
       if raceenabled {
           _ = m.state
           raceRelease(unsafe.Pointer(m))
       }
   
       // Fast path: drop lock bit. 快速将 state 的 mutexLocked 位清 0，然后 new 返回更新后的值，注意此 add 完成后，很有可能新的 goroutine 抢锁，并上锁成功
       new := atomic.AddInt32(&m.state, -mutexLocked)
       if (new+mutexLocked)&mutexLocked == 0 { // 如果释放了一个己经释放的锁，直接 panic
           panic("sync: unlock of unlocked mutex")
       }
   
       old := new
       for {// 如果 state 变量的 waiter 计数为 0 说明没人等待锁，直接 return 就好，同时如果 old 值的 mutexLocked|mutexWoken 任一置 1，说明要么有人己经抢上了锁，要么说明己经有被唤醒的 goroutine 去抢锁了，没必要去做通知操作
           // If there are no waiters or a goroutine has already
           // been woken or grabbed the lock, no need to wake anyone.
           if old>>mutexWaiterShift == 0 || old&(mutexLocked|mutexWoken) != 0 {
               return
           }
           // Grab the right to wake someone. 将 waiter 计数位减一，并设置 awoken 位
           new = (old - 1<<mutexWaiterShift) | mutexWoken
           if atomic.CompareAndSwapInt32(&m.state, old, new) {
               runtime_Semrelease(&m.sema) // cas 成功后，再做 sema release 操作，唤醒休眠的 goroutine
               return
           }
           old = m.state
       }
   }
   ```

   mutexWoken仅在unlock中通过semaphore信号量唤起其他gouroutine时添加，似乎并没有什么用（？

   后续的自旋和公平锁中起到作用

   目前的实现（公平锁）：

   ```go
   // Lock locks m.
   // If the lock is already in use, the calling goroutine
   // blocks until the mutex is available.
   func (m *Mutex) Lock() {
       // Fast path: grab unlocked mutex. 快速上锁逻辑
       if atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked) {
           if race.Enabled {
               race.Acquire(unsafe.Pointer(m))
           }
           return
       }
   
       var waitStartTime int64 // waitStartTime 用于判断是否需要进入饥饿模式
       starving := false // 饥饿标记
       awoke := false // 是否被唤醒
       iter := 0 // spin 循环次数
       old := m.state
       for {
           // Don't spin in starvation mode, ownership is handed off to waiters
           // so we won't be able to acquire the mutex anyway. 饥饿模式下不进行自旋，直接进入阻塞队列
           if old&(mutexLocked|mutexStarving) == mutexLocked && runtime_canSpin(iter) {
               // Active spinning makes sense.
               // Try to set mutexWoken flag to inform Unlock
               // to not wake other blocked goroutines.
               if !awoke && old&mutexWoken == 0 && old>>mutexWaiterShift != 0 &&
                   atomic.CompareAndSwapInt32(&m.state, old, old|mutexWoken) {
                   awoke = true
               }
               runtime_doSpin()
               iter++
               old = m.state
               continue
           }
           new := old
           // Don't try to acquire starving mutex, new arriving goroutines must queue.
           if old&mutexStarving == 0 { // 只有此时不是饥饿模式时，才设置 mutexLocked，也就是说饥饿模式下的活跃 goroutine 直接排队去
               new |= mutexLocked
           }
           if old&(mutexLocked|mutexStarving) != 0 { // 处于己经上锁或是饥饿时，waiter 计数 + 1
               new += 1 << mutexWaiterShift
           }
           // The current goroutine switches mutex to starvation mode.
           // But if the mutex is currently unlocked, don't do the switch.
           // Unlock expects that starving mutex has waiters, which will not
           // be true in this case. 如果当前处于饥饿模式下，并且己经上锁了，mutexStarving 置 1，接下来 CAS 会用到
           if starving && old&mutexLocked != 0 {
               new |= mutexStarving
           }
           if awoke { // 如果当前 goroutine 是被唤醒的，然后清 mutexWoken 位
               // The goroutine has been woken from sleep,
               // so we need to reset the flag in either case.
               if new&mutexWoken == 0 {
                   throw("sync: inconsistent mutex state")
               }
               new &^= mutexWoken
           }
           if atomic.CompareAndSwapInt32(&m.state, old, new) {
               if old&(mutexLocked|mutexStarving) == 0 { // 如果 old 没有上锁并且也不是饥饿模式，上锁成功直接退出
                   break // locked the mutex with CAS
               }
               // If we were already waiting before, queue at the front of the queue.
               queueLifo := waitStartTime != 0 // 第一次 queueLifo 肯定是 false
               if waitStartTime == 0 {
                   waitStartTime = runtime_nanotime() 
               }
               runtime_SemacquireMutex(&m.sema, queueLifo) // park 在这里，如果 queueLifo 为真，那么扔到队头，也就是 LIFO
         // 走到这里，说明被其它 goroutine 唤醒了，继续抢锁时先判断是否需要进入 starving
               starving = starving || runtime_nanotime()-waitStartTime > starvationThresholdNs // 超过 1ms 就进入饥饿模式
               old = m.state
               if old&mutexStarving != 0 { // 如果原来就是饥饿模式的话，走 if 逻辑
                   // If this goroutine was woken and mutex is in starvation mode,
                   // ownership was handed off to us but mutex is in somewhat
                   // inconsistent state: mutexLocked is not set and we are still
                   // accounted as waiter. Fix that.
                   if old&(mutexLocked|mutexWoken) != 0 || old>>mutexWaiterShift == 0 {
                       throw("sync: inconsistent mutex state")
                   }
           // 此时饥饿模式下被唤醒，那么一定能上锁成功。因为 Unlock 保证饥饿模式下只唤醒 park 状态的 goroutine
                   delta := int32(mutexLocked - 1<<mutexWaiterShift) // waiter 计数 -1
                   if !starving || old>>mutexWaiterShift == 1 { // 如果是饥饿模式下并且自己是最后一个 waiter ，那么清除 mutexStarving 标记
                       // Exit starvation mode.
                       // Critical to do it here and consider wait time.
                       // Starvation mode is so inefficient, that two goroutines
                       // can go lock-step infinitely once they switch mutex
                       // to starvation mode.
                       delta -= mutexStarving
                   }
                   atomic.AddInt32(&m.state, delta) // 更新，抢锁成功后退出
                   break
               }
               awoke = true // 走到这里，不是饥饿模式，重新发起抢锁竞争
               iter = 0
           } else {
               old = m.state // CAS 失败，重新发起竞争
           }
       }
   
       if race.Enabled {
           race.Acquire(unsafe.Pointer(m))
       }
   }
   
   // Unlock unlocks m.
   // It is a run-time error if m is not locked on entry to Unlock.
   //
   // A locked Mutex is not associated with a particular goroutine.
   // It is allowed for one goroutine to lock a Mutex and then
   // arrange for another goroutine to unlock it.
   func (m *Mutex) Unlock() {
       if race.Enabled {
           _ = m.state
           race.Release(unsafe.Pointer(m))
       }
   
       // Fast path: drop lock bit. 和原有逻辑一样，先减去 mutexLocked，并判断是否解锁了未上锁的 Mutex, 直接 panic
       new := atomic.AddInt32(&m.state, -mutexLocked)
       if (new+mutexLocked)&mutexLocked == 0 {
           throw("sync: unlock of unlocked mutex")
       }
       if new&mutexStarving == 0 { // 查看 mutexStarving 标记位，如果 0 走老逻辑，否则走 starvation 分支
           old := new
           for {
               // If there are no waiters or a goroutine has already
               // been woken or grabbed the lock, no need to wake anyone.
               // In starvation mode ownership is directly handed off from unlocking
               // goroutine to the next waiter. We are not part of this chain,
               // since we did not observe mutexStarving when we unlocked the mutex above.
               // So get off the way.
               if old>>mutexWaiterShift == 0 || old&(mutexLocked|mutexWoken|mutexStarving) != 0 {
                   return
               }
               // Grab the right to wake someone.
               new = (old - 1<<mutexWaiterShift) | mutexWoken
               if atomic.CompareAndSwapInt32(&m.state, old, new) {
                   runtime_Semrelease(&m.sema, false)
                   return
               }
               old = m.state
           }
       } else {
           // Starving mode: handoff mutex ownership to the next waiter.
           // Note: mutexLocked is not set, the waiter will set it after wakeup.
           // But mutex is still considered locked if mutexStarving is set,
           // so new coming goroutines won't acquire it.
           runtime_Semrelease(&m.sema, true) // 直接 runtime_Semrelease 唤醒等待的 goroutine
       }
   }
   ```

   > 整体来讲，公平锁上锁逻辑复杂了不少，边界点要考滤的比较多
   >
   > 1. 同样的 fast path 快速上锁逻辑，原来 m.state 为 0，锁就完事了
   > 2. 进入 for 循环，也要走自旋逻辑，但是多了一个判断，如果当前处于饥饿模式禁止自旋，根据实现原理，此时活跃的 goroutine 要直接进入 park 的队列
   > 3. 自旋后面的代码有四种情况：饥饿抢锁成功，饥饿抢锁失败，正常抢锁成历，正常抢锁失败。上锁失败的最后都要 waiter 计数加一后，更新 CAS
   > 4. 如果 CAS 失败，那么重新发起竞争就好
   > 5. 如果 CAS 成功，此时要判断处于何种情况，如果 old 没上锁也处于 normal 模式，抢锁成历退出
   > 6. 如果 CAS 成功，但是己经有人上锁了，那么要根据 queueLifo 来判断是扔到 park 队首还是队尾，此时当前 goroutine park 在这里，等待被唤醒
   > 7. `runtime_SemacquireMutex` 被唤醒了有两种情况，判断是否要进入饥饿模式，如果老的 old 就是饥饿的，那么自己一定是唯一被唤醒，一定能抢到锁的，waiter 减一，如果自己是最后一个 waiter 或是饥饿时间小于 starvationThresholdNs 那么清除 mutexStarving 标记位后退出
   > 8. 如果老的不是饥饿模式，那么 awoke 置 true，重新竞争
   >
   > 链接：[GO: sync.Mutex 的实现与演进](https://www.jianshu.com/p/ce1553cc5b4f)

2. 继续读MinIO

### 2021/2/12

1. 搓了一下午的地图，echarts的bmap有一堆坑，枯了

   js的高阶函数也很坑，arraytype没有foreach属实长见识

### 2021/2/14

1. 读完MinIO，明天开始准备环境

2. 学了一手mongo分片，开学之后试试在istio里把pulsar和mongo跑起来 // TODO

   丢家里的机子稳定性不错，回头装个linux上去，可以部署异地集群了

### 2021/2/19

1. 颓废好多天，研究挖矿好多天

### 2021/2/20

1. 学了graphviz咋用，之后写篇博客梳理一个大型项目

   MinIO主要是业务代码，梳理的价值不太大，之后考虑下Pulsar（等学完java再说（ // TODO

### 2021/2/21

1. 分享会讲了下MinIO的SSRF，学了下docker的几种逃逸

### 2021/2/23

1. 学了一些java基础和审计要点
2. 把electron和ffi跑起来，明天搓课设

### 2021/2/24-28

1. 折腾electron 画前端

## 3月

### 2021/3/1

1. 学密码学：Pedersen非常好玩；merkle tree可以塞进网盘的文件系统

   看了些格密码的入门

### 2021/3/3

1. 开始着手组NAS，捡了一个rh2285hv2来玩，d3条子现在简直贵的离谱

### 2021/3/7

1. 路由器日常gg，ping和dns能通上不了网，排查半天发现是代理gg，全局没关


### 2021/3/12

1. 最近天天搓课设，很久没写前端这次刚好练下手，有点后悔没用vue3

   规范了半天各种命名，结果最后还是无脑mainLayout一把梭了，也没怎么优化逻辑复用，代码并不是很文雅

   lodash是个好东西，JS原生API可太难用了

2. 垃圾Electron调用C遍地都是坑，配环境配得满头包

   单独写篇博客记一下

### 2021/3/13

1. 捡的rh2285hv2服务器到了，freenas的BIOS模式大概有些问题，是很多遍还是起不来遂放弃

   还是当成母鸡用比较合适，proxmox ve完美运行

   结果配了一堆东西之后脑子一抽给rootfs缩了2G，当场变砖

### 2021/3/14

1. 去樱园第一次拍人像，完全是随手乱抓

### 2021/3/15

1. 投简历，之后写一写pingcap的tinny kv // TODO
2. 把博客迁移回vultr，ban瓦工真被ban了

### 2021/3/16

1. 配了一整天路由器，之前学的iptables完全是随手乱抓，这次我已经深入理解了（确信（x
2. 感觉自己os过于薄弱，打算试试cs3210 // TODO

### 2021/3/17

1. 起了一个raidz，但是写入放大有巨大问题，usage会达到实际的160%左右

   大致原因是zfs的卷单元大小（volblocksize）默认是8k，但是6块盘组raidz后写入量为8k/5=1.6k，不到底层硬盘块大小（4k）的一半，产生巨大写放大

   解决方案就是手动创建vol，volblocksize设置为128k减小冗余比例，参考如下：

   raidz实现原理：https://jro.io/nas/#overhead

   解决方法：https://sites.google.com/site/ryanbabchishin/home/publications/changing-a-zvol-block-size-while-making-it-sparse-and-compressed

### 2021/3/18

1. 重建博客server，发现浓眉大眼的`trustasia`也需要认证了，换到`certbot`+`let's encrypt`

   做了一些回落+ws，安全性++++

2. 原来的博客是hugo本地编译再push整个public，并不文雅而且容易丢失原档

   改了一下git hook，把markdown拉到server上再编译

3. 才发现rc.local过时了，当场拟合一下systemd的启动咋写

### 2021/3/19

1. 尝试了很久使用snap的hugo，但snap的安全策略非常激进，手动配置app允许访问的路径非常困难

   要是这种东西取代apt的话还不如跑路arch（恼

2. 重写webhook，顺便搓个dockerfile放进docker里跑，方便管理&安全性++

3. 学spring boot

### 2021/3/22

1. 本来准备学CS3210，但是考虑到rCore资料比较多，写完rustlings就开始rCore
2. 搓报告

# 2020

## 11月

### 2020/11/24

1. 配了一堆jetbrains的快捷键，抛弃垃圾`VS Code`Keymap插件
2. 学了下levelDB咋用，在win上编译了一下午没跑起来，放弃
3. 在板子上配了SMB，某个**数据库传上去开始跑levelDB，速度真香，billion数据机械盘秒查
4. 学了powershell咋写，搓了个自动备份Code脚本，挂在任务计划每天跑一次，防丢数据
   - 163辣鸡，outlook好
5. 写大雾（x

### 2020/11/25

1. 给脚本加了seek，方便中断后继续&5亿之后插入有点慢，分了下库

2. 备份脚本修修补补

   - foreach辣鸡，管道好
   - 修了修文件LastWriteTime的判定，解决了clone的文件无法备份

3. 给查询服务搓了一遍drone&docker&compose，devops热了下手

4. 过了一遍Kotlin examples，感觉差不多是Java+Python+一点JS，现代语言都长一个样（

5. 看了一遍Dart examples，这玩意真的不是ES6吗

   总之全平台GUI真香，以后卷课设可以玩玩（

### 2020/11/26

1. ban掉了link文件，脚本基本能用了，push上博客

2. 把**数据库跑完了，发现5亿之后还是很快，怀疑plyvel的batch write之后不会自动clear？？不是很懂，反正加一行clear不费劲（x

   改了改服务加了个接口，push一把梭完事直接`docker-compose up -d`，drone真香

3. 不小心删了1G的**，及时Ctrl+C还能用，学了一把debugfs和awk咋使

   但是leveldb本身就会删除文件，所以inode一团糟，直接放弃恢复，凑合用吧

   debugfs只能dump单个文件太烦了，搓了一下批量恢复，留待以后哪天rm -rf /的时候用（x

   ```shell
   echo "ls -d /home/zero/Data/**db/**db" | sudo debugfs /dev/sda2 | awk 'NR>2' | xargs -n 3 | awk ' { print "dump "$1" /tmp/dump/**db/"$3;}' | sudo debugfs /dev/sda2
   ```

4. 整了个浏览器数据自动导出的玩意，啪，很快啊，我的裤子就被搞出来了，我说停停，Chrome你这加密不讲伍德，让我换个password manager，上个两步验证

5. 锂电池到了，重新配了下路由器，openwrt的5g频段有神秘力量，莫名其妙炸了莫名其妙又好了

   总之均衡负载一下，没有wifi受到伤害的世界达成了（x

### 2020/11/27

1. 回家把newifi3 d2搞来了，迁移了一下路由器配置，千兆网提高生活质量

   正好把板子摞在上面省地儿，就是热量爆炸（

   这路由器好吃电啊，电池根本充不满，危

2. 补了点ddl

3. leveldb缺文件之后服务会挂，回滚了，反正**查询用的少

4. 再不复习概统要挂科了，好困

### 2020/11/28

1. 修了下zt，之前那个network有玄学，PC连不上。顺便把d2加进去了

   家里移动宽带没要到公网IP，看了下是NAT3，等大船靠岸家里组个IDC(不是)，可以用zt打下洞

   板子上的zt版本有点老，不太灵光。直接pacman一把梭，所有包全部更新一遍，滚动更新有被爽到

2. 睡眠质量连续爆炸，头疼，复习不进去，要挂科了（

3. 把flutter example看完了，真不戳

### 2020/11/29

1. 把之前区块链的代码拉出来看了下go的test咋写
2. 试图入门spring，入门到放弃
3. 概率论什么玩意，要挂科了（确信

### 2020/11/30

1. 上午考了概统，今年出卷良心，大概不会挂科了（

2. 摸了半天鱼休息一下，晚上把hls接着看了一部分，之后着手把推流原型实现一下

   flutter生态有亿点差，`quasar`v2等12.15出beta.1之后试试看，推流原型实现之后开始规划后端架构



## 12月

### 2020/12/1

1. 修了一天路由器，不知道为啥打死都修不好，貌似是mwan3神秘问题，插上有线网之后无线网卡直接去世

   就算能ping通，路由器wget能通，lan口也不能上网，绝了

   防火墙关了也不行，想不明白，弃疗

2. 想起来还要把博客文章页加个目录，等推流原型搓完了学下hugo文档

3. 复习朱据结构，明天下午考试现在开始复习，也许会挂科（

### 2020/12/2

1. 辣鸡数据结构，感觉考挂了，算了加权看开了（

2. 给Istio升级到1.8，看了下新特性感觉变化不太大，不过上次升级到1.7.2折腾到一半，只部署了istiod，plane没有切过去，今天刚好解决一下

   16G内存有点顶不住了，有空回家把内存挂咸鱼卖了换16x2

3. 看了envoy的webassambly文档，发现支持rust于是兴冲冲init了一个helloworld，结果完全看不懂（

   这是啥，这又是啥，立刻重学rust

4. 看了下redis的分布式锁，可以悲观锁，但是侵入量太高了，性价比很低

5. 网盘的分布式事务（如果用得到）考虑到sql部分对资源的抢占式操作很少，TCC虽然很香但是Istio生态下没有好用的框架，手写的话侵入程度太大一个人根本写不动，计划用Pulsar做最终一致性，出问题直接死信队列手工处理

   然后考虑到get操作天然幂等，post/put等方法按restful标准，应当返回简单的状态码，因此http/grpc的body并不会很大，可以写一个wasm插件缓存reply，client出现重放时返回缓存值，配合pulsar几乎无侵入解决幂等性和分布式事务，保持和Istio一致的设计思想。

   具体做法待学习wasm的SDK，如果能调用redis可以考虑写入redis集群（好写但增加链路长度和延迟，降低可靠性），暴力缓存，考虑三种方案：

   1. treap树维护id，堆维护time，定期清理一次过期缓存，缓存时长根据约定超时重试时间决定
      - qps过高后内存可能爆炸，reply比较短的话可以接受，时间上复杂度klogn对于单机1wqps来说应该比较轻松
   2. 手写队列+循环bloom filter，定期重建一个过期bloom filter，加filter之后查询很少，O(n)查找，因为body中存有id，可以排除假阳
      - 感觉不错，性能非常高，不过内存开销还是很大，bloom filter方面1‰的假阳需要33倍空间，好在bitmap相比于hashtable压缩了几个数量级，完全可以忽略不计
      - 或者可以直接用hashtable+队列，可能会频繁扩缩容，并发过高之后存在巨量内存拷贝的问题
   3. hashtable存body，wasm增加ack，server收到ack之后删除相应数据，队列存time和id，通过队列定期删除hashtable并对id进行check，防止double free
      - 解决内存问题，虽然增加网络开销，不过只是增加简短的ack报文，极致一点可以考虑upd，发丢了也能被过期队列清除，比起大大节约内存资源来说，主观上感觉开销完全可以接受，可以根据情况权衡。

### 2020/12/3

1. 看了一点pulsar，支持动态扩容和消息事务真香，有时间仔细学一下 //TODO

2. 辣鸡路由器，修了一天修不动结果它自己突然就好了，绝了

   辣鸡vmware，莫名其妙给我整出来两个额外的network adapter，手动卸载之后才能ping通

   我跟计网八字不合实锤了

3. 昨天istio没部署完，今天收个尾。看了下describe发现昨天部署的时候卡住不是因为网络原因，是node内存不足所以超时了。

   ```bash
   istioctl install --set profile=demo --set revision=canary
   ```

   用demo配置重新部署了一遍，顺便修好了之前的egressgateway的probe问题

4. 才发现之前尝试高可用是直接部署的keepalived，只能实现master节点的故障切换，但是由于各个master节点之间状态不一致，服务还是会挂

   使用keepalived维持vip，再通过HAProxy（也可以nginx/lvs，看了下感觉haproxy比较好用）在master集群做一个roundrobin的均衡负载，防止性能浪费

   可以通过kubeadm一键部署，使master组成etcd集群，保证状态一致

   由于etcd的raft算法采用投票机制，需要奇数节点才能有效投票，使用两个master节点时无法取得多数投票，因此只要一个节点下线整个节点均不可用，反而降低了整体的可靠性。但是开三个master节点虚拟机内存直接起飞，这里暂时记录配置留待以后尝试 //TODE

   ![ha_pic2](https://d33wubrfki0l68.cloudfront.net/d1411cded83856552f37911eb4522d9887ca4e83/b94b2/images/kubeadm/kubeadm-ha-topology-stacked-etcd.svg)

   #### 配置haproxy

   haproxy.cfg

   ```cfg
   global
   log 127.0.0.1 local0
   log 127.0.0.1 local1 notice
   maxconn 4096
   #chroot /usr/share/haproxy
   #user haproxy
   #group haproxy
   daemon
       
   defaults
       log     global
       mode    http
       option  httplog
       option  dontlognull
       retries 3
       option redispatch
       timeout connect  5s
       timeout client  1m
       timeout server  1m
       
   frontend stats-front
     bind *:8081
     mode http
     default_backend stats-back
       
   frontend fe_k8s_6444
     bind *:6444
     mode tcp
     timeout client 1h
     log global
     option tcplog
     default_backend be_k8s_6443
     acl is_websocket hdr(Upgrade) -i WebSocket
     acl is_websocket hdr_beg(Host) -i ws
       
   backend stats-back
     mode http
     balance roundrobin
     stats uri /haproxy/stats
     stats auth pxcstats:secret
       
   backend be_k8s_6443
     mode tcp
     timeout queue 1h
     timeout server 1h
     timeout connect 1h
     log global
     balance roundrobin
     server master01 192.168.98.5:6443
     server master02 192.168.98.6:6443
     server master03 192.168.98.7:6443
   ```

   Dockerfile

   ```
   FROM haproxy:2.3
   COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
   ```

   ```bash
   docker build -t my-haproxy .
   docker run -d my-haproxy
   ```

   #### kubeadm init

   参考[使用堆控制平面和 etcd 节点](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/high-availability/#使用堆控制平面和-etcd-节点)

   网上找的配置文件改了改，和官方文档有所出入，之后测试一下

   kubeadm-config.yaml

   ```yaml
   apiVersion: kubeadm.k8s.io/v1beta2
   kind: ClusterConfiguration
   apiServer:
   certSANs: # hostname, ip, vip
   - master01
   - master02
   - master03
   - 192.168.98.5
   - 192.168.98.6
   - 192.168.98.7
   - 192.168.98.3
   controlPlaneEndpoint: "192.168.98.3:6443"
   networking:
   podSubnet: "10.244.0.0/16"
   ```

   ```bash
   kubeadm init --config=kubeadm-config.yaml|tee kubeadim-init.log
   ```

5. 复习一点大雾实验

### 2020/12/4

1. 上午考试睡大觉，下午吃饭打游戏，快乐摸鱼的一天

2. 划掉一项todolist，把便携机安排一下。捡了一晚上垃圾，搞一个DC直插，方便断电之后接锂电干活或者带出去用。

   | Name                   | Price |
   | :--------------------- | :---- |
   | ql2x                   | 360   |
   | 华硕B150M-A D3         | 188   |
   | 十铨D3 1600 8Gx2       | 264   |
   | IS40X                  | 80    |
   | M8VC 500G              | 419   |
   | 120W DC-ATX电源+适配器 | 135   |
   | 9260AC                 | 80    |
   | 机箱                   | 100-  |
   | total                  | 1k6   |

   预算从1k涨到1k6，不过除了内存频率拉跨以外都很香了

### 2020/12/5

1. 好好学了一下CSS，之前全靠复制粘贴和手动瞎调不太靠谱

2. 垃圾长宽，把github劫持了，改完dns之后ssh还是不能用，非得挂代理。这种无良企业啥时候倒闭啊？？

   中间还因为wsl里的host没更新，挂proxychains也push不上去，修了一个点才找到问题，佛了

3. 看到有NAT3优化到NAT1的文章，下次回家尝试优化，学校改为对称NAT之后只能和NAT1和NAT2打洞了，否则ICE要走TURN才能穿透，速度太慢

### 2020/12/6

1. 学了一下hugo的文档，有时间给博客加个文章目录，不然日志太长了翻起来麻烦
2. 用dns劫持把DC1跑起来了，陈年todolist划掉一项，接入了node-red，这个东西感觉还挺好玩的，有空学一下文档之后加点功耗累计之类的功能

### 2020/12/7

1. 上午睡大觉，下午新机子的零件倒了，装了一下午机，晚上配了下环境超了超频。CPU-Z单核跑到520可太狠了，台式的3700x被暴打。

### 2020/12/8

1. 把新机子换到DC1上看了下功耗，昨天配置没配置功耗墙，直接上170w吓死个人，感谢电源不杀之恩

   昨天电压没调好容易蓝，今天调试了一下参数控制一下功耗，单核1.05v上4.7G，单核跑530分秒天秒地，这波抽到SSR了

2. 超频真好玩（

   又搞了一天，最高全核4.6暴打7700k可太猛了，可惜散热和电源都上不去，电压往下拉到1.04才能不撞温度墙，但实在太低了巨容易蓝屏，截图留念

   ![超频极限](超频极限.png)

   最后1.105v，单核4.7G全核4.1G，功耗刚好150w，就很理想

3. 晚上补了一波作业，猛然发现周末考四级，英语得做点题了（

4. 鸽了好几天终于把hugo的topic栏加上了，hugo语法有点怪，关键字有点像pw

5. 去打工，把mass的项目赶紧搞完，拖了好久了实在麻烦

6. 继续补ddl

### 2020/12/9

1. 打了一天的工，裂开了，三点才睡，打工人落泪

2. topic写挂了，有空再改吧（

### 2020/12/10

1. 直接补了一天的觉

2. 单端的电源线买错了，dc口2.1mm和2.5mm的坑踩了一万遍👎👎👎。目前看来2.5用的比较多，而且勉强可以兼容2.1，以后记得看清楚

3. 新网卡倒了，12DB天线看起来挺猛的，但是路由器感觉有点拉跨，nc跑了200M就不行了，等新电源到了跑个iperf3试试看

4. 把内网wg修了一下，发现openwrt的dnsmasq默认搞了53端口的转发，仔细学了一遍iptables咋写

   改iptables的时候，一开始在nat用`-d {ip} --dport 53 -j ACCEPT`放行结果死活连不上，后来才发现`--dport`是扩展模块，必须`-p`指定协议才能用，每日踩坑（∞/∞）

5. 搞smb的时候改了下user目录的权限，结果ssh连不上去了，插vga看log才发现目录权限高了会直接denied，每日踩坑（∞/∞）

6. 改了下输入法设置和WT设置，提高生活质量，记一下[Windows Terminal配置项](https://www.jianshu.com/p/13e832853926)

7. 日常补ddl，猛然发现四级周六就考，我麻了，真就裸考（

### 2020/12/11

1. 看了下之前捡的板子是联想OEM的inagra crb，联想官网压根搜不到，bios版本太低了没有power management，就很烦
2. 上大雾缝了一点topic，没看明白，好烦
3. 好颓啊，考前一天晚上打了一晚上pummel party，u1s1真的好玩

### 2020/12/12

1. 上午考四级，随缘做题，听力开始了监考不提醒，就离谱，爱咋地咋地吧

2. 下午回家把大麦配好了，开了upnp之后测了一下成功full cone，可以STUN打洞

   回学校ping了一下延迟5ms，好评。有时间尝试一下wireguard on zerotier，虽然家里上行带宽只有20M-，但是考虑到延迟还是比小水管好用多了

3. 晚上打了知识挑战赛，一直学东西不怎么上手写，现在码力确实好菜啊，一个回文链表5min没写出来，算法康复需要提上日常了 // TODO

### 2020/12/13

1. 终于找到板子的网络唤醒和来电自启了，搓了一下red node，终于能早上设备全家桶定时自启辽，生活质量++
2. 把数据结构实验报告给搓了，近期还有离散，分析，对话三个ddl，明天必须结束，马原笔记周二抄一下
3. 最近好颓废啊，效率特别低，实属需要加把劲干活，网盘的几个部分要开始验证原型了

### 2020/12/14

1. 电源线终于到了，把原来的超频电压改回adaptive然后offset降压，多核的时候会自动增压，提高多核性能

   按照120w的标准调了一个battery模式，插电池的时候可以把功耗降下来，性能也还不错：相对于全功率单核-5%，全核-20%

2. 跑了个iperf，TODO回收。新3的5g速率确实有问题，只能跑到300M，不过凑合够用

### 2020/12/15

1. 学CAD和solidworks，找了两个不错的模型，准备开搓
2. 继续颓废，睡大觉

### 2020/12/16

1. 把node red重新搞了搞，现在插线板可以来电自启了，就是先前抄来的代码实现有点粗糙，快速切换按钮会有并发问题，不过还算可以接受，不想重构了（懒狗言论

2. de了好久bug，发现博客toc的空标题是hugo自己本身的bug，官方文档也及其混乱，函数完全没有分类，读起来究极心塞。

   搓了半天用模板语法搞了个toc，后续再优化一下缩进层次加个css，明天赶紧搞完吧，摸鱼太久了

3. 区块链的MASS修了修bug

### 2020/12/17

1. 2k4跑死我了，真得好好锻炼了（flag
2. 第二天不小心把博客扬了，没push搞丢了，这天干了啥来着（

### 2020/12/18

1. 上午不小心把博客扬了，晚上又不小把服务器扬了，还好都能抢救，折腾了一天，裂开
2. 把toc的css写了，读了一发sass的文档，各种语法糖用起来挺爽的，就是太长了一口气记不住，试了一下一些基本特性

### 2020/12/19

1. 写辣鸡网安实践报告和数据结构报告，ddl总算划掉一下
2. 加了个toc自动收缩和高亮的js，不然标题太多之后目录会超出屏幕，博客这段work总算告一段落
3. 看了一发typescript文档，把toc迁移到ts了，代码补全挺爽的，想动态类型的时候也可以直接写，非常舒适
4. 重新开始学rust，准备搞个deno来读一读，虽然这东西好像并不是很实用

### 2020/12/22

1. 学rust，试一试tide和actix
2. idea快捷键太难配了，快进到学vim，vim真好玩.jpg
3. 睡大觉（叉腰

### 2020/12/25

1. 看了好几天的rust，越学越迷糊，头大

2. ql2x的板子又给我整一堆蓝屏，这次频率降到4.6G，必不可能再出问题了（flag

   启了rdp和zt，可以连上去写安卓，intel的u可以直接跑AS的虚拟机，比较方便
   
   *我大意了，AMD也可以x86模拟，之前貌似只是sdk没配好

### 2020/12/27

1. 玩了一天wasm-pack，bug一堆，开了opt之后不能返回string，服了

2. yew还挺好玩的，rust+flutter好像可以写一切，除了生态太差以外还挺有意思的（

3. 跟甲方对线

### 2020/12/28

1. wasm并不是很好用的样子，interface提案好像一直没啥动静，原生类型只有整形和浮点，加别的类型之后直接脑溢血，体积也挺大的。再等两年也许生态会好起来
2. 学计网

