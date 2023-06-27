---
layout: post
title:  "你真的会用shared_ptr吗？"
date:   2023-06-27
excerpt: "小心有坑"
image: ""
comments: true
toc: false
tags: Y-2023 c++
---

## 引子

c++里的智能指针`shared_ptr`，设计的初衷是为了方便内存管理和垃圾回收。其通过引用计数机制来自动管理对象引用，当引用计数为0时，触发对象的析构函数，释放相应的内存。

但是你遇到过这样的问题吗，我都使用了智能指针，为什么还是会有`double free or corruption`问题？

## 分析

你说的都没错，但是你可能漏了一个细节。在cppreference关于`shared_ptr`的说明中有下面这么一段话：

>The ownership of an object can only be shared with another shared_ptr by copy constructing or copy assigning its value to another shared_ptr. Constructing a new shared_ptr using the raw underlying pointer owned by another shared_ptr leads to undefined behavior.
>

意思就是说，`shared_ptr`的共享机制只有在拷贝构造以及拷贝赋值时才会传递。如果你通过裸指针构造一个全新的`shared_ptr`，cpp会认为这是一个全新的智能指针，其与之前的智能指针均认为自己为所指对象的唯一owner。

整个例子吧，写一个简单的测试程序，命名为`test_shared_ptr.cc`:

```cpp
#include <iostream>
#include <memory

struct Bad
{
    std::shared_ptr<Bad> getptr()
    {
        return std::shared_ptr<Bad>(this);
    }
    ~Bad() { std::cout << "Bad::~Bad() called\n"; }
};

void testBad()
{
    // Bad, each shared_ptr thinks it's the only owner of the object
    std::shared_ptr<Bad> bad0 = std::make_shared<Bad>();
    std::shared_ptr<Bad> bad1 = bad0->getptr();
    std::cout << "bad1.use_count() = " << bad1.use_count() << '\n';
} // UB: double-delete of Bad
 
int main()
{
    testBad();
}
```

编译一下`g++ -std=c++17 test_shared_ptr.cc -o test`，完了执行一下，看下结果：

```
bad1.use_count() = 1
Bad::~Bad() called
test(71405,0x11bf79e00) malloc: *** error for object 0x7f82c1c05a48: pointer being freed was not allocated
test(71405,0x11bf79e00) malloc: *** set a breakpoint in malloc_error_break to debug
```

说明什么，`bad1`是基于`bad0`所指向的对象指针重新构造的，其`use_count`为1，其认为自己是唯一拥有该`Bad`对象的智能指针。因此，`bad0`和`bad1`都会去析构该`Bad`对象，从而造成重复释放内存的问题。

## 解决方案

整个问题的解决办法很简单，尽可能不要使用裸指针去初始化一个智能指针，或者使用`enable_shared_from_this`，详细使用方法参见cppreference。

## References

1. [**shared_ptr**](https://en.cppreference.com/w/cpp/memory/shared_ptr)
2. [**enable_from_shared_this**](https://en.cppreference.com/w/cpp/memory/enable_shared_from_this)



