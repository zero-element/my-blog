---
title: "Electron通过napi调用C代码总结"
date: 2021-03-19
description: "被历史遗留打得满头包，总之就是体验极差"
categories: [
  "开发"
]
tags: [
  "Node.js"
]
---

**千万不要使用ffi-api系列package，即使ffi-api#node-12分支也无法在electron上使用**

~~第一次尝试windows下编译ffi-napi时报错，遂被ffi-api#node-12继续蒸发一整天~~

~~第三天出现了MSVC相关pull request，全麻~~

# 环境搭建

项目环境：Electron 9 + Node 14

如果编译环境齐全，直接npm安装相关包

```shell
npm install ffi-napi ref-napi ref-array-napi ref-struct-napi
```

所需编译环境参考：[node-gyp](https://github.com/TooTallNate/node-gyp#installation)

# 相关用例

C头文件结构体及导出函数

```c
typedef struct {
    int len;
    double cost;
    int sids[50];
} Result;
typedef struct {
    double time[2];
} douTime;

_declspec(dllexport) void Init();
_declspec(dllexport) void GetResult(int fromUid, int fromSid, int toUid, int type, double time, Result *r);
_declspec(dllexport) void SetFactor(int lineId, double newFactor, double limit);
_declspec(dllexport) void GetArriveTime(int sid, double time, int cur, douTime *result);
```

贴出项目代码作为用例，囊括了大多数使用场景

```javascript
const ffi = require('ffi-napi')
const ref = require('ref-napi')
const refArray = require('ref-array-napi')
const Struct = require('ref-struct-napi')

const Result = Struct({
  len: ref.types.int,
  cost: ref.types.double,
  sids: refArray(ref.types.int, 50)
})
const ResultArray = refArray(Result)
const douTime = Struct({
  time: refArray(ref.types.double, 2)
})

export const dll = ffi.Library('algorithm', {
  Init: ['void', []],
  SetFactor: ['void', ['int', 'double', 'double']],
  GetResult: ['void', ['int', 'int', 'int', 'int', 'double', ResultArray]],
  GetArriveTime: ['void', ['int', 'double', 'int', ref.refType(douTime)]]
})

export function Init () {
  dll.Init()
}

export function GetResult (fromUid, fromSid, toUid, type, time) {
  const res = new ResultArray(2)
  dll.GetResult(fromUid, fromSid, toUid, type, time, res)
  return res
}

export function SetFactor (lineId, newFactor, limit) {
  dll.SetFactor(lineId, newFactor, limit)
}

export function GetArriveTime (sid, time) {
  const dTimePointer = ref.alloc(douTime)
  dll.GetArriveTime(sid, time, 1, dTimePointer)
  return dTimePointer.deref()
}
```

