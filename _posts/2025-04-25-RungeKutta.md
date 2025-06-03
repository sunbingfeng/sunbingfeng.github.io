---
toc: true
layout: post
title:  "4th-order Rugge-Kutta"
date:   2025-04-25
excerpt: "AI Chat Series"
image: ""
comments: true
toc: true
tags: Y-2025 rk4 AI_Assistant_Programming
---


> 本文是AI Chat系列文章的第6篇，介绍常见的4阶Runge-Kutta方法。

## Introduction

在使用IMU的过程中，不可避免的需要对IMU原始数据做积分以获得位置和姿态角，那么Runge-Kutta方法就是一个绕不过去的知识点。相比于基础的中值积分等，可以提升积分的精度。

## Ask the AI

让AI给我编写4阶Runge-Kutta方法的过程中，其多次给我反馈带错误的实现，搞得我血压飙升，忍不住骂AI了。其间，AI一个劲的给我道歉，也是挺搞笑的。

>
>I apologize for my previous incorrect responses. You're right - I should be more careful and verify the formulas before suggesting changes.
>

不知道是把他骂晕了，还是怎么着，几个公式的符号就是死活搞不对。最后还是得我自己一行一行检查，一个一个符号确认，才让程序可以正常工作。

所以，这次就不附上问AI的过程了，直接上最终能工作的版本，以免大家也同我一样闹心，心率失常。

```python
def rk4_integration(gyro_data, acc_data, dt, initial_state=None):
    """
    Perform 4th-order Runge-Kutta integration on IMU data.
    
    Args:
        gyro_data: numpy array of gyroscope data (N x 3) in rad/s
        acc_data: numpy array of accelerometer data (N x 3) in m/s^2
        dt: time step in seconds
        initial_state: initial state [x, y, z, vx, vy, vz, qw, qx, qy, qz]
                      (position, velocity, quaternion)
    
    Returns:
        states: numpy array of integrated states (N x 10)
    """
    n_samples = len(gyro_data)
    
    # Initialize state vector [x, y, z, vx, vy, vz, qw, qx, qy, qz]
    if initial_state is None:
        initial_state = np.zeros(10)
        
        initial_state[6:10] = np.array([1.0, 0.0, 0.0, 0.0])
        
    states = np.zeros((n_samples, 10))
    vel_dot = np.zeros((n_samples, 3))
    states[0] = initial_state
    
    def state_derivative(state, gyro, acc):
        """
        Calculate state derivatives for IMU integration.
        state: [x, y, z, vx, vy, vz, qw, qx, qy, qz]
        """
        # Extract quaternion
        q = state[6:10]
        q_norm = np.linalg.norm(q)
        if q_norm < 1e-6:
            print("Warning: Quaternion norm is too small!")
            return np.zeros(10)
            
        q = q / q_norm  # Normalize quaternion
        
        qw, qx, qy, qz = q
        # Quaternion derivative from gyroscope
        wx, wy, wz = gyro
        q_dot = 0.5 * np.array([
            [-qx*wx - qy*wy - qz*wz],
            [ -qw*wx - qz*wy + qy*wz],
            [ qz*wx + qw*wy - qx*wz],
            [-qy*wx + qx*wy + qw*wz]
        ]).flatten()
       
        # Rotation matrix from quaternion
        R = np.array([
            [1-2*qy**2-2*qz**2, 2*qx*qy-2*qw*qz, 2*qx*qz+2*qw*qy],
            [2*qx*qy+2*qw*qz, 1-2*qx**2-2*qz**2, 2*qy*qz-2*qw*qx],
            [2*qx*qz-2*qw*qy, 2*qy*qz+2*qw*qx, 1-2*qx**2-2*qy**2]
        ])
        
        # Check if rotation matrix is valid
        if np.any(np.isnan(R)):
            return np.zeros(10)
        
        # Accelerometer measurement in world frame
        acc_world = R @ acc
        
        # Check if acceleration is valid
        if np.any(np.isnan(acc_world)):
            return np.zeros(10)
        
        # State derivative
        state_dot = np.zeros(10)
        state_dot[0:3] = state[3:6]  # Position derivative = velocity
        state_dot[3:6] = acc_world - np.array([0, 0, 9.81])  # Velocity derivative = acceleration - gravity
        state_dot[6:10] = q_dot  # Quaternion derivative
        
        # print("velocity derivative: ", state_dot[3:6]) 
        return state_dot
    
    # RK4 integration
    for i in range(1, n_samples):
        state = states[i-1]
        gyro = gyro_data[i-1]
        acc = acc_data[i-1]
        
        # Check input data
        if np.any(np.isnan(gyro)) or np.any(np.isnan(acc)):
            states[i] = states[i-1]  # Keep previous state
            continue
        
        # RK4 steps
        k1 = state_derivative(state, gyro, acc)
        k2 = state_derivative(state + 0.5*dt*k1, gyro, acc)
        k3 = state_derivative(state + 0.5*dt*k2, gyro, acc)
        k4 = state_derivative(state + dt*k3, gyro, acc)
        
        # Update state
        states[i] = state + (dt/6.0) * (k1 + 2*k2 + 2*k3 + k4)
        
        # Normalize quaternion
        q_norm = np.linalg.norm(states[i, 6:10])
        if q_norm < 1e-6:
            print(f"Warning: Quaternion norm too small at index {i}")
            states[i] = states[i-1]  # Keep previous state
        else:
            states[i, 6:10] = states[i, 6:10] / q_norm
        
        vel_dot[i] = k4[3:6]

    return states, vel_dot
```

不过有一说一，AI的思路还是相当清晰的，逻辑可圈可点。
其针对IMU积分过程，首先定义了状态变量，明确了一阶导的实现，然后指出RK4算法所需要的4步微分中间量，最后汇总积分输出更新后的状态量。
整个过程很清晰，一眼就能很清楚每一步在干啥。

所以，一句话总结一下这一次跟AI聊天的经验。那就是，框架性的东西问AI，细节性的东西还是得自己细心检查。

## Experiments

下面，我们用一段IMU的数据，做一个简单的测试。测试代码以及所使用的测试数据详见评论区。

我们看一下IMU的数据情况：
<figure>
<img src="{{ site.url }}/images/2025-Q2/gyro.png"  alt="img" align="center" class="center_img" />
</figure>
<figure>
<img src="{{ site.url }}/images/2025-Q2/acc.png"  alt="img" align="center" class="center_img" />
</figure>

接下来就是RK4积分后的结果：
<figure>
<img src="{{ site.url }}/images/2025-Q2/result.png"  alt="img" align="center" class="center_img" />
</figure>

好了，感兴趣的朋友可以去体验一下。
