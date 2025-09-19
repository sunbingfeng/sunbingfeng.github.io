---
toc: true
layout: post
title:  "Setup Android Dev Environment"
date:   2025-09-05
image: ""
comments: true
excerpt: "Android Setup"
toc: true
tags: Y-2025 review
---

> 本文是AI Chat系列文章的第9篇，介绍从一个小白的视角搭建Android开发环境。

## Introduction

最近工作需要在Android平台上实现一个测试APP，但是以前没有过Android开发的经验，连开发环境都不知道怎么搭建。还好，我们有AI的帮助，废话不说，开干吧。

## Setup Dev Environment

一般来说，Android应用开发都是在Android Studio或者Jetbrains 等IDE中进行的。这些IDE有一个共同的特点，那就是太庞大，不够轻便。现在VSCode生态这么好，我们很自然的想到是不是有基于VSCode的开发流程。

接着我们去Google一下，找到一篇还算完整的[Tutorial][setup_dev_tutorial]，教我们如何一步步搭建Android开发环境。整理一下，主要有几个关键的点：

1. 安装JDK，可以去[Java官网][java_official]下载
2. 安装Android SDK，这里只需要下载command line tools就行。去到[Android开发者网站][android_sdk]，滑到最下面，下载对应的cli tools。然后解压到一个目录下(建议`Android/sdk`)。
3. 安装VSCode相关插件: Android For VSCode, 配置launch.json
4. 配置环境变量这里总结下几个必须要配置的：

    | Env | Description | Example |
    |--------|-------------------|----------|
    | **JAVA_HOME** | 步骤1安装的JDK的路径 | **D:\Program Files\Eclipse Adoptium\jdk-21.0.8.9-hotspot**|
    | **ANDROID_HOME**|步骤2解压的SDK路径| **D:\Android\sdk**|
    | **PATH** | 将platform_tools目录加到PATH | **%ANDROID_HOME%\platform-tools\\** |
    |**ANDROID_AVD_HOME**|安卓模拟器路径| **%ANDROID_HOME%\.android\avd** |

## Demo Project
目前，大都利用Gradle去管理Anroid开发环境。起初，连Gradle是啥我都不知道，但是Google一下后大概直到其是干啥的了。那么，一个使用Gradle管理的工程长什么样呢，这里给一个示例：

<figure>
<img src="{{ site.url }}/images/2025-Q3/gradle_proj.png"  alt="Demo project" align="center" class="center_img" />
<figcaption>Figure 1: 示例工程结构</figcaption>
</figure>

其中，有几个点说明一下：
- `.vscode`是VSCode配置文件夹
- `gradle/wrapper`是gradle创建wrapper环境所用的配置文件夹
- `settings.gradle`和`build.gradle`是用来描述工程编译设置项，比如：所依赖的SDK/Java/Kotlin版本，三方库版本等
- `gradlew.bat`或者`gradlew`，其是工程所使用的gradle脚本，后续所有的编译安装操作都是用这个脚本。`.bat`脚本是给Windows环境用的。

在我调试用的这个开源工程上，没有gradlew脚本。起初，我Google了一下怎么利用系统Gradle来生成这个脚本，一直都没有成功。最后，我直接让AI给我生成了一个gradlew.bat脚本。简单看了一眼其内容，大致为读取JAVA环境配置，并且基于`gradle/wrapper`下面的设置生成gradle环境。该环境是局部有效的，放置于本工程的`.gradle`目录下面。

插一句嘴，这个利用gradlew脚本来管理工程的一个好处，即是可以保证所有人的开发环境都是一致的，都是基于wrapper配置来统一生成的。这样方便做版本控制，以及协同开发。

有了这个脚本后，我们就可以执行工程编译，所使用的命令是：`.\gradlew.bat assembleDebug`。编译过程中，会去拉取一些依赖库。在国内，可以配置一些大厂的镜像源，以加速拉去进度。配置方法很多，可以参考[Gradle国内源配置][gradle_source]。

编译成功后，我们需要找一个模拟器来试运行一下程序。下面，我们直接问AI，如何搭建一个emulator。

其给出的步骤如下：
- 创建一个模拟器，`avdmanager.bat create avd -n "TestDevice" -k "system-images;android-26;google_apis;x86" -d "pixel"`
- 可以检查下emulator有没有生成成功：`emulator.exe -list-avds`
- 启动模拟器：`emulator.exe -avd TestDevice`

模拟器安装好以后，就可以将编译成功的app安装到模拟器上调试运行了。
- 安装app：`gradlew.bat installDebug`
- 启动app: `adb.exe shell am start -n [app name]`

最后，上一个模拟器启动后的图片。

<figure>
<img src="{{ site.url }}/images/2025-Q3/emulator.png"  alt="Demo project" align="center" class="center_img" />
<figcaption>Figure 2：模拟器界面</figcaption>
</figure>

## Conclusion

这次完全是一个小白入手搭建Android开发环境并且跑通程序调试运行的经历。虽然技术含量不高，但是作为一个从0到1的过程，还是有必要记录一下。过程中，也有遇到一些问题，AI通过读取命令的报错信息，直接就给解决了，本文没有完全摘录。因此，本文并不是一个一站式解决方案，只是列了一个梗概，各中细节还是需要各位借助AI自己去摸索。

日常工作中，如果有需要开发一些简单测试APP，你完全不用惧怕。如果能在开源社区找到一个相近的工程，那么借助AI改巴改巴实现你的需求，是完全没问题的。甚至你也可以完全借助AI去给你从0到1搭建工程，去一步步实现。

总之，只要你敢想，没有什么可以阻挡！

[setup_dev_tutorial]: <https://dev.to/allenchrios/optimizing-android-development-key-features-of-vs-code-to-enhance-your-workflow-54i5>
[java_official]: <https://www.oracle.com/java/technologies/downloads/>
[android_sdk]: <https://developer.android.com/studio?hl=zh-cn#downloads>
[gradle_source]: <https://blog.iprac.cn/blogs/628.html>