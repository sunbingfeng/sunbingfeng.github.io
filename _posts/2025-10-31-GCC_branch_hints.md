---
toc: true
layout: post
title:  "探究编译器的branch prediction"
date:   2025-10-31
excerpt: "unlikely/likely"
image: ""
comments: true
toc: true
tags: tips
---

> 本文是AI Chat系列文章的第12篇，探究性能优化的小tips。

## Introduction

在嵌入式平台上，由于资源/算力都很紧张，性能优化是家常便饭的事情。今天我们来探讨一下针对`if-else`代码的优化，我们讨论的主题就是`likely/unlikely`这一对编译器提供的branch prediction hints。下面废话不多说，开撸。

## What's likely/unlikely?

在介绍这一对兄弟之前，我们先看一个简单的`if-else`分支代码，如果`condition`为true，我们执行`do1`的操作，否则执行`do2`的操作:

```c
if (condition){
    do1();
}
else{
    do2();
}
```

一般情况下，编译器在编译链接的时候，`do1`的汇编代码会放在`do2`的前面。如果`condition`确实大部分情况都为true，那么顺序执行`do1`不会造成指令缓存失效。但是如果说`condition`大部分情况都是false，那么就会造成指令缓存失效的问题，这个时候需要重新加载do2的指令到缓存中。这样带来的问题是，CPU的I-Cache命中率低，其需要频繁的加载新的指令块，因此执行效率变低了。

缓存命中，说白了就是一个概率问题。谁的执行几率更高，我们就把它的执行代码放到前面。说到这，我们很自然的就想到了一个办法。我们程序员很清楚代码的执行逻辑，他是能分析出`condition`为真的可能性有多大的。如果`condition`为真的可能性较低，那么我们告诉编译器将`do2`的汇编代码放到前面。没错，这就是`likely/unlikely`干的事情。

下面就是一个常规的定义，其本质上是调用了编译器的相关编译指令，比如GCC的`__builtin_expect`: 

```c
/* Branch prediction hints for GCC/Clang */
#ifndef likely
  #define likely(x)   __builtin_expect(!!(x), 1)
#endif
#ifndef unlikely
  #define unlikely(x) __builtin_expect(!!(x), 0)
#endif
```

`likely`就是告诉编译器，`x`大概率是真的；同理，`unlikely`就是说`x`大概率是假的。比如我们上面的例子，我们加入`unlikely`来修饰`condition`，这样编译器就可以针对性的调整汇编代码链接顺序了。

```c
if (unlikely(condition)){
    do1();
}
else{
    do2();
}
```

这里特别指出，现在的编译器已经很智能了，就算不手动加入prediction hints，也都支持智能branch prediction。但是在很多嵌入式平台上这个支持的不是很好，因此手动添加prediction hints还是有收益的。

## Performance boost up

那么加入这个修饰，在嵌入式平台上有多大的性能提升呢？下面，我们让AI帮我们写一个benchmark来测试一下。

具体的过程就不说了，下面给出其用来对比测试的函数本体：

```c
/**
 * Test 2: With unlikely() hint
 * Same logic, but compiler optimizes for the hot path
 */
uint32_t test_with_unlikely(uint32_t iterations)
{
    uint32_t sum = 0;
    uint32_t error_count = 0;
    
    for (uint32_t i = 0; i < iterations; i++) {
        // Hot path - normal data processing
        sum += i;
        sum = (sum & 0xFFFF) + (sum >> 16);  // Checksum-like operation
        
        // Rare condition with unlikely() hint
        if (unlikely((i & 0x3FF) == 0)) {
            // Cold path - placed out-of-line by compiler
            handle_error_condition(&sum, i);
            error_count++;
        }
        
        // Another rare check with unlikely() hint
        if (unlikely(g_debug_mode)) {
            debug_dump_data(&sum, i);
        }
    }
    
    g_result = sum;
    return error_count;
}
```

