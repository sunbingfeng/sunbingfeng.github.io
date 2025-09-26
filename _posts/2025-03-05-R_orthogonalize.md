---
toc: true
layout: post
title:  "SO(3) Orthogonalization"
date:   2025-03-05
excerpt: "AI Chat Series"
image: ""
comments: true
toc: true
tags: math
---


> 本文是AI Chat系列文章的第3篇，主要介绍实现SO(3)的正交化运算。

## Introduction

之前让AI帮助实现了一个简易的SO(3)类，其中有一段SO(3)的正交化操作的代码，如下所示：

```cpp
class SO3 {
public:
    // ... existing code ...

    // Orthogonalize the rotation matrix
    void orthogonalize() {
        std::array<std::array<double, 3>, 3> R = R_;
        
        // First column remains unchanged
        // Normalize first column
        double norm = std::sqrt(R[0][0]*R[0][0] + R[1][0]*R[1][0] + R[2][0]*R[2][0]);
        R[0][0] /= norm;
        R[1][0] /= norm;
        R[2][0] /= norm;

        // Second column - remove projection onto first column and normalize
        double dot = R[0][1]*R[0][0] + R[1][1]*R[1][0] + R[2][1]*R[2][0];
        R[0][1] -= dot * R[0][0];
        R[1][1] -= dot * R[1][0];
        R[2][1] -= dot * R[2][0];
        norm = std::sqrt(R[0][1]*R[0][1] + R[1][1]*R[1][1] + R[2][1]*R[2][1]);
        R[0][1] /= norm;
        R[1][1] /= norm;
        R[2][1] /= norm;

        // Third column - cross product of first two columns
        R[0][2] = R[1][0]*R[2][1] - R[2][0]*R[1][1];
        R[1][2] = R[2][0]*R[0][1] - R[0][0]*R[2][1];
        R[2][2] = R[0][0]*R[1][1] - R[1][0]*R[0][1];

        R_ = R;
    }
};
```

其就是基于Gram-Schmidt正交化方法实现的，只能保证R的列向量是正交的，不能保证是R_的最优逼近。因此，再跟AI聊一下，让他帮改进一下。


## Ask the AI
>Me: This orthogonalization method only ensure that the axises are orthogonal, but can not guarantee the R is close to R_. In theory, we should use the equation $$R = (R*R^T)^{-1/2}*R$$ instead. So what's your opinion?
>
>AI: You're absolutely right! The current Gram-Schmidt orthogonalization method doesn't minimize the distance to the original matrix R. The formula you suggested R = (RR^T)^(-1/2)R is known as the Polar Decomposition method, which finds the closest orthogonal matrix to R in Frobenius norm.

Here's an improved implementation:

```cpp
void orthogonalize() {
    // 1. Compute S = R*R^T
    std::array<std::array<double, 3>, 3> S;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            S[i][j] = 0;
            for (int k = 0; k < 3; ++k) {
                S[i][j] += R_[i][k] * R_[j][k];
            }
        }
    }

    // 2. Compute eigenvalues and eigenvectors of S
    // Since S is symmetric positive definite, we can use simpler methods
    // Here using Newton iteration for inverse square root
    std::array<std::array<double, 3>, 3> Sinv_sqrt = S;
    
    // Newton iteration for inverse square root
    for (int iter = 0; iter < 5; ++iter) {  // Usually converges in 2-3 iterations
        std::array<std::array<double, 3>, 3> temp = Sinv_sqrt;
        
        // Sinv_sqrt = (3I - Sinv_sqrt*S*Sinv_sqrt)*Sinv_sqrt/2
        std::array<std::array<double, 3>, 3> prod;
        // Compute Sinv_sqrt*S
        for (int i = 0; i < 3; ++i) {
            for (int j = 0; j < 3; ++j) {
                prod[i][j] = 0;
                for (int k = 0; k < 3; ++k) {
                    prod[i][j] += temp[i][k] * S[k][j];
                }
            }
        }
        // Compute (Sinv_sqrt*S)*Sinv_sqrt
        for (int i = 0; i < 3; ++i) {
            for (int j = 0; j < 3; ++j) {
                Sinv_sqrt[i][j] = 0;
                for (int k = 0; k < 3; ++k) {
                    Sinv_sqrt[i][j] += prod[i][k] * temp[k][j];
                }
            }
        }
        // 3I - Sinv_sqrt
        for (int i = 0; i < 3; ++i) {
            for (int j = 0; j < 3; ++j) {
                Sinv_sqrt[i][j] = (i == j ? 3.0 : 0.0) - Sinv_sqrt[i][j];
            }
        }
        // Multiply by original Sinv_sqrt and scale
        for (int i = 0; i < 3; ++i) {
            for (int j = 0; j < 3; ++j) {
                double sum = 0;
                for (int k = 0; k < 3; ++k) {
                    sum += Sinv_sqrt[i][k] * temp[k][j];
                }
                Sinv_sqrt[i][j] = sum * 0.5;
            }
        }
    }

    // 3. R = (RR^T)^(-1/2)*R
    std::array<std::array<double, 3>, 3> result;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            result[i][j] = 0;
            for (int k = 0; k < 3; ++k) {
                result[i][j] += Sinv_sqrt[i][k] * R_[k][j];
            }
        }
    }

    R_ = result;
}
```

Key advantages of this approach:

1. Minimizes `||R - R_||_F` while maintaining orthogonality
2. Preserves the orientation (determinant = 1)
3. More numerically stable than Gram-Schmidt
4. Provides the closest orthogonal matrix in Frobenius norm

The Newton iteration for computing $$(RR^T)^{-1/2}$$ is more efficient than explicit eigendecomposition and typically converges in 2-3 iterations for matrices close to orthogonal.

