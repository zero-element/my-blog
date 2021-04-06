---
title: "WASM踩坑实践"
date: 2020-12-27T21:25:34+08:00
draft: false
categories: [
  "开发"
]
tags: [
  "wasm"
]
---

# wsam-pack

wasm-pack: 0.9.1

return类型为String时，开启wasm-opt会报错

解决方案：

修改cargo.toml,添加

```toml
[package.metadata.wasm-pack.profile.dev]
wasm-opt = ["-Os", "--enable-mutable-globals"]

[package.metadata.wasm-pack.profile.release]
wasm-opt = ["-Os", "--enable-mutable-globals"]
```

# Yew模板

唯一好用：[yew-wasm-pack-template](https://github.com/yewstack/yew-wasm-pack-template)

其他模板都或多或少有些问题，比如windows下编译产生.cache，需要手动删除+重新编译，进而导致不能热更新等等

# 编译优化尺寸

修改cargo.toml,添加

```toml
[profile.release]
lto = true
#或使用'z'
opt-level = 's' 
```

返回尽量使用静态字符串，动态类型会产生巨量胶水