上面的例子中，`for`循环执行很多次，`i`每隔1024次执行`handle_error_condition`的逻辑。因为`g_debug_mode`始终为false，`debug_dump_data`的逻辑从来都不会执行。就这样的一个例子，我们来跑一下benchmark执行10000000次，看一下加入unlikely究竟有多大的性能提升。

| Test | Configuration | Result | Time (seconds) | Rate (M iterations/sec) |
|------|---------------|--------|----------------|-------------------------|
| 1 | WITHOUT hints (baseline) | 9766 | 3.0530 | 3.28 |
| 2 | WITH unlikely() hint | 9766 | 2.7230 | 3.67 |

**Performance Improvement:**
- Time reduction: 10.8% (3.0530s → 2.7230s)
- Speed increase: 11.9% (3.28 → 3.67 M iterations/sec)

从上面的表格可以看出，加入了`unlikely`提示后，benchmark耗时降低了10%左右。小小的一个动作带来的收益确不错，可喜可贺。

## Assembly analysis

针对加入了prediction hints的代码，我们分析一下其生成的汇编代码，是不是针对如我们的预期一样，将最可能的执行代码前置。这里，我们也是借助AI，让其从编译的目标elf文件中提取指定函数的汇编代码再做进一步分析。

感兴趣的朋友也可以自己去做这一步，下面附上提取汇编代码的方法：

```
arm-none-eabi-objdump -d xxx.elf --start-address=0x00226498 --stop-address=0x00226698 > test_with_unlikely.asm
```

这个里面的start-address可以从map文件中获得，比如我们上面例子编译结果的map文件摘要：

```
 .text.debug_dump_data
                0x002263f4       0x34 master_out/obj/main.o
                0x002263f4                debug_dump_data
 .text.test_without_hints
                0x00226428       0x70 master_out/obj/main.o
                0x00226428                test_without_hints
 .text.test_with_unlikely
                0x00226498       0x64 master_out/obj/main.o
                0x00226498                test_with_unlikely
 *fill*         0x002264fc        0x4 
```

经过AI的分析，我们看一下其分析的结果。其首先分析asm代码，给出了明确的证据说明确实unlikely起作用了。

代码段`(0x2264a8 - 0x2264c2)`是`test_with_unlikely`的主体程序：

```
2264a8:  add   r3, r4              ; sum += i
2264aa:  lsrs  r2, r3, #16         ; sum >> 16
2264ac:  uxtah r3, r2, r3          ; sum = (sum & 0xFFFF) + (sum >> 16)
2264b0:  ubfx  r2, r4, #0, #10     ; r2 = i & 0x3FF (extract bits 0-9)
2264b4:  str   r3, [sp, #4]        ; save sum

2264b6:  cbz   r2, 2264d8          ; if ((i & 0x3FF) == 0) → COLD PATH ✅
                                   ; ^^^ FORWARD BRANCH = unlikely() hint worked!

2264b8:  ldrb  r3, [r6, #0]        ; [HOT PATH CONTINUES] load g_debug_mode
2264ba:  cbnz  r3, 2264ce          ; if (g_debug_mode) → another cold path

2264bc:  adds  r4, #1              ; i++
2264be:  cmp   r5, r4              ; i < iterations?
2264c0:  ldr   r3, [sp, #4]        ; reload sum
2264c2:  bne.n 2264a8              ; LOOP BACK ← tight hot loop!
```

`0x2264d8`处为**Cold Path 1 (Error Handling):**

```
2264d8:  mov   r1, r4
2264da:  add   r0, sp, #4
2264dc:  bl    226370              ; call handle_error_condition (noinline)
2264e0:  adds  r7, #1              ; error_count++
2264e2:  b.n   2264b8              ; jump back to hot path
```

`0x2264ce`处为**Cold Path 2 (Debug Dump):**

```
2264ce:  mov   r1, r4
2264d0:  add   r0, sp, #4
2264d2:  bl    2263f4              ; call debug_dump_data
2264d6:  b.n   2264bc              ; jump back
```

可以发现，这两段处理逻辑均被安排到主体函数之外，其中：

