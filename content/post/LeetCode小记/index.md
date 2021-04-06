---
title: "LeetCode小记"
date: 2021-04-07T01:01:29+08:00
draft: false
categories: [
  "开发"
]
tags: [
  "Rust"
]
---

rust练手+康复一些基础算法

# 滑动窗口的最大值 

4ms 测了一下全语言最快 rust巨大nb

```rust
impl Solution {
    pub fn max_sliding_window(nums: Vec<i32>, k: i32) -> Vec<i32> {
        type Node = (usize, i32);
        let mut result: Vec<i32> = vec![];
        let mut queue: Vec<Node> = vec![];
        nums.into_iter().enumerate().for_each(|(index, value)| {
            if let Some((front_index, _)) = queue.first() {
                if index - *front_index >= k as usize {
                    queue.remove(0);
                }
            }
            while let Some((_, last)) = queue.last() {
                if *last > value {
                    break;
                }
                queue.pop();
            }
            queue.push((index, value));
            if index >= (k - 1) as usize {
                result.push(queue[0].1);
            }
        });
        result
    }
}
```

# 二叉搜索树的第k大节点

实践一下智能指针

```rust
use std::rc::Rc;
use std::cell::RefCell;
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

