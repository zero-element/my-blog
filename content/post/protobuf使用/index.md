---
title: "在Python+Go中使用protobuf"
date: 2020-06-08
description: "记录protobuf在python和Go中的使用和踩坑"
categories: [
  "开发"
]
tags: [
  "Proto",
  "Python",
  "Golang"
]
---

# Protobuf3

### 数据类型

| proto    | 注释                                                         | Go        | Python                 |
| :------- | :----------------------------------------------------------- | :-------- | :--------------------- |
| double   |                                                              | float64   | float                  |
| float    |                                                              | float32   | float                  |
| int32    | 编码长度是可变的，不能用于编码负数。如果要用于负数，应当使用sint32 | int32     | int                    |
| int64    | 类似int32,应当使用sint64编码负数                             | int64     | int/log                |
| uint32   | 变长编码                                                     | uint32    | int/long               |
| uint64   | 变长编码                                                     | uint64    | int/long               |
| sint32   | 变长编码                                                     | int32     | int                    |
| sint64   | 变长编码                                                     | int64     | int/long               |
| fixed32  | 4字节，比uint32更适合编码超过2^28的数字                      | uint32    | int/long               |
| fixed64  | 8字节，2^56                                                  | uint64    | int/long               |
| sfixed32 | 4字节                                                        | int32     | int                    |
| sfixed64 | 8字节                                                        | int64     | int/long               |
| bool     |                                                              | bool      | bool                   |
| string   | 必须是UTF-8编码或是7bit的ASCII                               | string    | unicode(Py2), str(Py3) |
| bytes    | 可以包含任意byte序列                                         | []byte    | bytes                  |
| enum     | 可以包含一个用户自定义的枚举类型uint32                       | N(uint32) | enum                   |
| message  | 可以包含一个用户自定义的消息类型                             | N         | object of class        |

### 基本语法（3.0）

protobuf3中首行必须声明版本，如下

```protobuf
syntax = "proto3";
package protoc;

message Pics {
    message Picture {
        int32 id = 1;
        string location = 2;
        bytes pic_data = 3;
    }
    repeated Picture pic = 1;
}
```

语法说明：

1. [修饰符]

   - singular：表示该字段出现0/1次，为可选字段。protobuf3中singular为默认修饰符，无需自行声明。
   - repeated：表示该字段可以重复任意多次（包括0次）。重复的值的顺序会被保留。用于储存数组（在go中转换为切片，在python中转换为list），注意与oneof关键字不兼容。

   注意protobuf3中取消了required，所有字段均默认singular，并取消了default，缺省值由语言和数据类型自动决定，因此需要注意处理缺省值。

2. 字段类型

   具体数据类型参考数据类型表格，可以使用any表示任意类型但不推荐使用，避免类型混乱。

   支持在message内部嵌套定义message（会被反映为嵌套数据结构），也可以使用自定义的message类型。

3. 字段名称

   建议使用下划线命名规范，message表示新声明的类型，字段名称首字母使用大写。

4. 字段编码值

   用于标识字段顺序，编码值使用动态长度储存，建议使用1~15的编码值存放高频字段，占用空间较少。

### 安装

##### Windows

1. 前往github下载已编译的对应版本，或自行编译：[release](https://github.com/protocolbuffers/protobuf/releases)
2. 下载protoc-xxx-win64.zip，解压bin/protoc.exe
3. 将protoc所在目录添加至path
4. 命令行测试`protoc --version`是否成功

##### Linux

1. 同理，下载protobuf二进制文件/源码

2. 编译

   ```shell
   tar -xvf protobuf
   cd protobuf
   ./configure --prefix=/usr/local/protobuf
   make
   make check
   make install
   ```

3. 添加至path

   ```shell
   vim /etc/profile
   在文件的末尾添加如下的两行:
   export PATH=$PATH:/usr/local/protobuf/bin/
   export PKG_CONFIG_PATH=/usr/local/protobuf/lib/pkgconfig/
   ```

4. 命令行测试`protoc --version`是否成功

## 在Python中使用

### 安装python包

- 直接使用pip安装

  ```shell
  pip install protobuf
  ```

- 或者在release中下载对应python版本，手动安装

  ```shell
  python setup.py build
  python setup.py install
  python setup.py test
  ```

### 生成pb2.py文件

protoc用法：

```shell
protoc -I=$SRC_DIR --python_out=$DST_DIR $SRC_DIR/*.proto
```

`--xxx_out`表示生成对应语言的proto定义文件

运行后会在`$DST_DIR`下生成`xxx_pb2.py`文件，使用时直接`import`即可

### 在Python中调用

一些使用测试

```
pics = pics_pb2.Pics()
pic1 = pics.pic.add()
pic1.id = 1
pic1.location = 'loooooocation'
pic1.pic_data = 'daaaaaaaaaaaaaaaaata'.encode('utf-8')
pic2 = pics.pic.add()
print(pics)
ser = pics.SerializeToString()
pics_ = pics_pb2.Pics()
pics_.ParseFromString(ser)
with open("test.txt", "wb") as f:
    f.write(ser)
```

对于自定义的message类型，可以使用`.add()`初始化

## 在Go中使用

### 安装Go包

直接使用go get拉取

```shell
go get -u github.com/Go/protobuf/{protoc-gen-go,proto}
```

### 生成pb.go文件

使用protoc：

```shell
protoc -I=$SRC_DIR --go_out=$DST_DIR $SRC_DIR/*.proto
```

运行后会在`$DST_DIR`下生成`xxx.pb.go`文件，同样在使用时直接`import`导入

### 在Go中调用

##### 向repeated中添加数据

go中对类型限定非常非常非常严格，除了依次append，似乎没有找到很好的方法

```go
protocResp.Pic = append(protocResp.Pic, &protoc.Pics_Picture{
	Id: int32(pic.ID), Location: pic.Location.Name, PicData: buffer})
}
```

~~个人感觉感觉go语法的很多限制实属呆板过头了，弊大于利~~

##### 官方demo

```go
in, err := ioutil.ReadFile(fname)
if err != nil {
        log.Fatalln("Error reading file:", err)
}
book := &pb.AddressBook{}
if err := proto.Unmarshal(in, book); err != nil {
        log.Fatalln("Failed to parse address book:", err)
}
```