- `handle_error_condition`被链接到**hot path**之后32 bytes ✅
- `debug_dump_data`被链接到**hot path**之后22 bytes ✅

主体并没有被两段处理逻辑打断，其占用连续的26 bytes, 用1-2个I-Cache lines就可以搞定。

| Feature | Evidence | Benefit |
|---------|----------|---------|
| **Forward branch for cold path** | `cbz r2, 2264d8` jumps +32 bytes | Hot path stays inline |
| **Compact hot loop** | Only 26 bytes (11 instructions) | Fits in 1-2 cache lines |
| **Cold paths out-of-line** | At 0x2264ce and 0x2264d8 | Doesn't pollute I-cache |
| **Fall-through on common case** | When `(i & 0x3FF) != 0`, continues at 2264b8 | No branch penalty 99.9% of time |


如果不添加**`unlikely()`**，结果会是怎样？下面，我们来分析一下另外一个`test_without_hints`的汇编代码。

通过分析，可以发现，主体被拆分成了两个部分 ：

**Part 1: 0x226446 - 0x226456**
```
226446:  add   r3, r4              ; sum += i
226448:  lsrs  r2, r3, #16         ; sum >> 16
22644a:  uxtah r3, r2, r3          ; sum = (sum & 0xFFFF) + (sum >> 16)
22644e:  ubfx  r2, r4, #0, #10     ; r2 = i & 0x3FF

226454:  cmp   r2, #0              ; if ((i & 0x3FF) == 0)?
226456:  bne.n 22643a              ; NO → jump BACKWARD ⚠️
```

**Part 2: 0x22643a - 0x226444**
```
22643a:  ldrb  r3, [r6, #0]        ; load g_debug_mode
22643c:  cbnz  r3, 226468          ; if (g_debug_mode) → jump forward
22643e:  adds  r4, #1              ; i++
226440:  cmp   r5, r4              ; i < iterations?
226442:  ldr   r3, [sp, #4]        ; reload sum
226444:  beq.n 226478              ; exit if done
; [FALLS THROUGH back to 226446] ✅
```

**Cold Path (Error Handling) INLINED: 0x226458 - 0x226466**
```
226458:  mov   r1, r4
22645a:  add   r0, sp, #4
22645c:  bl    226370              ; handle_error_condition
226460:  ldrb  r3, [r6, #0]        ; reload g_debug_mode
226462:  adds  r7, #1              ; error_count++
226464:  cmp   r3, #0
226466:  beq.n 22643e              ; jump back
```

眼神好的朋友可能发现了，虽然Part 1之后被强行插入了`handle_error_condition`，但是Part 2正好在Part 1的前面。也就是说，主体的执行代码还是连续的。跟使用了`unlikely`的版本不一样的地方在于，其汇编的空间分布顺序与执行顺序是反着的，而`unlikely`的版本是严格一致的，并没有受到Cold path的强行插入的影响。

归功于聪明的编译工具，这个时候的主体汇编还是连续的。就是这样，其执行的性能还是差于使用了`unlikely`提示的版本。

至于为什么同样是连续的指令空间，性能确有10%的差异，这个很值得去深究一下，后面有时间再深挖一下，有思路的朋友也可以在评论区留言。

## Conclusion

通过本文的分析可以看出，`unlikely()`分支提示虽然在代码层面只是一个简单的标记，但其背后对编译器代码布局优化的影响是深远的。通过将cold path代码移出hot path，编译器可以：

1. **保持hot path的连续性**：减少I-Cache的miss，提高指令预取效率
2. **优化分支预测**：通过forward branch向CPU提示这是一个很少执行的分支
3. **提升整体性能**：在本例中实现了约10%的性能提升

虽然编译器本身已经相当智能，能够在某些情况下自动优化代码布局，但通过`unlikely()`/`likely()`提示，我们可以为编译器提供更多的上下文信息，帮助它做出更好的优化决策。在实际的性能关键代码中，特别是在嵌入式系统中，这样的优化往往是值得的。

