---
toc: true
layout: post
title:  "Fast Inverse sqrt"
date:   2025-04-14
excerpt: "AI Chat Series"
image: ""
comments: true
toc: true
tags: Y-2025 math tips
---


> 本文是AI Chat系列文章的第5篇，介绍一种快速的$$\frac{1}{\sqrt{x}}$$求解算法。

## Introduction

在嵌入式平台上，经常需要优化算法的执行效率。今天介绍一种快速的求解inverse sqrt的方法。这个经典的快速求解算法，于1999年首次应用于一款第一人称视角游戏 **Quake III Arena** 中。其中涉及到大量的向量normalization运算，也即除以向量模的操作。通过该算法的应用，极大的提升了游戏的性能。一个小的优化，收获数量级的性能提升，堪称算法优化的典范。

## Ask the AI

> Me: Help me to implement a fast inverse sqrt method.
>
> AI: I'll help you implement the famous "Fast Inverse Square Root" algorithm, which was popularized by Quake III Arena. This algorithm provides a fast approximation of $$\frac{1}{\sqrt{x}}$$.

```cpp
float FastInverseSqrt(float x) {
    // Evil floating point bit hack
    float xhalf = 0.5f * x;
    int i = *(int*)&x;              // Reinterpret float bits as int
    i = 0x5f3759df - (i >> 1);      // The magic number
    x = *(float*)&i;                // Reinterpret int bits as float
    
    // Newton's method iteration for better accuracy
    x = x * (1.5f - xhalf * x * x); // First iteration
    // x = x * (1.5f - xhalf * x * x); // Optional: Second iteration for more accuracy
    
    return x;
}
```

For a more modern C++ implementation with type safety:

```cpp
#include <cstdint>

float FastInverseSqrt(float x) {
    union {
        float f;
        std::uint32_t i;
    } conv;

    const float xhalf = 0.5f * x;
    conv.f = x;
    conv.i = 0x5f3759df - (conv.i >> 1);
    x = conv.f;
    x = x * (1.5f - xhalf * x * x); // First Newton iteration
    // x = x * (1.5f - xhalf * x * x); // Optional: Second iteration
    
    return x;
}
```

### How it works:

1. **Bit manipulation**: The algorithm exploits the IEEE 754 floating-point representation to approximate $$\log_2$$ through integer operations.

2. **Magic number**: 0x5f3759df is a carefully chosen constant that helps approximate the logarithm.

3. **Newton's method**: One or two iterations of Newton's method refine the approximation.

### Usage example:

```cpp
float x = 2.0f;
float inv_sqrt = FastInverseSqrt(x);
// inv_sqrt ≈ 1/√2 ≈ 0.707106781
```

### Performance comparison:

```cpp
// Standard library version
float StandardInverseSqrt(float x) {
    return 1.0f / std::sqrt(x);
}

// Benchmark example
void CompareSpeed() {
    float x = 2.0f;
    
    // Fast version
    float fast_result = FastInverseSqrt(x);
    
    // Standard version
    float std_result = StandardInverseSqrt(x);
    
    // Compare accuracy
    float relative_error = std::abs(fast_result - std_result) / std_result;
    printf("Relative error: %e\n", relative_error);
}
```

### Notes:

1. **Accuracy**: The fast version is an approximation. One Newton iteration gives about 1% accuracy, two iterations about 0.1%.

2. **Modern hardware**: On modern CPUs, the standard `1.0f / std::sqrt(x)` might be just as fast due to hardware optimizations.

3. **Undefined behavior**: The original bit-hack version technically violates strict aliasing rules. The union version is safer.

4. **Positive numbers**: The function assumes positive input numbers.

If you need a specific accuracy level or have other requirements, let me know and I can modify the implementation accordingly.

这是基于CPP的实现，关于其背后的理论知识以及详细的推导过程，建议查看[Wikipedia][invsqrt_wiki]上的解释，非常的详细。
接下来，我们让AI写一个Python的实现，并编写相关的测试benchmark。

>Me: Re-implement it in Python please.
>
>AI: Here's the Fast Inverse Square Root implementation in Python, using both NumPy for vectorized operations and a pure Python version:

