---
toc: true
layout: post
title:  "探究优化求解方法"
date:   2025-09-18
excerpt: "牛顿大法好"
image: ""
comments: true
toc: true
tags: Y-2025 math
---

> 本文是AI Chat系列文章的第11篇， 探究经常用到的几种优化迭代求解方法。

## Introduction

对于优化求解问题，有一些常规的迭代求解办法，比如：梯度下降，高斯牛顿，LM等。这些方法本质都不难，但是一段时间不用，就容易生疏。本文通过2D平面直线拟合的问题来讲解一下这几种方法，以做温习之用。

首先，用数学语言描述一下我们要解决的问题，基于一组2D点$$s_i:[s_{xi}, s_{yi}]$$，求一个最优的直线表达$$y=ax+b$$以让所有点到法向的投影距离和最小，也即：

$$
    \begin{equation}
    \argmin_{a, b} \frac{1}{2} \sum \left | a s_{xi} + b - s_{yi} \right |^2
    \end{equation}
$$

其可以抽象为更通用的问题：

$$
    \begin{equation}
    \argmin_{x} \frac{1}{2} \sum {f_i}^T{f_i}
    \end{equation}
$$

其中，$$f_i$$表征采样点$$s_i$$在待估计参数$$x=[a, b]$$下的残差。针对直线拟合的问题， $$f_i(x) = a s_{xi} + b - s_{yi}$$。将所有的残差叠起来，组成一个更大的残差向量，则问题简化成$$\argmin_{x} \frac{1}{2} {f}^T{f}$$

下面将会依次讲解梯度下降，高斯牛顿以及牛顿迭代方法。

## Gradient-Descent

由上文可知，待优化的代价函数为$$F=\frac{1}{2} {f}^T{f}$$。其在$$x_{k-1}$$（说明，这里用$$x$$表示待优化变量，下同）处的梯度为： $$\nabla F=J^Tf$$

其中，$$J$$表征残差$$f$$相对$$x$$的雅可比。

那么，梯度下降方法的迭代步进为: $$-\alpha \nabla F$$, $$\alpha$$为可调步进参数。

以直线拟合的例子来说，$$J_i = [s_{xi}, 1]$$, $$J$$就是将所有的$$J_i$$竖着叠起来:

$$
\begin{equation}
J=\begin{bmatrix}
 J_0\\
 J_1\\
 \vdots\\
 J_m\\
\end{bmatrix}
\end{equation}
$$

看一下一个简单的实现：

```python
def gradient_descent_linear(x, y_obs, params_init, max_iter=100, learning_rate=0.1, tol=1e-6):
    """
    Gradient descent optimization for linear regression
    """
    params = params_init.copy()
     
    for iteration in range(max_iter):
        # Compute residuals
        res = residuals_linear(params, x, y_obs)
        error = np.sum(res**2)
        
        # Compute gradient (analytical for linear case)
        J = np.column_stack([x, np.ones_like(x)])  # Jacobian
        gradient = J.T @ res
        
        # Normalize gradient to prevent huge steps
        gradient_norm = np.linalg.norm(gradient)
        if gradient_norm > 0:
            gradient_normalized = gradient / gradient_norm
            params_new = params - learning_rate * gradient_normalized
        else:
            params_new = params
        
        # Check convergence
        if np.linalg.norm(params_new - params) < tol:
            print(f"Gradient descent converged after {iteration + 1} iterations")
            break
            
        params = params_new
    
    return params, error
```
上面的实现中，有一点需要注意的，那就是需要对gradient做归一化，以得到一个标准方向向量。

## Gaussian-Newton

从上文可知，$$f_i = {s_i}^Tx$$，对其做一阶泰勒展开可得，$$f_i(x+\delta x) = f_i(x) + J_i \delta x$$, 代入到代价函数中可得：

$$
\begin{equation}
F=\frac{1}{2}\sum \left \| f_i(x)+J_i\delta x \right \|^2
\end{equation}
$$

对$$\delta x$$求导，可得：

$$
\begin{equation}
\frac{\partial F}{\partial \delta x}=\sum {J_i}^T(f_i(x)+J_i \delta x)
\end{equation}
$$

令该导数为0，解出来$$\delta x = -{(J^TJ)}^{-1}J^Tf$$，
其中，$$J$$为$$J_i$$叠起来的雅可比矩阵（同上小节），$$f$$为叠起来的残差向量。

那么，上代码：

