---
toc: true
layout: post
title:  "Conjugate Gradient Method"
date:   2025-04-11
excerpt: "AI Chat Series"
image: ""
comments: true
toc: true
tags: Y-2025 math
---


> 本文是AI Chat系列文章的第4篇，介绍基于Conjugate Gradient的线性求解方法。

## Introduction

在优化求解问题中，经常会碰到类似$$Ax=b$$的线性方程求解问题。如果A是对称矩阵，那么可以调用常规的LU分解或者Cholskey分解来完成方程式的求解。

这类求解方法没啥好说的，今天来介绍一个基于迭代的求解方法。正如文章标题所述，该方法主要基于Conjugate Gradient，下面基于AI的配合，详细阐述一下。

## Ask the AI

>Me: Responding to Ax=b problems where A is large and sparse, direct methods, i.e, LU decomposition, are computationally expensive. Can you show me how to solve it through Conjugate Gradient method?
>
>AI: Certainly! Iterative methods are particularly useful for solving large systems of linear equations, especially when the matrix involved is sparse or too large for direct methods to be efficient. One of the most common iterative methods for solving systems of linear equations is the **Conjugate Gradient (CG) method**. Here's a more detailed explanation:

The Conjugate Gradient (CG) method is an iterative algorithm for solving systems of linear equations $$Ax = b$$, where $$A$$ is a symmetric positive definite matrix. Here's a step-by-step derivation of the method:

### **Problem Setup:**

Given a symmetric positive definite matrix $$A$$ and a vector $$b$$, we want to find the vector $$x$$ that minimizes the quadratic function:

$$
f(x) = \frac{1}{2} x^T A x - b^T x
$$

The gradient of this function is:

$$
\nabla f(x) = Ax - b
$$

Setting the gradient to zero gives the system of equations:

$$
Ax = b
$$

### **Derivation of the CG Method:**

1. **Initialization**:
   - Start with an initial guess $$x_0$$.
   - Compute the initial residual $$r_0 = b - Ax_0$$.
   - Set the initial search direction $$p_0 = r_0$$.

2. **Iterative Process**:
   - For each iteration $$k$$, perform the following steps:

3. **Compute Step Size**:
   - Calculate the step size $$\alpha_k$$ using the formula:

   $$
   \alpha_k = \frac{r_k^T r_k}{p_k^T A p_k}
   $$

4. **Update the Solution**:
   - Update the solution vector $$x$$:

   $$
   x_{k+1} = x_k + \alpha_k p_k
   $$

5. **Update the Residual**:
   - Compute the new residual:

   $$
   r_{k+1} = r_k - \alpha_k A p_k
   $$

6. **Check for Convergence**:
   - If the norm of the residual $$r_{k+1}$$ is below a certain threshold, the algorithm has converged.

7. **Compute the New Search Direction**:
   - Calculate the coefficient $$\beta_k$$:

   $$
   \beta_k = \frac{r_{k+1}^T r_{k+1}}{r_k^T r_k}
   $$

8. **Update the Search Direction**:
   - Update the search direction:

   $$
   p_{k+1} = r_{k+1} + \beta_k p_k
   $$

### Convergence:

The CG method converges in at most $$n$$ iterations for an $$n \times n$$ matrix, but it often converges much faster in practice. The method is efficient because it only requires matrix-vector multiplications and does not need to store the entire matrix $$A$$.

### Summary:

The Conjugate Gradient method is powerful for solving large, sparse systems of linear equations due to its efficiency and the fact that it only requires the matrix $$A$$ to be symmetric and positive definite. The method iteratively refines the solution by minimizing the quadratic form associated with the system, using conjugate directions to ensure convergence.

这里需要补充说明一下，$$\alpha_k$$ 为什么取这个值，继续跟AI聊一下。

>Me: I think the derivation of the update of the $$\alpha_k$$ might be to minimize the quadratic test function $$\frac{1}{2}x^T A x - x^T b$$. Through this way, I can obtain the specified formula $$\alpha_k$$ What's your opinion?
>
>AI: Yes, you're absolutely right! The correct way to derive $$\alpha_k$$ is through minimizing the quadratic objective function. Let me show the correct derivation:

