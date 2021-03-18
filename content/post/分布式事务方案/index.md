---
title: "分布式事务方案"
date: 2020-11-08
draft: false
categories: [
  "开发"
]
tags: [
  "分布式"
]
---

[分布式事务常见类型](https://juejin.im/post/6850418108599894023)

[分布式事务取舍](https://jianshu.com/p/917cb4bdaa03)

主要就是这张图

![Saga&Seata&TCC](Saga&Seata&TCC.png)

一致性要求不高，或幂等重试可以保证业务安全的场景可以考虑支持事务的消息队列