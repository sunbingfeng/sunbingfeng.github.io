---
toc: true
layout: post
title:  "Deep Dive into Butterworth Low Pass Filter"
date:   2025-08-15
excerpt: "From Theory to Implementation: A Comprehensive Guide to Butterworth Filters"
image: ""
comments: true
toc: true
tags: Y-2025 math algorithm
---

> This is the 7th article in the AI Chat series, where we'll explore the principles and implementation of the Butterworth low-pass filter.

## Table of Contents
1. [Introduction](#1-introduction)
2. [Mathematical Foundation](#2-mathematical-foundation)
3. [Filter Design Process](#3-filter-design-process)
4. [Implementation Methods](#4-implementation-methods)
5. [Experimental Validation](#5-experimental-validation)
6. [Conclusion](#6-conclusion)

## 1. Introduction

In signal processing, particularly for positioning and sensor data applications, filter selection is crucial. The Butterworth low-pass filter has become one of the most widely used filters due to its:
- **Maximally flat frequency response** in the passband
- **Simple mathematical structure**
- **Straightforward implementation**
- **Predictable behavior**

This article will guide you through the complete design process, from mathematical principles to practical implementation, using a real-world example from the VQF IMU attitude fusion algorithm.

## 2. Mathematical Foundation

### 2.1 Butterworth Filter Characteristics

The Butterworth filter is designed to have a **maximally flat magnitude response** in the passband. For a second-order filter, this means:
- **DC gain**: 1 (0 dB)
- **Cutoff frequency**: -3 dB point
- **Roll-off rate**: -40 dB/decade after cutoff

### 2.2 Normalized Prototype Filter

The standard approach starts with a **normalized prototype** filter with cutoff frequency at 1 rad/s:

**Transfer Function:**
```
H(s) = 1 / (s² + √2s + 1)
```

**Why 1 rad/s?**
- This is a **convention** in filter design
- Provides a **standardized starting point**
- Makes calculations and comparisons easier
- All Butterworth filters begin with this normalized form

**Mathematical Verification:**
At ω = 1 rad/s:
```
H(j·1) = 1 / ((j·1)² + √2·j·1 + 1)
        = 1 / (-1 + j√2 + 1)
        = 1 / (j√2)
```

The magnitude is exactly `1/√2 ≈ 0.707`, which corresponds to the -3 dB cutoff point.

## 3. Filter Design Process

### 3.1 Traditional Design Steps

The classical approach involves four main steps:

1. **Normalized Prototype**: Start with H(s) = 1/(s² + √2s + 1)
2. **Frequency Scaling**: Scale to desired cutoff frequency ωc
3. **Bilinear Transform**: Convert from s-domain to z-domain
4. **Coefficient Extraction**: Derive the difference equation coefficients

### 3.2 Frequency Scaling

To scale the cutoff frequency from 1 rad/s to ωc:

**Substitute s → s/ωc:**
```
H(s) = 1 / ((s/ωc)² + √2(s/ωc) + 1)
     = ωc² / (s² + √2ωc·s + ωc²)
```

### 3.3 Bilinear Transform

Convert from continuous-time to discrete-time:

**Transform Formula:**
```
s = (2/T) × (z-1)/(z+1)
```

Where T is the sampling period.

## 4. Implementation Methods

### 4.1 VQF Implementation Approach

The VQF algorithm uses a more sophisticated approach that **implicitly handles frequency pre-warping**:

```cpp
void filterCoeffs(vqf_real_t tau, vqf_real_t Ts, double outB[], double outA[])
{
    assert(tau > 0);
    assert(Ts > 0);
    
    // Calculate pre-warped cutoff frequency
    double fc = (M_SQRT2 / (2.0*M_PI))/double(tau);
    double C = tan(M_PI*fc*double(Ts));
    double D = C*C + sqrt(2)*C + 1;
    
    // Filter coefficients
    double b0 = C*C/D;
    outB[0] = b0;      // b0
    outB[1] = 2*b0;    // b1
    outB[2] = b0;      // b2
    
    outA[0] = 2*(C*C-1)/D;           // a1
    outA[1] = (1-sqrt(2)*C+C*C)/D;   // a2
}
```

### 4.2 Why VQF Method Works

The key insight is **frequency pre-warping compensation**:

**Pre-warping Formula:**
```
ωc = (2/T) × tan(ωd×T/2)
```

Where:
- **ωc** = pre-warped cutoff frequency
- **ωd** = desired digital cutoff frequency
- **T** = sampling period

**Why This Matters:**
- The bilinear transform introduces **frequency distortion**
- Low frequencies are compressed, high frequencies are expanded
- Without pre-warping, the digital filter would have the wrong cutoff frequency
- The VQF method automatically compensates for this distortion

### 4.3 Traditional vs. VQF Approach

| Aspect | Traditional Method | VQF Method |
|--------|-------------------|------------|
| **Frequency Handling** | Direct ωc usage | Pre-warped ωc |
| **Denominator** | 4 + 2√2ωc + ωc² | C² + √2C + 1 |
| **Pre-warping** | Manual calculation | Built-in |
| **Accuracy** | Requires manual compensation | Automatic |

## 5. Experimental Validation

### 5.1 Test Setup

Let's validate our understanding by comparing the VQF implementation with SciPy's industry-standard implementation:

**Parameters:**
- Sampling Frequency: 1000 Hz
- Cutoff Frequency: 100 Hz
- Filter Order: 2
- Nyquist Frequency: 500 Hz

### 5.2 Coefficient Comparison

**Method 1: SciPy Implementation**
```
b coefficients: [0.06745527 0.13491055 0.06745527]
a coefficients: [ 1.        -1.1429805  0.4128016]
```

**Method 2: VQF Implementation**
```
b coefficients: [0.06745527 0.13491055 0.06745527]
a coefficients: [ 1.        -1.1429805  0.4128016]
```

**Result:** Perfect match! Both methods produce identical coefficients.

### 5.3 Frequency Response Analysis

The frequency response confirms:
- **-3 dB cutoff** exactly at 100 Hz
- **Passband flatness** as expected
- **Roll-off rate** of -40 dB/decade
- **No ripples** in passband or stopband

<figure>
<img src="{{ site.url }}/images/2025-Q3/butterworth.png"  alt="Butterworth Filter Frequency Response" align="center" class="center_img" />
<figcaption>Figure 1: Frequency response of the 2nd-order Butterworth low-pass filter showing the -3 dB cutoff at 100 Hz</figcaption>
</figure>

## 6. Conclusion

### 6.1 Key Takeaways

1. **Mathematical Foundation**: The Butterworth filter's normalized prototype provides a solid starting point
2. **Pre-warping Importance**: Frequency compensation is crucial for accurate digital filter design
3. **VQF Method Superiority**: The VQF approach automatically handles pre-warping, making it more robust
4. **Validation**: Both theoretical and experimental results confirm the correctness of our implementation

### 6.2 Practical Applications

This understanding is essential for:
- **Sensor data processing** in robotics and IoT
- **Audio signal filtering** in consumer electronics
- **Control system design** in automotive and aerospace
- **Biomedical signal processing** in healthcare devices

### 6.3 Further Reading

For deeper exploration, consider:
- [VQF IMU Attitude Fusion Algorithm][vqf] - The source of our implementation
- [Stack Overflow Discussion][stackoverflow] - Detailed mathematical derivation
- Signal Processing textbooks on digital filter design

The Butterworth filter remains a cornerstone of signal processing, and understanding its implementation details empowers engineers to create robust, efficient filtering solutions for real-world applications.

[vqf]: <https://github.com/dlaidig/vqf>
[stackoverflow]: <https://stackoverflow.com/questions/20924868/calculate-coefficients-of-2nd-order-butterworth-low-pass-filter/52764064#52764064>