### Correct Derivation of $$\alpha_k$$

The quadratic objective function is:

$$
f(x) = \frac{1}{2}x^T A x - x^T b
$$

1. **Update Step**:
   - At each iteration, we update $$x$$ along the search direction:
   
   $$
   x_{k+1} = x_k + \alpha_k p_k
   $$

2. **Minimizing the Objective Function**:
   - Substitute the update into the objective function:
   
   $$
   f(x_k + \alpha_k p_k) = \frac{1}{2}(x_k + \alpha_k p_k)^T A (x_k + \alpha_k p_k) - (x_k + \alpha_k p_k)^T b
   $$

3. **Take Derivative with Respect to $$\alpha_k$$**:
   - Set the derivative to zero:
   
   $$
   \frac{d}{d\alpha_k}f(x_k + \alpha_k p_k) = p_k^T A x_k + \alpha_k p_k^T A p_k - p_k^T b = 0
   $$

4. **Using the Residual**:
   - Note that $$r_k = b - A x_k$$
   - Therefore, $$p_k^T(b - A x_k) = p_k^T r_k$$

5. **Solve for $$\alpha_k$$**:
   
   $$
   \alpha_k = \frac{p_k^T r_k}{p_k^T A p_k} = \frac{r_k^T r_k}{p_k^T A p_k}
   $$

This derivation through minimizing the quadratic objective function gives us the correct formula for $$\alpha_k$$. This approach is more principled than trying to minimize $$r_{k+1}^2$$ directly, as it aligns with the fundamental goal of the Conjugate Gradient method: finding the minimum of the quadratic form.

The last equality $$\frac{p_k^T r_k}{p_k^T A p_k} = \frac{r_k^T r_k}{p_k^T A p_k}$$ holds because at each iteration, $$p_k$$ is a linear combination of $$r_k$$ and previous search directions.

This derivation helps explain why the Conjugate Gradient method is so effective at minimizing the quadratic objective function and solving the linear system $$Ax = b$$.

补充说明一下，二次代价函数$$f(x_k)$$的一阶导为$$A x_k - b$$，而CG求解过程中所谓的残差$$r_k=b - A x_k$$其实就是负梯度方向。$$x_{k+1}$$更新是沿着$$p_k$$方向更新$$\alpha_k$$步进，该本质就是沿着负梯度方向的线性搜索。$$p_0$$初始值选择就是$$r_0$$的方向，$$p_{k+1}$$更新基于$$r_{k+1}$$和$$p_k$$的线性组合，因此可以近似认为$$p_k$$还是沿着负梯度方向，也即与$$r_k$$同向。

>Me: Can you give me more theory support to this method?
>
>AI: Yes, the Conjugate Gradient (CG) method is supported by several theoretical foundations that explain its efficiency and convergence properties. Here are some key theoretical aspects:

### **Krylov Subspace Methods**

The CG method is a type of Krylov subspace method. These methods iteratively build a solution by exploring the Krylov subspace, which is generated by the initial residual and the matrix $$A$$:

$$
\mathcal{K}_k(A, r_0) = \text{span}\{r_0, Ar_0, A^2r_0, \ldots, A^{k-1}r_0\}
$$

The CG method finds the best approximation to the solution within this subspace, minimizing the error in the $$A$$-norm.

### **Conjugate Directions**

The method constructs a sequence of search directions that are $$A$$-conjugate, meaning they satisfy:

$$
p_i^T A p_j = 0 \quad \text{for} \quad i \neq j
$$

This property ensures that each step in the algorithm is orthogonal to the previous ones in the transformed space defined by $$A$$, leading to efficient convergence.

### **Quadratic Minimization**

The CG method minimizes the quadratic form:

$$
f(x) = \frac{1}{2} x^T A x - b^T x
$$

By iteratively updating the solution, the method reduces the residual and the error in the solution, converging to the minimum of the quadratic form.

### **Convergence Properties**

