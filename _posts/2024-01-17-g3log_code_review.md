---
layout: post
title:  "g3log代码分析"
date:   2024-01-17
excerpt: "glog的异步平替"
image: ""
comments: true
toc: false
tags: Y-2024 c++ g3log
---

## 引子

最近在优化一个项目性能的时候，经常发现glog会阻塞，最严重的情况会到秒级，让人很无奈。鉴于此，急需要切换使用一个异步的日志方案。

很早之前就听看过关于g3log的介绍(详情可以参阅其作者给出的[性能分析报告][g3log_perf_report])，其设计较简洁，性能很不错。再加上其使用方式与glog很类似，因此其很适合作为glog的一直异步平替方案。

经过简单的适配以后，发现之前因为同步日志带来的阻塞问题消失的无影无踪，心头一阵窃喜。

闲暇之余，拜读了g3log的源代码，发现其中还真有点干货。因此，想写一点东西，分享一下。

是为引。

## 关于g3log的基础使用

1. 首先构造一个LogWorker，并初始化g3log：

```cpp
  const std::string directory = "./";
  const std::string name = "TestLogFile";
  auto worker = g3::LogWorker::createLogWorker();
  auto handle = worker->addDefaultLogger(name, directory);    
```

2. 添加日志：

日志操作很简单，推荐使用基于Stream的方式，比如：
```cpp
LOG(DEBUG) << "Hello world!.";
```

3. 如果需要更复杂的日志操作，可以添加自定义的Sinker，具体可以参考作者给出的[示例][g3sinks]

## g3log的整体设计

### LOG宏的定义
上面提到的LOG(severity)宏的定义如下，其估计还是继承至glog：
```cpp
#define INTERNAL_LOG_MESSAGE(level) LogCapture(__FILE__, __LINE__, static_cast<const char*>(G3LOG_PRETTY_FUNCTION), level)
...
// LOG(level) is the API for the stream log  
#define LOG(level) if (!g3::logLevel(level)) {} else INTERNAL_LOG_MESSAGE(level).stream()
```

从上面代码可以看出，每一个LOG宏其实是定义了一个局部的LogCapture对象。该对象负责捕捉实际的日志内容，在其析构之前，会将所有的日志内容丢给LogWorker处理。

### LogWorker：日志管理器

如前所述，每一个节点在初始化的时候，需要手动构造一个LogWorker。LogWorker担任一个管理员的角色，负责归集各个LogCapture中的日志内容，然后分发至不同的Sinker。管理员不负责日志文件的写操作，真正的日志存储操作是在Sinker中完成的。

LogWorker包含一个private成员LogWorkerImpl，其承载了LogWorker的所有核心操作。

```cpp
   /// Background side of the LogWorker. Internal use only
   struct LogWorkerImpl final {
      typedef std::shared_ptr<g3::internal::SinkWrapper> SinkWrapperPtr;
      std::vector<SinkWrapperPtr> _sinks;
      std::unique_ptr<kjellkod::Active> _bg;  // do not change declaration order. _bg must be destroyed before sinks
      
      LogWorkerImpl(); 
      ~LogWorkerImpl() = default;
      
      void bgSave(g3::LogMessagePtr msgPtr);
      void bgFatal(FatalMessagePtr msgPtr);
      
      LogWorkerImpl(const LogWorkerImpl&) = delete;
      LogWorkerImpl& operator=(const LogWorkerImpl&) = delete;
   };

```

这里需要重点说明的是两个东西：

1. `_sinks`: 该容器存储所有的Sinker
2. '_bg': 其是一个任务线程封装类，所有的日志条目的分发都是交给这一个背景线程完成的。
后面可以重点介绍一下这个Active类的设计，还挺轻巧的。


### Sinker的设计

Sinker是日志内容的消费方，用来完成日志内容的最终处理，比如：关键词过滤、日志级别过滤、特殊颜色高亮显示以及文件存储等等。
这种基于Sinker的日志设计框架，被很多的日志框架所采用，比如：glog，boost log等等。最早源至哪里，谁是真正的鼻祖，我没有深入去考证。

其是一个模板类，通过传入不同的模板类型T，可以实现不同功能的Sinker。也即是说，你只需要按照Sinker的设计规范实现自定义的模板类即可。

Sinker的类定义如下所示，为了显示方便，摘掉了其构造函数实现：
```cpp
      template <class T>
      struct Sink : public SinkWrapper {
         std::unique_ptr<T> _real_sink;
         std::unique_ptr<kjellkod::Active> _bg;
         AsyncMessageCall _default_log_call;

         virtual ~Sink() {
            _bg.reset();  // TODO: to remove
         }

         void send(LogMessageMover msg) override {
            _bg->send([this, msg] {
               _default_log_call(msg);
            });
         }

         template <typename Call, typename... Args>
         auto async(Call call, Args&&... args) -> std::future<std::invoke_result_t<decltype(call), T, Args...>> {
            return g3::spawn_task(std::bind(call, _real_sink.get(), std::forward<Args>(args)...), _bg.get());
         }
      };
```
可以看出, Sinker其实也是封装了一个Active线程，所有的日志操作均是在该背景线程上完成的。


### Active类的设计

```cpp
   class Active {
     private:
      Active() :
          done_(false) {}  // Construction ONLY through factory createActive();
      Active(const Active&) = delete;
      Active& operator=(const Active&) = delete;
   
      void run() {
         while (!done_) { 
            Callback func;
            mq_.wait_and_pop(func);
            func(); 
         }
      }

      shared_queue<Callback> mq_;
      std::thread thd_;
      bool done_;
      
     public:
      virtual ~Active() {
         send([this]() noexcept { done_ = true; });
         thd_.join();
      }

      void send(Callback msg_) {
         mq_.push(msg_);
      }

      /// Factory: safe construction of object before thread start
      static std::unique_ptr<Active> createActive() {
         std::unique_ptr<Active> aPtr(new Active());
         aPtr->thd_ = std::thread(&Active::run, aPtr.get());
         return aPtr;
      }
   };
```

该类很巧妙的实现了一个先进先出的背景任务线程，而且保证线程安全。简单说明几点：

1. 其通过一个shared_queue来实现多个任务的顺序处理；
2. run()是任务线程的执行主题，其顺序执行任务队列中的任务。当队列为空时，线程进入等待;
3. 着重需要说明的是，该类的析构函数，通过载入一个给done_赋值的任务，来结束run线程。
这个操作巧妙的点在于，无需对done_变量做锁操作即可以保证线程安全。而且可以保证所有的日志条目都能被正确的保存，不会被丢失。


## References

- [g3log作者的性能分析报告][g3log_perf_report]

[g3log_perf_report]: <https://kjellkod.wordpress.com/2015/06/30/the-worlds-fastest-logger-vs-g3log/>
[g3sinks]: <https://github.com/KjellKod/g3sinks>