>Me: Could you give me more mathematics details about the Newton iteration?
> 
>AI: Let me explain the Newton iteration for computing $$(RR^T)^{-1/2}$$:

For a symmetric positive definite matrix $$S = RR^T$$, we want to find $$X = S^{-1/2}$$. This means:

$$
\begin{align}
X^2 = S^{-1} \\
XS^{1/2} = I \\
\end{align}
$$

The Newton iteration for computing $$X = S^{-1/2}$$ is based on the function $$f(X) = X^{-2} - S$$. We want $$f(X) = 0$$.

The iteration formula is:
$$ X_{k+1} = X_k(3I - X_kSX_k)/2 $$

Here's why it works:
1. If $$X$$ is close to $$S^{-1/2}$$, then $$XSX ≈ I$$
2. The error term in each iteration is cubic, meaning very fast convergence
3. The factor 1/2 ensures stability

For matrices close to orthogonal (like our rotation matrices), the iteration typically converges in 2-3 steps.

Here's a more detailed implementation with comments:

```cpp
void orthogonalize() {
    // Compute S = RR^T
    std::array<std::array<double, 3>, 3> S;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            S[i][j] = 0;
            for (int k = 0; k < 3; ++k) {
                S[i][j] += R_[i][k] * R_[j][k];
            }
        }
    }

    // Initial guess: X₀ = S (for matrices close to orthogonal)
    std::array<std::array<double, 3>, 3> X = S;
    
    // Newton iteration: Xₖ₊₁ = Xₖ(3I - XₖSXₖ)/2
    for (int iter = 0; iter < 5; ++iter) {
        // Store current X
        std::array<std::array<double, 3>, 3> X_k = X;
        
        // Compute XₖS
        std::array<std::array<double, 3>, 3> XS;
        for (int i = 0; i < 3; ++i) {
            for (int j = 0; j < 3; ++j) {
                XS[i][j] = 0;
                for (int k = 0; k < 3; ++k) {
                    XS[i][j] += X_k[i][k] * S[k][j];
                }
            }
        }
        
        // Compute XₖSXₖ
        std::array<std::array<double, 3>, 3> XSX;
        for (int i = 0; i < 3; ++i) {
            for (int j = 0; j < 3; ++j) {
                XSX[i][j] = 0;
                for (int k = 0; k < 3; ++k) {
                    XSX[i][j] += XS[i][k] * X_k[k][j];
                }
            }
        }
        
        // Compute 3I - XₖSXₖ
        for (int i = 0; i < 3; ++i) {
            for (int j = 0; j < 3; ++j) {
                XSX[i][j] = (i == j ? 3.0 : 0.0) - XSX[i][j];
            }
        }
        
        // Compute Xₖ₊₁ = Xₖ(3I - XₖSXₖ)/2
        for (int i = 0; i < 3; ++i) {
            for (int j = 0; j < 3; ++j) {
                X[i][j] = 0;
                for (int k = 0; k < 3; ++k) {
                    X[i][j] += X_k[i][k] * XSX[k][j];
                }
                X[i][j] *= 0.5;
            }
        }
    }

    // Finally compute R = S^(-1/2)R
    std::array<std::array<double, 3>, 3> result;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            result[i][j] = 0;
            for (int k = 0; k < 3; ++k) {
                result[i][j] += X[i][k] * R_[k][j];
            }
        }
    }

    R_ = result;
}
```

The convergence can be monitored by checking `||XSX - I||`, but for rotation matrices that are already close to orthogonal, a fixed number of iterations (3-5) is usually sufficient.

>Me: As the Newton method should calculate the gradient, in order to obtain the iteration formula, so is this iteration formula obtained through this way? 

>AI: Yes, this Newton iteration formula for computing $$S^{-1/2}$$ is derived from the Newton-Raphson method, but in a matrix form. Let me explain the derivation:

1. We want to find X such that $$X^2 = S^{-1}$$
   This can be rewritten as: $$f(X) = X^{-2} - S = 0$$

2. The Newton iteration formula in general is:
   $$ X_{k+1} = X_k - [f'(X_k)]^{-1}f(X_k) $$

3. For our matrix function $$f(X) = X^{-2} - S$$, the derivative (Fréchet derivative) is: $$f'(X)H = -2X^{-3}H$$, where H is the direction of derivative

4. Substituting into Newton's formula:

$$\\
\begin{align*}
X_{k+1} &= X_k + \frac{1}{2}X_k^3(X_k^{-2} - S) \\
    &= X_k(I + \frac{1}{2}(I - X_kSX_k)) \\
    &= X_k(\frac{3}{2}I - \frac{1}{2}X_kSX_k) \\
    &= X_k(3I - X_kSX_k)/2 \\
\end{align*}
\\$$

This is how we arrive at the iteration formula. The cubic convergence rate comes from the fact that if X is close to S^(-1/2), then the error in the next iteration is cubed.


>Me: You substitue the $$X_k^2*S$$ with $$X_k * S * X_k$$, so why these two equal?

>AI:For general matrices, $$X_k^2*S ≠ X_k*S*X_k$$. However, in our case, we're working with symmetric matrices where:

1. $$S = RR^T$$ is symmetric
2. $$X_k$$ converges to $$S^{-1/2}$$, which is also symmetric
3. For symmetric matrices, matrix multiplication is associative and the order doesn't matter when multiplying with their own powers

Therefore, in this specific context:
- When $$X_k$$ is symmetric (which it is in each iteration)
- And $$S$$ is symmetric (which it is by construction as $$RR^T$$)
- Then $$X_k^2*S = X_k*S*X_k$$

This property is crucial for the Newton iteration to work correctly. The symmetry of all matrices involved allows us to write the iteration in either form without changing the result.

If we were working with non-symmetric matrices, we would need to be much more careful about the order of matrix multiplication.