- **Finite Termination**: For an $$n \times n$$ matrix, the CG method converges in at most $$n$$ iterations, assuming exact arithmetic. In practice, it often converges much faster.
- **Error Reduction**: The error in the solution decreases exponentially with each iteration, especially when the eigenvalues of $$A$$ are well-clustered.

### **Spectral Properties**

The convergence rate of the CG method is influenced by the eigenvalues of the matrix $$A$$. The method converges faster when the eigenvalues are tightly clustered, as this leads to a smaller condition number.

### **Preconditioning**

To improve convergence, preconditioning can be applied. A preconditioner $$M$$ is used to transform the system into one with more favorable spectral properties:

$$
M^{-1}Ax = M^{-1}b
$$

The preconditioned system has a better-conditioned matrix, leading to faster convergence.

These theoretical foundations explain why the CG method is effective for solving large, sparse systems of linear equations, particularly when the matrix is symmetric and positive definite. The method's reliance on conjugate directions and its ability to minimize the quadratic form efficiently are key to its success.

>Me: Show me why $$p_i^T A p_j = 0$$ applies.
>
>AI: The property $$p_i^T A p_j = 0$$ for $$i \neq j$$ in the Conjugate Gradient method is known as the conjugacy of the search directions. This property is crucial for the efficiency and convergence of the method. Let's go through the reasoning behind this property.

### Conjugacy of Search Directions

The search directions $$p_k$$ in the Conjugate Gradient method are constructed to be $$A$$-conjugate, meaning:

$$
p_i^T A p_j = 0 \quad \text{for} \quad i \neq j
$$

#### Derivation

1. **Initialization**:
   - The first search direction is set to the initial residual: $$p_0 = r_0$$.

2. **Iterative Update**:
   - For each iteration $$k$$, the new search direction is computed as:

   $$
   p_{k+1} = r_{k+1} + \beta_k p_k
   $$

   where

   $$
   \beta_k = \frac{r_{k+1}^T r_{k+1}}{r_k^T r_k}
   $$

3. **Orthogonality of Residuals**:
   - The residuals are orthogonal: $$r_i^T r_j = 0$$ for $$i \neq j$$.

4. **Conjugacy Proof**:
   - Assume $$p_0, p_1, \ldots, p_k$$ are $$A$$-conjugate.
   - We need to show that $$p_{k+1}$$ is also $$A$$-conjugate to all previous directions.

   Consider $$p_{k+1} = r_{k+1} + \beta_k p_k$$. We want to show:

   $$
   p_{k+1}^T A p_j = 0 \quad \text{for} \quad j \leq k
   $$

   - For $$j = k$$:

     $$
     p_{k+1}^T A p_k = (r_{k+1} + \beta_k p_k)^T A p_k = r_{k+1}^T A p_k + \beta_k p_k^T A p_k
     $$

     Since $$r_{k+1}$$ is orthogonal to $$p_k$$ in the $$A$$-norm, $$r_{k+1}^T A p_k = 0$$. Also, by the definition of $$\beta_k$$, the term $$\beta_k p_k^T A p_k$$ does not affect the conjugacy.

   - For $$j < k$$:

     $$
     p_{k+1}^T A p_j = (r_{k+1} + \beta_k p_k)^T A p_j = r_{k+1}^T A p_j + \beta_k p_k^T A p_j
     $$

     Both terms are zero because $$r_{k+1}$$ is orthogonal to all previous directions and $$p_k$$ is $$A$$-conjugate to $$p_j$$.

### Conclusion

The conjugacy of the search directions ensures that each update in the Conjugate Gradient method is independent of the others in terms of the $$A$$-norm. This property is crucial for the method's efficiency, allowing it to converge in at most $$n$$ iterations for an $$n \times n$$ matrix.

上面AI给出的解释，我始终觉得有问题，就是这一段：

>Since $$r_{k+1}$$ is orthogonal to $$p_k$$ in the $$A$$-norm, $$r_{k+1}^T A p_k = 0$$. Also, by the definition of $$\beta_k$$, the term $$\beta_k p_k^T A p_k$$ does not affect the conjugacy.

