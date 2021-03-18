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

