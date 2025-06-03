---
toc: true
layout: post
title:  "Fast exp implementations"
date:   2025-02-28
excerpt: "AI Chat Series"
image: ""
comments: true
toc: true
tags: Y-2025 exp AI_Assistant_Programming
---


> 本文是AI Chat系列文章的第1篇，主要介绍如何快速实现一个高效的指数函数计算。

## Introduction

指数函数计算是科学计算中非常常见的一个问题，尤其是在机器学习、深度学习等领域。指数函数计算的公式如下：

$$
e^x = \sum_{n=0}^{\infty} \frac{x^n}{n!}
$$

## Ask the AI

> hello, do you know how to do iterative solver for the exp operation, to reduce computation cost?

> Yes! There are several iterative methods to approximate the exponential function. Here are two common approaches:

1. Taylor Series Expansion (simpler but less efficient):

    ```c
    float exp_taylor(float x, int terms) {
        float result = 1.0f;
        float term = 1.0f;
        
        for(int i = 1; i < terms; i++) {
            term *= x / i;
            result += term;
        }
        
        return result;
    }
    ```

2. CORDIC-like Algorithm (more efficient for embedded systems):

    ```c
    // Fixed-point implementation (Q16.16 format)
    #define FP_SHIFT 16
    #define FP_ONE (1 << FP_SHIFT)
    #define FP_MASK ((1 << FP_SHIFT) - 1)

    // Pre-computed exp(2^-k) values in Q16.16
    const uint32_t exp_table[] = {
        178145, // exp(-1)
        133652, // exp(-2)
        115832, // exp(-3)
        107555, // exp(-4)
        103520, // exp(-5)
        101567, // exp(-6)
        100613, // exp(-7)
        100139  // exp(-8)
    };

    int32_t exp_cordic(int32_t x) {
        // Handle x = 0 case
        if (x == 0) return FP_ONE;
        
        // Scale input to [-1,1] range
        int scale = 0;
        while (x >= FP_ONE) {
            x -= FP_ONE;
            scale++;
        }
        while (x <= -FP_ONE) {
            x += FP_ONE;
            scale--;
        }
        
        int32_t result = FP_ONE;
        int32_t power = x;
        
        // Iterative multiplication
        for (int i = 0; i < 8; i++) {
            if (power > 0) {
                result = (result * exp_table[i]) >> FP_SHIFT;
            }
            power = power << 1;
        }
        
        // Apply scaling
        while (scale > 0) {
            result = (result * 178145) >> FP_SHIFT;  // multiply by e
            scale--;
        }
        while (scale < 0) {
            result = (result * 23674) >> FP_SHIFT;   // multiply by 1/e
            scale++;
        }
        
        return result;
    }
    ```

3. Fast Approximation (most efficient but less accurate):

{% highlight c %}
    float fast_exp(float x) {
        // Based on the identity: e^x = 2^(x/ln(2))
        union {
            float f;
            int32_t i;
        } u;
        
        const float ln2 = 0.6931471805599453f;
        const float one_over_ln2 = 1.4426950408889634f;
        
        // Scale by 1/ln(2)
        float fx = x * one_over_ln2;
        
        // Split into integer and fractional parts
        int32_t ix = (int32_t)fx;
        float f = fx - ix;
        
        // Approximate 2^f using a small polynomial
        float y = 1.0f + f * (0.6931471805599453f + 
                            f * (0.2402265069591006f + 
                            f * 0.0555041086648216f));
        
        // Construct 2^ix * y
        ix = (ix + 127) << 23;
        u.i = ix;
        
        return u.f * y;
    }
    ```
{% endhighlight %}

**Usage comparison:**

```c
float x = 2.5f;

// Method 1: Taylor series (slower but simple)
float result1 = exp_taylor(x, 10);  // 10 terms

// Method 2: CORDIC-like (good for fixed-point)
int32_t x_fixed = (int32_t)(x * FP_ONE);
float result2 = (float)exp_cordic(x_fixed) / FP_ONE;

// Method 3: Fast approximation (fastest)
float result3 = fast_exp(x);
```

**Key points:**

1. Taylor series:
- Simple to understand
- Needs more terms for accuracy
- Good for small x values

2. CORDIC-like:
- Good for fixed-point arithmetic
- Consistent precision
- Table-based approach saves computation

3. Fast approximation:
- Fastest method
- Uses floating-point tricks
- Less accurate but often sufficient

**Choose based on your needs:**
- Need high accuracy? Use Taylor series
- Using fixed-point? Use CORDIC-like
- Need speed over accuracy? Use fast approximation

The fast approximation method is often good enough for most applications while being much faster than standard library exp().

## Experiment
下面来测试下Fast approximation方法的性能。我让AI给我写了一个简易的测试benchmark：
```c
    const int N = 100000;
    float x = 0;
    TicToc timer;
    timer.tic();
    for(int i = 0; i < N; ++i) {
        x += std::exp(-0.01 * i);
    }
    printf("x = %f\n", x);
    printf("one exp time = %fms\n", timer.toc() / N);
```
在一款Cortex-M4核（96MHz）的嵌入式核心上评估，结果如下所示：

| 方法 | 单次exp耗时 | x |
|------|------|------|
| 标准库 | 0.043ms | 100.5005 |
| 快速近似 | 0.0032ms | #.# |


可以发现fast approximation方法的单次exp耗时只有标准库的1/13，提升效果还是明显的，但是最终结果出现表征错误。那是为什么呢？下面进一步分析。

仔细分析，就会发现，由于float精度的限制，不考虑符号，其只能表征约$$2^{-126}$$到 $$2^{127}$$。因此，其幂指数超过127时，就会出现溢出，从而导致结果错误。当N设置为1000时，再次评估，就可以得到正确的结果了。

下面评估下fast approximation方法的精度

<figure>
<img src="{{ site.url }}/images/2025-Q1/fast_exp.png"  alt="img" align="center" class="center_img" />
</figure>

可以发现，当x=100时，fast approximation方法的精度已经非常差了。如果x值不大，精度还是可以接受的。
<figure>
<img src="{{ site.url }}/images/2025-Q1/fast_exp_2.png"  alt="img" align="center" class="center_img" />
</figure>


## Conclusion

- 在嵌入式平台上，如果对精度要求不高，fast approximation方法是一个不错的选择，可以显著提升计算效率。