```python
def gaussian_newton_linear(x, y_obs, params_init, max_iter=100, tol=1e-6):
    """
    Gaussian-Newton method for linear regression
    """
    params = params_init.copy()
    for iteration in range(max_iter):
        # Compute residuals
        res = residuals_linear(params, x, y_obs)
        error = np.sum(res**2)
        
        # Compute Jacobian (analytical for linear case)
        J = np.column_stack([x, np.ones_like(x)])  # [x, 1] for [a, b]
        
        # Solve normal equations: J^T * J * delta = -J^T * residuals
        JTJ = J.T @ J
        JTr = J.T @ res
        
        # Add regularization
        regularization = 1e-8 * np.eye(JTJ.shape[0])
        JTJ_reg = JTJ + regularization
        
        try:
            delta = np.linalg.solve(JTJ_reg, -JTr)
        except np.linalg.LinAlgError:
            delta = -np.linalg.pinv(JTJ_reg) @ JTr
        
        # Update parameters
        params_new = params + delta
        
        # Check convergence
        if np.linalg.norm(delta) < tol:
            print(f"Gaussian-Newton converged after {iteration+1} iterations")
            break
            
        params = params_new
    
    return params, error

```

## Newton method

对代价函数F做二阶泰勒展开可得：

$$
\begin{equation}
F(x+\delta x) = F(x) + {\nabla F}^T \delta x + \frac{1}{2} {\delta x}^TH\delta x
\end{equation}
$$

其中，$$H$$表征$$F$$相对$$x$$的二阶导，也即Hessian矩阵。

让$$F$$对$$\delta x$$求导，并令导数为0，可以求解出$$\delta x$$:

$$
\begin{equation}
\delta x = -{H}^{-1}\nabla F
\end{equation}
$$

从上文可知$$\nabla F=J^Tf$$, 因此$$\delta x=-{H}^{-1}J^Tf$$

对比上一小节高斯牛顿方法，可以看出两者的差别主要在$$H$$部分，高斯牛顿方法可以理解为用$$J^TJ$$近似表征Hessian矩阵，从而达到降低运算量的目的。

针对本文中直线拟合的例子，可以发现其Hessian矩阵为0。这种情况下，Newton迭代还能用吗？我们来看一下。

类似Gaussian-Newton实现，我们一般也会给H加一个很小的单位矩阵，以确保可逆性：

```python
        # Add regularization
        regularization = 1e-8 * np.eye(H.shape[0])
        H_reg = H + regularization
```
如果H为0，那么H_reg就等于$$1e-8 * I$$。此时，Newton方法退化成了$$\alpha=1e8$$的梯度下降方法。由于$$\alpha$$太大，收敛性也会很差，结果可想而知。

## Results

我们让AI写了一个测试脚本，脚本放到评论区，这里直接上结果：

<figure>
<img src="{{ site.url }}/images/2025-Q3/reg_compare.png"  align="center" class="center_img" />
<figcaption>Figure 1: 优化求解结果对比</figcaption>
</figure>

| Method | Iterations | Execution Time (s) | Final Error | Convergence |
|--------|------------|-------------------|-------------|-------------|
| **Gaussian-Newton** | 2 | 0.001003 | 0.10314272 | ✓ Converged |
| **Newton Method** | 2 | 0.000997 | 0.10314272 | ✓ Converged |
| **Gradient Descent** | 100 | 0.004202 | 7.97953291 | ✗ Max iterations |

从上面的结果可以看出：

- **Fastest convergence**: Gaussian-Newton and Newton methods (both 2 iterations)
- **Best accuracy**: Gaussian-Newton and Newton methods (identical error: 0.103)
- **Slowest convergence**: Gradient Descent (100 iterations, hit max limit)
- **Worst accuracy**: Gradient Descent (error ~77x higher than optimal methods)
- **Computational efficiency**: Newton method slightly faster (0.000997s vs 0.001003s)

## Conclusion

本文通过2D直线拟合问题对比了三种常用的优化迭代方法：梯度下降、高斯牛顿和牛顿方法，简单总结如下：

- **梯度下降**：实现简单，但收敛慢，容易陷入局部最优
- **高斯牛顿**：用雅可比矩阵的转置乘积近似Hessian矩阵，在非线性最小二乘问题中表现优异
- **牛顿方法**：使用完整的Hessian矩阵，收敛速度快，但计算复杂度较高

对于线性回归这类问题，高斯牛顿和牛顿方法都能快速收敛到全局最优解，而梯度下降则显得力不从心。理论上，牛顿方法利用了二阶Hessian，实际效果会更好一些。但是受限于本文例子的特殊性，没有体现出二阶方法的优势。后续有机会给大家延申了讲一下。另外，LM方法在Gaussian-Newton基础上引入了自适应步进调节，在工程中应用很普遍，这里也不做展开介绍。

最后，留一个问题给大家。前一篇文章我们求解直线拟合的问题，使用SVD分解法可以求解直线法向。本文没有去优化求解法向，原因是什么？有没有机会去优化求解法向向量，会有什么问题？