$$r_{k+1}$$与$$r_k$$是正交的，而$$r_{k+1}=r_{k}-\alpha_{k}Ap_{k}$$，也即其可以由$$r_k$$和$$A p_k$$线性表达，因此$$r_{k+1}$$不可能与$$Ap_{k}$$正交。再者，$$p_k^T A p_k$$是大于0的，它怎么就不影响$$p_{k+1}$$的conjugacy特性，怎么就能推出$$p_{k+1}^T A p_k=0$$？

反正AI的解释就是糊里糊涂的。下面我来推导一下$$\beta$$的由来，以说明为啥前后$$p_{k}$$是conjugate orthogonal。

Congugate Gradient的核心宗旨是确保$$p_{k+1}^T A p_k=0$$, 那么:

$$
\begin{align}
(r_{k+1} + \beta A p_{k})^T A p_{k} = 0 \\
r_{k+1}^T A p_k + \beta p_{k}^T A p_k = 0 \\
\beta = -\frac{r_{k+1}^T A p_k}{p_k^T A p_k} \\
\end{align}
$$

由前面的推导可知：

$$
\begin{align}
r_{k+1} = r_k - \alpha_k A p_k \\
\alpha_k = \frac{r_k^T r_k}{p_k^T A p_k}
\end{align}
$$

代入到前面的公式可得：

$$
\beta = -\frac{r_{k+1}^T(r_k - r_{k+1})}{\alpha {p_k^T A p_k}}
= \frac{r_{k+1}^T r_{k+1}}{r_k^T r_k}
$$

因此，$$\beta$$的特殊取值设计保证了$$p_{k}$$是conjugate orthogonal。

## Experiments

好了，说里那么多，我们来写一段测试程序验证下该方法的可行性。

```python
def test_conjugate_gradient():
    J = np.random.rand(10, 10)
    A = np.dot(np.transpose(J), J)
    x_true = np.random.rand(10)
    b = np.dot(A, x_true)
    x = np.linalg.solve(A, b)
    print("x_true: ", x_true)
    print("x: ", x, ", error: ", np.linalg.norm(x - x_true))
    
    x = np.zeros(10)
    r = b - np.dot(A, x)
    p = r
    r_old = r
    
    errors = []
    for i in range(20):
        Ap = np.dot(A, p)
        alpha = np.dot(r, r) / np.dot(p, Ap)
        x = x + alpha * p
        r = r - alpha * Ap
        if np.linalg.norm(r) < 1e-6:
            break
        beta = np.dot(r, r) / np.dot(r_old, r_old)
        p = r + beta * p
        r_old = r
        errors.append(np.linalg.norm(x - x_true))
    print("x by CG: ", x, ", error: ", np.linalg.norm(x - x_true))
    
    _, ax = plt.subplots()
    ax.plot(errors)
    ax.set_title("conjugate gradient error")
    plt.show()
```

这段测试程序很简单，就是生成一个随机的10x10的方阵J，然后构造对称矩阵A。针对给定的x值，生成对应的b，然后通过两种方法（一为numpy内置的线性求解器，二为上面介绍的Conjugate Gradient方法）求解x的估计值。

运行结果如下：

```
x_true:  [0.43035432 0.64106726 0.0515147  0.03762809 0.73804567 0.23480996
 0.76863671 0.14293322 0.3014281  0.21103692]
x:  [0.43035432 0.64106726 0.0515147  0.03762809 0.73804567 0.23480996        
 0.76863671 0.14293322 0.3014281  0.21103692] , error:  8.102494088942738e-14 
x by CG:  [0.43035432 0.64106726 0.0515147  0.03762809 0.73804567 0.23480996  
 0.76863671 0.14293322 0.3014281  0.21103692] , error:  2.7416374433878263e-11
```

两种方法计算的结果相当接近，从下面的图示可以看出，收敛速度还挺快，10次迭代后的误差为2.7416374433878263e-11，已经很小了。

<figure>
<img src="{{ site.url }}/images/2025-Q2/cg_error.png"  alt="img" align="center" class="center_img" />
</figure>

通过上面的一个简单实验，说明该方法精度和收敛速度均不错。
