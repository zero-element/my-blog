---
title: "Rust学习记录"
date: 2020-10-12
description: "泛型好文明，错误处理好文明，总之Go坏文明（逃"
categories: [
  "开发"
]
tags: [
  "Rust"
]
---

# 环境配置

### IDE选择

~~菜鸟教程害人不浅~~

上手发现各种教程博客都用的是vscode，但是细细一看眉头一皱，发现事情并不简单。

vscode里的`rust language server`，可以说是这么多语言里第一个让我觉得难用的：没有snippet，不能自动配置`task.json`和`launch.json`，甚至使用`MSVC`工具链调试的时候会有神秘错误，原因是rls自动生成了一个随机的调试路径，但是没有把MSVC中的库自动拷贝过去。

虽然可以在`lauch.json`中配置map映射相关目录，但是由于无法预测rls自动生成的哈希目录名，这种做法也只能在第一次报错之后，针对报错路径进行相应配置。

甚至调试的时候还会自动把`println!`宏展开（貌似）。

这些bug在github上的issue已经有一年多了，仍然处于open没有修复。生态可以说是很差了，不知道为什么那么多教程推荐vscode。

**最后吃了室友的安利去试了下`CLion`，自带rust插件，类型推断体验极佳，写起来十分丝滑，好评。**