```python
import numpy as np
import struct

def fast_inverse_sqrt_single(x: float) -> float:
    """
    Fast inverse square root for a single float number
    Args:
        x: Input float number (must be positive)
    Returns:
        Approximation of 1/sqrt(x)
    """
    if x <= 0:
        raise ValueError("Input must be positive")
    
    # Convert float to its binary representation
    x_bytes = struct.pack('f', x)
    i = struct.unpack('i', x_bytes)[0]
    
    # The magic number and bit manipulation
    x_half = x * 0.5
    i = 0x5f3759df - (i >> 1)
    
    # Convert back to float
    x = struct.unpack('f', struct.pack('i', i))[0]
    
    # Newton iteration
    x = x * (1.5 - x_half * x * x)  # First iteration
    # x = x * (1.5 - x_half * x * x)  # Optional: Second iteration for more accuracy
    
    return x

def fast_inverse_sqrt_numpy(x: np.ndarray) -> np.ndarray:
    """
    Vectorized fast inverse square root for numpy arrays
    Args:
        x: Input numpy array (must be positive)
    Returns:
        Array with approximations of 1/sqrt(x)
    """
    if np.any(x <= 0):
        raise ValueError("All inputs must be positive")
    
    x = x.astype(np.float32)
    x_half = 0.5 * x
    
    # View float32 as int32 for bit manipulation
    i = x.view(np.int32)
    i = 0x5f3759df - (i >> 1)
    x = i.view(np.float32)
    
    # Newton iteration
    x = x * (1.5 - x_half * x * x)  # First iteration
    # x = x * (1.5 - x_half * x * x)  # Optional: Second iteration
    
    return x

# Example usage and testing
if __name__ == "__main__":
    # Test single value
    x = 2.0
    result_single = fast_inverse_sqrt_single(x)
    true_value = 1.0 / np.sqrt(x)
    print(f"Single value test:")
    print(f"Input: {x}")
    print(f"Fast inverse sqrt: {result_single}")
    print(f"True value: {true_value}")
    print(f"Relative error: {abs(result_single - true_value) / true_value}")
    
    # Test numpy array
    x_array = np.array([1.0, 2.0, 4.0, 16.0], dtype=np.float32)
    result_array = fast_inverse_sqrt_numpy(x_array)
    true_array = 1.0 / np.sqrt(x_array)
    
    print("\nArray test:")
    print(f"Input array: {x_array}")
    print(f"Fast inverse sqrt: {result_array}")
    print(f"True values: {true_array}")
    print(f"Relative errors: {np.abs(result_array - true_array) / true_array}")
    
    # Benchmark
    import time
    
    size = 1000000
    x_large = np.random.random(size).astype(np.float32)
    
    start_time = time.time()
    fast_result = fast_inverse_sqrt_numpy(x_large)
    fast_time = time.time() - start_time
    
    start_time = time.time()
    numpy_result = 1.0 / np.sqrt(x_large)
    numpy_time = time.time() - start_time
    
    print("\nBenchmark:")
    print(f"Fast inverse sqrt time: {fast_time:.6f} seconds")
    print(f"Numpy time: {numpy_time:.6f} seconds")
    print(f"Mean relative error: {np.mean(np.abs(fast_result - numpy_result) / numpy_result)}")
```

This implementation provides:

1. **Single Value Function**: `fast_inverse_sqrt_single()`
   - Works with individual float values
   - Uses Python's `struct` module for bit manipulation

2. **Vectorized Function**: `fast_inverse_sqrt_numpy()`
   - Works with NumPy arrays
   - Vectorized operations for better performance
   - Uses NumPy's view casting for bit manipulation

3. **Testing and Benchmarking**:
   - Compares results with true values
   - Measures performance against NumPy's implementation
   - Calculates relative errors

Key features:
- Type checking and error handling
- Both scalar and vectorized implementations
- Performance benchmarking
- Accuracy comparison with true values

Note that in Python, this implementation is mainly for educational purposes because:
1. NumPy's `1.0 / np.sqrt(x)` is highly optimized
2. Python's overhead makes bit manipulation less efficient than in C/C++
3. Modern hardware often has fast floating-point operations

The vectorized NumPy version will be much faster than the single-value version for large arrays, but might still be slower than NumPy's built-in functions.

## Experiments

首先，我们来运行一下Python的版本，看下结果如何：
```shell
Single value test:
Input: 2.0
Fast inverse sqrt: 0.7069300386983334
True value: 0.7071067811865475
Relative error: 0.00024995162387992986

Array test:
Input array: [ 1.  2.  4. 16.]
Fast inverse sqrt: [0.99830717 0.70693004 0.49915358 0.24957679]
True values: [1.         0.70710677 0.5        0.25      ]
Relative errors: [0.00169283 0.00024993 0.00169283 0.00169283]

Benchmark:
Fast inverse sqrt time: 0.009000 seconds
Numpy time: 0.002001 seconds
Mean relative error: 0.0009781228145584464
```

从上面的结果来看，快速invsqrt算法的逼近误差约在小数点后3位，精度还不错。单次耗时约0.009s，大于Numpy的0.002s。看来AI说的没错，Numpy中的实现做了向量化操作相关的优化，因此耗时更低。
下面我们换到嵌入式平台上来验证。

```cpp
    /// DEBUG CODE
    int N = 60000000;
    float sum = 0.0f;
    wlt::TicToc timer;
    for(int i = 1; i < N; i++) {
      float x = i;
      float y = invSqrt(x);
      sum += y;
    }
    LOG("invSqrt time: %.3f, sum: %.3f\r\n", timer.toc(), sum);
    timer.tic();

    sum = 0.0f;
    for(int i = 1; i < N; i++) {
      float x = i;
      float y = 1.0f / sqrt(x);
      sum += y;
    }
    LOG("inv sqrt throuth 1/sqrt time: %.3f, sum: %.3f\r\n", timer.toc(), sum);
```

结果如下所示：

```
invSqrt time: 5779.0, sum: 8192.0

inv sqrt throuth 1/sqrt time: 13174.0, sum: 8192.0
```

上面的耗时是N次的总耗时，平均后可以发现, 快速invsqrt单次执行耗时约96ns，1/sqrt耗时约为220ns，降低了1倍多，优化还是很明显的。

但是，这个耗时在ns数量级，如果invsqrt调用频次较低的话，这个耗时优化几乎无感！！因此，大家务必根据自己的应用场景合理选择。

[invsqrt_wiki]: <https://en.wikipedia.org/wiki/Fast_inverse_square_root>