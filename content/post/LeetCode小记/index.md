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

# 包含每个查询的最小区间

BinaryHeap和BTreeMap嗯写的离线算法，效率有点拉跨，有功夫试试搓个线段树

```rust
use std::collections::{BinaryHeap, BTreeMap};
use std::cmp::Reverse;

impl Solution {
    pub fn min_interval(intervals: Vec<Vec<i32>>, queries: Vec<i32>) -> Vec<i32> {
        let mut event_heap = BinaryHeap::new();
        let mut seg_num_map: BTreeMap<i32, i32> = BTreeMap::new();
        let mut result: Vec<i32> = (1..=queries.len() as i32).collect();
        for range in intervals {
            let len = range[1] - range[0] + 1;
            event_heap.push((Reverse(range[0]), 2, len));
            event_heap.push((Reverse(range[1]), 0, len));
        }
        for (index, &query) in queries.iter().enumerate() {
            event_heap.push((Reverse(query), 1, index as i32));
        }

        while let Some(event) = event_heap.pop() {
            let len = event.2;
            if event.1 == 2 {
                if let Some(count) = seg_num_map.get_mut(&len) {
                    *count += 1;
                } else {
                    seg_num_map.insert(len, 1);
                }
                continue;
            }
            if event.1 == 1 {
                if let Some(kv) = seg_num_map.iter().next() {
                    result[len as usize] = *kv.0;
                } else {
                    result[len as usize] = -1;
                }
                continue;
            }
            if event.1 == 0 {
                if let Some(count) = seg_num_map.get_mut(&len) {
                    if *count > 1 {
                        *count -= 1;
                    } else {
                        seg_num_map.remove(&len);
                    }
                }
            }
        }
        result
    }
}
```

# 有向图中最大颜色值

懒得优化空间了，开了二维dp

```rust
use std::collections::{VecDeque};
use std::cmp::max;

impl Solution {
    pub fn largest_path_value(colors: String, edges: Vec<Vec<i32>>) -> i32 {
        struct node {
            color: i32,
            next: Vec::<usize>,
            scale: i32,
        }
        let mut nodes: Vec::<node> = colors.chars().enumerate().map(|(index, char)|
            node {
                color: char as i32 - 'a' as i32,
                next: vec![],
                scale: 0,
            }
        ).collect();

        let mut res = 1;
        for edge in edges {
            nodes[edge[0] as usize].next.push(edge[1] as usize);
            nodes[edge[1] as usize].scale += 1;
        }

        let mut deque: VecDeque<usize> = VecDeque::new();
        let mut dp = vec![[0i32; 30]; colors.len()];
        let mut count = 0;

        for index in 0..nodes.len() {
            dp[index][nodes[index].color as usize] = 1;
            if nodes[index].scale == 0{
                deque.push_back(index);
                count += 1;
            }
        }

        while let Some(node_index) = deque.pop_front() {
            for next in nodes[node_index].next.clone() {
                nodes[next].scale -= 1;
                if nodes[next].scale == 0 {
                    deque.push_back(next);
                    count += 1;
                }
                for index in 0..26 {
                    dp[next][index] = max(dp[next][index], dp[node_index][index] + (nodes[next].color == index as i32) as i32);
                    res = max(res, dp[next][index]);
                }
            }

        }

        if count != colors.len() {
            return -1;
        }
        res
    }
}
```

# 高精度加法

```rust
use std::iter;
use std::mem::swap;

impl Solution {
    pub fn add_strings(num1: String, num2: String) -> String {
        let mut iter1 = num1.chars().into_iter().rev();
        let mut iter2 = num2.chars().into_iter().rev();
        //num1 is longer
        if num1.len() < num2.len() {
            swap(&mut iter1, &mut iter2);
        }
        let iter1 = iter1.map(|c| c as i32 - '0' as i32);
        let iter2 = iter2.map(|c| c as i32 - '0' as i32);

        let mut carry = 0;
        let mut result = iter1.zip(iter2.chain(iter::repeat(0))).map(|(a, b)| {
            let mut sum = a + b + carry;
            carry = if sum >= 10 { 1 } else { 0 };
            sum = if sum >= 10 { sum - 10 } else { sum };
            return sum.to_string();
        }).collect::<String>();
        if carry > 0 {
            result.push('1');
        }
        return result.chars().into_iter().rev().collect();
    }
}
```

