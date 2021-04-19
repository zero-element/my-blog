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

rust练手

rust搓数据结构直接难度+1档，全麻

# 滑动窗口的最大值 

4-8ms 全语言最快 rust巨大nb

```rust
use std::collections::VecDeque;
impl Solution {
    pub fn max_sliding_window(nums: Vec<i32>, k: i32) -> Vec<i32> {
        type Node = (usize, i32);
        let mut result: Vec<i32> = vec![];
        let mut queue: VecDeque<Node> = VecDeque::new();
        nums.into_iter().enumerate().for_each(|(index, value)| {
            if let Some((front_index, _)) = queue.front() {
                if index - *front_index >= k as usize {
                    queue.pop_front();
                }
            }
            while let Some((_, last)) = queue.back() {
                if *last > value {
                    break;
                }
                queue.pop_back();
            }
            queue.push_back((index, value));
            if index >= (k - 1) as usize {
                result.push(queue[0].1);
            }
        });
        result
    }
}
```

# 二叉搜索树的第k大节点

练一下智能指针

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

# 两两交换链表中的节点

```rust
// 递归法
impl Solution {
    pub fn swap_pairs(head: Option<Box<ListNode>>) -> Option<Box<ListNode>> {
      head.and_then(|mut n| {
        match n.next {
          Some(mut m) => {
            n.next = Self::swap_pairs(m.next);
            m.next = Some(n);
            Some(m)
          },
          None => Some(n)
        }
      })
    }
}
```

# 合并k个升序链表

```rust
// 迭代法，append时直接新开node
// 内存大效率低，但逻辑简单
use std::collections::BinaryHeap;
use std::cmp::Reverse;
impl Solution {
    pub fn merge_k_lists(lists: Vec<Option<Box<ListNode>>>) -> Option<Box<ListNode>> {
        let mut heads = Vec::new();
        let mut head: Option<Box<ListNode>> = None;
        let mut tail = &mut head;
        let mut heap = BinaryHeap::new();

        for list in lists.iter() {
            heads.push(list);
        }
        for (index, curHead) in lists.iter().enumerate() {
            if let Some(curNode) = curHead {
                heap.push((Reverse(curNode.val), index));
                heads[index] = &curNode.next;
            }
        }
        while let Some(minPair) = heap.pop() {
            let new_node = Box::new(ListNode::new(minPair.0.0));
            if let Some(curHead) = heads[minPair.1] {
                heads[minPair.1] = &curHead.next;
                heap.push((Reverse(curHead.val), minPair.1));
            }
            if let Some(last) = tail {
                last.next = Some(new_node);
                tail = &mut last.next;
            } else {
                *tail = Some(new_node);
            }
        }
        head
    }
}
```