[Clion下载](https://www.jetbrains.com/clion/download/download-thanks.html)

[JetBrains全家桶注册补丁](https://github.com/2293736867/JetBrainsActivation)

### 工具链配置

因为主力环境是在win下，初步使用来看`GNU`调试的时候似乎容易跳进汇编里，`MSVC`出现的问题相对更少，所以默认使用的是`MSVC`工具链，可以在使用`rustup‑init.exe`安装工具链的时候直接选好。

当然如果某个项目需要切换到GNU的时候可以用`rustup`为这个项目单独指定工具链。

```powershell
rustup install stable-x86_64-pc-windows-gnu 		#如果没装gnu的话初次进行安装
rustup override set stable-x86_64-pc-windows-gnu

#可以查看rustup支持的编译链
rustup target list
```

编译和调试环境`CLion`都会自动配置，一键运行非常丝滑。

### cargo换源

打开`$HOME/.cargo`，创建`config`文件（无后缀），配置清华源

```ini
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
```

# 语法和概念

基本语法类C，可速览菜鸟教程（不要细看

以下大致是对[rust圣经](http://120.78.128.153/rustbook/ch03-01-variables-and-mutability.html)的一些总结

### 基本语法

1. 变量通过`let`关键字声明且默认不可变，可变变量需要使用`let mut`声明

   不可变变量与常量区别在于，变量可以接受表达式进行赋值

2. 除基础数据类型，有数组（支持切片），元组（支持解构赋值），vector等

3. 支持箭头函数，嵌套定义函数，**代码块以结尾无分号语句作为返回值**

   ```rust
   let y = {
       let x = 3;
       x + 1
   };
   //y=4
   fn plus_one(x: i32) -> i32 {
       x + 1
   }
   //plus_one(5)=6
   ```

4. if和loop可视为表达式用于对变量赋值，loop用于无限循环，其中break可接受传值作为表达式的返回值，for类python用于遍历迭代器，while类C

   loop:

   ```rust
   fn main() {
       let mut counter = 0;
      
       let result = loop {
           counter += 1;
      
           if counter == 10 {
               break counter * 2;	// break提供代码块的返回值直接赋值到变量，简化代码流程
           }
       };
      
       println!("The result is {}", result);
   }
   ```

   if:

   ```rust
   // 需要确保if所有分支返回类型相同
   fn main() {
       let condition = true;
       let number = if condition { // 直接赋值，简化代码结构，文雅
           5
       } else {
           6
       };
      
       println!("The value of number is: {}", number);
   }
   ```

   for（不能作为代码块返回值）:

   ```rust
   fn main() {
       for (index, number) in (1..4).rev().enumerate() { 	// (1..4)生成一个Range，enumerate生成带有index的tuple
                                                           // 不需要index时可以直接 for number in (1..4)
           println!("{} number: {}!", index, number);
       }
       println!("LIFTOFF!!!");
   }
   ```

5. 结构体

   ```rust
   #[derive(Debug)] // 自动添加Debug trait，该trait用于支持fmt中格式化和打印方法，便于输出结构体内容
   struct Rectangle {
       width: u32,
       height: u32,
   }
      
   impl Rectangle {
       fn area(&self) -> u32 { // self不是必须的，只有返回值是Rectangle也可以放在impl里声明（只要与这个结构体相关），没有self的时候自动作为普通函数
                               // &self表示引用，防止所有权的转移，详见“内存模型”
           self.width * self.height
       }
   }
      
   fn main() {
       let rect1 = Rectangle { width: 30, height: 50 };
      
       println!(
           "The area of the rectangle is {} square pixels.",
           rect1.area()
       );
       format!("The rect1 is: {:?}", rect1);  // Debug实现的序列化打印，{:#?}可自动换行格式化
   }
   ```

6. Vector

   HashMap

   ```rust
   use std::collections::HashMap;
      
   let text = "hello world wonderful world";
      
   let mut map = HashMap::new();
      
   for word in text.split_whitespace() {
       let count = map.entry(word).or_insert(0); // or_insert不存在时插入
       *count += 1;                              // count取得v的可变引用（见下），*count取得对象可以直接赋值修改
   }
      
   println!("{:?}", map);
   ```

7. trait（特性），类似于Go和Java的interface加强版

   不只是函数参数，几乎有泛型的地方都可以用trait条件进行限制（指定返回值需要的trait，对实现了指定trait的类型声明方法），还可以对trait进行组合（类似于多重继承的作用）

   ```rust
   use std::fmt::Display;
      
   struct Pair<T> {
       x: T,
       y: T,
   }
      
   impl<T> Pair<T> {
       fn new(x: T, y: T) -> Self {
           Self {
               x,
               y,
           }
       }
   }
      
   impl<T: Display + PartialOrd> Pair<T> { // 对实现了Display和PartialOrd方法的特定类型T，实现Pair<T>的trait
       fn cmp_display(&self) {
           if self.x >= self.y {
               println!("The largest member is x = {}", self.x);
           } else {
               println!("The largest member is y = {}", self.y);
           }
       }
   }
   ```

### 内存模型

##### 所有权

为了保证内存和线程安全，rust提出了所有权的内存模型，基本规则如下

> 1. Rust 中的每一个值都有一个被称为其**所有者**（*owner*）的变量。
> 2. 值在任一时刻有且只有一个所有者。
> 3. 当所有者（变量）离开作用域，这个值将被丢弃。

~~就很像锁~~

1. 对于整数等基本类型，由于内存长度确定且长度较短，拷贝时开销较小，所以执行`let b = a;`时rust会直接在栈上进行深拷贝得到两个相同的值，这两个值的所有权分别由变量a和b持有。执行这类操作的基本类型称为`Copy`的 ，只包含`Copy`类型的元组也是`Copy`的。

   对于string这样的变长类型，与python类似，rust将会把b的指针指向a指向的数据。但不同之处在于，为了遵守**规则2**，变量a将会被作废，也就是交出这段数据的所有权，将其转移给b。这可以防范a和b同时具备所有权（指针）时，析构时发生`double free`的问题。

2. 类似于赋值语句，向函数传递值或者从函数返回可能会发生所有权的移动或者复制。

   传值和返回中的所有权转移过程：

   ```rust
   fn main() {
       let s1 = gives_ownership();         // gives_ownership 将返回值
                                           // 移给 s1
      
       let s2 = String::from("hello");     // s2 进入作用域
      
       let s3 = takes_and_gives_back(s2);  // s2 被移动到
                                           // takes_and_gives_back 中,
                                           // 它也将返回值移给 s3
      
       let x = 5;                      	// x 进入作用域
      
       makes_copy(x);                  	// x 应该移动函数里，但i32是Copy的，所以在后面可继续使用x
   } // 这里, s1和s3移出作用域并被丢弃。s2也应当移出作用域，但传参时已被移走，所以什么也不会发生。
     // x传参时被拷贝，x本身仍然持有所有权，所以这里被移出作用域并丢弃
      
   fn gives_ownership() -> String {             // gives_ownership 将返回值移动给
                                                // 调用它的函数
      
       let some_string = String::from("hello"); // some_string 进入作用域.
      
       some_string                              // 返回 some_string 并移出给调用的函数
   }
      
   // takes_and_gives_back 将传入字符串并返回该值
   fn takes_and_gives_back(a_string: String) -> String { // a_string 进入作用域
      
       a_string  // 返回 a_string 并移出给调用的函数
   }
      
   fn makes_copy(some_integer: i32) { // some_integer 进入作用域
       println!("{}", some_integer);
   } // 这里，some_integer 移出作用域。不会有特殊操作
   ```

通过所有权的设计，rust保证了一段内存中的数据只能由一个变量进行操作（仅基于上面的三条规则而言是这样），相当于是在语法的层面上提供了天然的锁，解决了并发时的各种问题，但是这种限制也带来了很大的麻烦。

当一个string被传入函数后就失去了所有权，如果在下文中想要继续使用这个string就会很麻烦，比如这样：

```rust
fn main() {
    let s1 = String::from("hello");

    let (s2, len) = calculate_length(s1);

    println!("The length of '{}' is {}.", s2, len);
}

fn calculate_length(s: String) -> (String, usize) {
    let length = s.len(); // len()返回字符串的长度

    (s, length) // 返回时把s和length作为元组打包，将所有权转移回调用处的上下文
}
```

所以rust又整出了**引用**与**借用**

##### 引用与借用

```rust
fn main() {
    let s1 = String::from("hello");

    let len = calculate_length(&s1);

    println!("The length of '{}' is {}.", s1, len);
}

fn calculate_length(s: &String) -> usize { // s 是对 String 的引用
    s.len()
} // 这里，s离开了作用域。但因为它并不拥有引用值的所有权，
  // 所以什么也不会发生
```

这些&符号称为**引用**，它们允许你使用值但不获取其所有权；获取引用作为函数参数称为**借用**。

~~其实就是只读锁~~

~~所以相应就会有写锁~~

能够进行修改的引用被称为**可变引用**

```rust
fn main() {
    let mut s = String::from("hello");

    change(&mut s);
}

fn change(some_string: &mut String) {
    some_string.push_str(", world");
}
```

和写锁类似，同一个作用域内只能存在一个可变引用，而且为避免脏读，可变引用也不能和普通引用共存（写锁和读锁冲突），但是要注意一点

> 引用的作用域从声明的地方开始一直持续到最后一次使用为止

所以这样是没问题的

```rust
let mut s = String::from("hello");

let r1 = &s; // 没问题
let r2 = &s; // 没问题
println!("{} and {}", r1, r2);
// 此行之后 r1 和 r2 不再使用

let r3 = &mut s;// 没问题
println!("{}", r3);

// 但是加一行
let r4 = &s;	// 就会出大问题，r3和r4冲突
```

##### slice

切片就是一种特殊的引用，只是指定了引用的范围

返回字符串第一个空格前单词

```rust
fn first_word(s: &String) -> &str {
    let bytes = s.as_bytes();

    for (i, &item) in bytes.iter().enumerate() {
        if item == b' ' {
            return &s[0..i]; // rust中切片不持有所有权，所有权仍处于调用者的上下文，所以也只读
        }
    }

    &s[..]
}
```

实际上字符串字面值被储存在二进制文件中，当使用字符串常量赋值时，变量的类型就是一个全长的切片，不具有真正的字面量的生命周期。

##### 生命周期

在上面的各种例子中可以看到，我们调用函数的时候往往会传入引用，而返回值也经常直接是某个被传入的引用。

这在返回值是某个确定的引用时不会有什么问题，rust可以自动推断相关变量的作用域，比如这样会报错：

```rust
fn main()
{
    let r;

    {
        let x = 5;
        r = test(&x);
    }
    println!("r: {}", r); // x已经离开了作用域，r是x的引用，使用相同的作用域
}

fn test(x: &i32) -> &i32 {
    x
}
// 报错:borrowed value does not live long enough
```

但如果返回值取决于分支条件，存在多种可能时，这时候rust就无法进行自动推断了，比如这段代码编译时会报错：

```rust
fn longer(s1: &str, s2: &str) -> &str {
    if s2.len() > s1.len() {
        s2
    } else {
        s1
    }
}
// 提示:this function's return type contains a borrowed value, but the signature does not say whether it is borrowed from `x` or `y`
```

因为返回值是运行期决定的，rust不知道返回值的生命周期需要取决于x还是y，

这时候就需要添加生命周期注解，手动指定这两个参数x和y的作用域关系

```rust
/// &i32        // 引用
/// &'a i32     // 带有显式生命周期的引用
/// &'a mut i32 // 带有显式生命周期的可变引用
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str { // 这样就规定了传入的x和y必须具备相同的作用域，返回值也使用作用域a，即等同于x和y
    if x.len() > y.len() {
        x
    } else {
        y
    }
}
```

泛型、特性与生命周期结合

```rust
use std::fmt;

struct A {
    key: String,
}

impl fmt::Display for A {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "Display: {}", self.key)
    }
}

fn main() {
    let str1 = "string";
    let str2 = "string2";
    let ann = A { key: String::from("the key") };
    println!("{}", longest_with_an_announcement(&str1, &str2, ann));
}


/// 只接受实现了Display的类型，编译期检查
/// 可以用where语句把限定现在结尾，如
/// fn xxx<T>(xxx) -> xxx where T: fmt::Display
fn longest_with_an_announcement<'a, T: fmt::Display>(x: &'a str, y: &'a str, ann: T) -> &'a str
{
    println!("Announcement! {}", ann);
    if x.len() > y.len() {
        x
    } else {
        y
    }
}
```

##### 智能指针

拿一道leetcode题作为例子：[二叉搜索树的第k大节点](https://leetcode-cn.com/problems/er-cha-sou-suo-shu-de-di-kda-jie-dian-lcof/)

```rust
#[derive(Debug, PartialEq, Eq)]
pub struct TreeNode {
    pub val: i32,
    pub left: Option<Rc<RefCell<TreeNode>>>,
    pub right: Option<Rc<RefCell<TreeNode>>>,
}

impl TreeNode {
    #[inline]
    pub fn new(val: i32) -> Self {
        TreeNode {
            val,
            left: None,
            right: None,
        }
    }
}

impl Solution {
    pub fn search(root: Option<Rc<RefCell<TreeNode>>>, k: i32, count: &mut i32, ans: &mut i32) {
        if let Some(root) = root {
            let root = root.borrow();
            Self::search(root.right.clone(), k, count, ans);
            *count += 1;
            if *count == k {
                *ans = root.val;
            }
            Self::search(root.left.clone(), k, count, ans);
        }
    }

    pub fn kth_largest(root: Option<Rc<RefCell<TreeNode>>>, k: i32) -> i32 {
        let mut count = 0;
        let mut ans = 0;
        Self::search(root, k, &mut count, &mut ans);
        return ans;
    }
}
```



# 复杂一点的栗子

### 常用语法

猜随机数小游戏

```rust
extern crate rand;  //导入rand包，import->extern&&package->crate
                    //起到use std::rand作用，引入namespace
use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guess the number!");                            // 输出字符串常量

    let secret_number = rand::thread_rng().gen_range(1, 101); // let声明的变量是不可修改的，但是可以let同名变量进行覆盖；与常量区别在于可以赋予表达式

    loop {                                                    // 无限循环，手动break
        println!("Please input your guess.");

        let mut guess = String::new();                        // let声明的变量是静态的，需要加mut关键字才能动态修改

        io::stdin().read_line(&mut guess)                     // read_line返回Result类型，类似k-v，其中k可枚举：Ok表成功，Err表失败，v传递返回值或错误类型——这里使用Result.expect()直接对Err抛出panic
            .expect("failed to read line");

        let guess: u32 = match guess.trim().parse() {         // 使用match匹配Rusult类型
            Ok(num) => num,                                   // 箭头函数，用法类似es6
            Err(_) => continue,
        };

        println!("You guessed: {}", guess);                   // println!本质是宏，展开后变为引用，不存在所有权转移的问题

        match guess.cmp(&secret_number) {                     // 匹配结果
            Ordering::Less    => println!("Too small!"),
            Ordering::Greater => println!("Too big!"),
            Ordering::Equal   => {
                println!("You win!");
                break;
            }
        }
    }
}

// 注意编辑./target/Cargo.toml添加依赖
[dependencies]
rand = "0.5.5"
```

### 并发：简单的WebServer

src/bin/main.rs

```rust
use hello::ThreadPool; // hello是项目名，由Cargo.toml指定，ThreadPool是自行实现的一个简易线程池

use std::io::prelude::*;
use std::net::TcpListener;
use std::net::TcpStream;
use std::fs;
use std::thread;
use std::time::Duration;

fn main() {
    let listener = TcpListener::bind("127.0.0.1:7878").unwrap(); // 返回err时，unwrap直接抛出panic
    let pool = ThreadPool::new(4);

    for stream in listener.incoming().take(2) { // 只取前两个iter，进行两次测试，否则无限循环
        let stream = stream.unwrap();
        pool.execute(|| { // 闭包，功能上类似于具有调用者作用域的匿名函数（实际上闭包只是捕获环境中的变量，具体的所有权关系转移较为复杂，大多数情况下由rust自动推断处理，详见圣经13.1）
                          // 形式上在竖线中声明参数，比如
                          // let add_one_v1 = |x: u32| -> u32 { x + 1 };
                          // 类型注解可以省略，代码块只有一行时可以省略大括号（和es6基本相似）
                          // 所以可以省略成这样
                          // let add_one_v2 = |x| x + 1;
                          // 这里参数为空所以是||
            handle_connection(stream);
        });
    }

    println!("Shutting down.");
}

fn handle_connection(mut stream: TcpStream) {
    let mut buffer = [0; 512];
    stream.read(&mut buffer).unwrap();

    let get = b"GET / HTTP/1.1\r\n";
    let sleep = b"GET /sleep HTTP/1.1\r\n";

    let (status_line, filename) = if buffer.starts_with(get) {
        ("HTTP/1.1 200 OK\r\n\r\n", "hello.html")
    } else if buffer.starts_with(sleep) {
        thread::sleep(Duration::from_secs(5));
        ("HTTP/1.1 200 OK\r\n\r\n", "hello.html")
    } else {
        ("HTTP/1.1 404 NOT FOUND\r\n\r\n", "404.html")
    };

    let contents = match fs::read_to_string(filename) {
        Ok(content) => content,
        Err(_) => "File not Found"
    };

    let response = format!("{}{}", status_line, contents);

    stream.write(response.as_bytes()).unwrap();
    stream.flush().unwrap();
}
```

src/lib.rs

cargo约定lib.rs作为库文件的根（入口）

如果要分割模块，将模块内容放在src/xxx.rs，然后再lib.rs中mod xxx即可引入

```rust
use std::thread;
use std::sync::mpsc;
use std::sync::Arc;
use std::sync::Mutex;

enum Message {
    NewJob(Job),	// 支持动态的枚举类型，传递任务信息
    Terminate,		// 终止信号
}

pub struct ThreadPool {
    workers: Vec<Worker>,
    sender: mpsc::Sender<Message>,	// 保存channal的producer，用于给线程通信
}

type Job = Box<dyn FnOnce() + Send + 'static>; /// 智能指针，指向堆上数据，仅允许单一持有者
                                               /// 相应的，Rc<>支持多个持有者，通过引用计数智能释放
                                               /// Rc和Box都是不可变引用，RefCell支持可变引用，但仅允许单一持有者
                                               /// dyn用于消除歧义，表明该trait为动态分发（类似CPP虚表）
											   /// FnOnce指定trait，这里是闭包类型的一种（详见圣经10.2），Send为需要的方法，'static为生命周期

impl ThreadPool {
    /// 创建线程池。
    ///
    /// 线程池中线程的数量。
    ///
    /// # Panics
    ///
    /// `new` 函数在 size 为 0 时会 panic。
    pub fn new(size: usize) -> ThreadPool {
        assert!(size > 0);

        let (sender, receiver) = mpsc::channel();       // 创建channel，解构赋值

        let receiver = Arc::new(Mutex::new(receiver));  // Arc为Rc的线程安全版，使用原子化的引用计数，提供线程安全的多所有权；Mutex本质也是智能指针，提供lock方法对变量加锁，同时为Arc带来了可变性
                                                        // 注意Rc不能避免循环引用，Mutex也不能规避死锁

        let mut workers = Vec::with_capacity(size);     // 创建线程池，workers类型由rust自动推断

        for id in 0..size {
            workers.push(Worker::new(id, Arc::clone(&receiver)));
        }

        ThreadPool {
            workers,
            sender,
        }
    }

    pub fn execute<F>(&self, f: F)
        where
            F: FnOnce() + Send + 'static                      // 指定接受FnOnce类型的闭包
    {
        let job = Box::new(f);                                // 对闭包的只能指针，此时f作用域存在于当前上下文，通过智能指针向线程传入其不可变引用

        self.sender.send(Message::NewJob(job)).unwrap();      // 向线程通信，所有线程均持有reciver但Arc保证其线程安全，只会被消费一次
    }
}

impl Drop for ThreadPool {
    fn drop(&mut self) {                                      // 析构函数，离开作用域时自动调用，rust禁止手动调用——否则会发生double free
        println!("Sending terminate message to all workers.");

        for _ in &mut self.workers {                          // 发送n次Terminate信号，保证销毁n个线程
            self.sender.send(Message::Terminate).unwrap();
        }

        println!("Shutting down all workers.");

        for worker in &mut self.workers {
            println!("Shutting down worker {}", worker.id);

            if let Some(thread) = worker.thread.take() {
                thread.join().unwrap();
            }
        }
    }
}

struct Worker {
    id: usize,
    thread: Option<thread::JoinHandle<()>>,
}

impl Worker {
    fn new(id: usize, receiver: Arc<Mutex<mpsc::Receiver<Message>>>) ->
        Worker {

        let thread = thread::spawn(move ||{
            loop {
                let message = receiver.lock().unwrap().recv().unwrap(); // recv阻塞等待
                                                                        // try_recv不会阻塞，相反它立刻返回一个 Result<T, E>

                match message {
                    Message::NewJob(job) => { // 执行传入的闭包
                        println!("Worker {} got a job; executing.", id);

                        job();
                    },
                    Message::Terminate => {   // 退出自旋循环
                        println!("Worker {} was told to terminate.", id);

                        break;
                    },
                }
            }
        });

        Worker {
            id,
            thread: Some(thread),
        }
    }
}
```

