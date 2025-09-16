---
toc: true
layout: post
title:  "g3log代码分析"
date:   2024-01-17
excerpt: "glog的异步平替"
image: ""
comments: true
toc: true
tags: Y-2024 c++ framework
---

## 引子

最近在优化一个项目性能的时候，经常发现glog会阻塞，最严重的情况会到秒级，让人很无奈。鉴于此，亟需切换使用一个异步的日志方案。

很早之前就听看过关于g3log的介绍(详情可以参阅其作者给出的[性能分析报告][g3log_perf_report])，其设计较简洁，性能很不错。再加上其使用方式与glog很类似，因此其很适合作为glog的一种异步平替方案。

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
3. 如果需要更复杂的日志操作，可以添加自定义的Sink，具体可以参考作者给出的[示例][g3sinks]

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

这里要特殊指出一下，刚开始看g3log源码的时候，很困惑这个LogCapture对象怎么跟LogWorker联系起来的。其既没有提供相关的分发日志内容的接口，其他的模块也没有引用该对象的时候。
直到看到其析构函数，一下全明白了。

```cpp
/** logCapture is a simple struct for capturing log/fatal entries. At destruction the
* captured message is forwarded to background worker.
* As a safety precaution: No memory allocated here will be moved into the background
* worker in case of dynamic loaded library reasons instead the arguments are copied
* inside of g3log.cpp::saveMessage*/
LogCapture::~LogCapture() noexcept(false) {
   using namespace g3::internal;
   SIGNAL_HANDLER_VERIFY();
   saveMessage(_stream.str().c_str(), _file, _line, _function, _level, _expression, _fatal_signal, _stack_trace.c_str());
}
```
提一嘴，如果该LogCapture所在的局部域没有退出的话，其是不会进到析构的，因此该LOG条目就并不会立即打印，就算设置了g3log的flush策略为立即打印，也不会。
有一个小Trick，如果你需要某一个LOG立即打印，你可以将该打印放到一个`{}`对中，比如：
```cpp
{
   LOG(INFO) << "this message will be flushed immediately.";
}
```

### Active类的设计

下面介绍g3log这个异步日志框架的一个核心组件，真正赖以实现所有异步操作的操盘手，那就是Active类。

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
2. run()是任务线程的执行主体，其顺序执行任务队列中的任务。当队列为空时，线程进入等待;
3. 着重需要说明的是，该类的析构函数，通过载入一个给done_赋值的任务，来结束run线程。
这个操作巧妙的点在于，无需对done_变量做锁操作即可以保证线程安全。而且可以保证所有的日志条目都能被正确的保存，不会被丢失。

### LogWorker：日志管理器

如前所述，每一个节点在初始化的时候，需要手动构造一个LogWorker。LogWorker担任一个管理员的角色，负责归集各个LogCapture中的日志内容，然后分发至不同的Sink。管理员不负责日志文件的写操作，真正的日志存储操作是在Sink中完成的。

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

1. `_sinks`: 该容器存储所有的Sink
2. `_bg`: 其是一个任务线程封装类，就是前面所述的Active类，所有的日志条目的分发都是交给这一个背景线程完成的。


### Sink的设计

Sink是日志内容的消费方，用来完成日志内容的最终处理，比如：关键词过滤、日志级别过滤、特殊颜色高亮显示以及文件存储等等。
这种基于Sink的设计思想，被很多的日志框架所采用，比如：glog，boost log等等。最早源至哪里，谁才是真正的鼻祖，我没有深入去考证。

其是一个模板类，通过传入不同的模板类型T，可以实现不同功能的Sink。也即是说，你只需要按照Sink的设计规范实现自定义的模板类即可。

Sink的类定义如下所示，为了显示方便，摘掉了其构造函数实现：
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
可以看出, Sink其实也是封装了一个Active线程，所有的日志操作均是在该背景线程上完成的。

g3log提供了一个最基础的FileSink，如果调用addDefaultLogger初始化g3log的话，内部就是使用FileSink来保存日志。

```cpp
      /**      
      A convenience function to add the default g3::FileSink to the log worker
       @param log_prefix that you want
       @param log_directory where the log is to be stored.
       @return a handle for API access to the sink. See the README for example usage

       @verbatim
       Example:
       using namespace g3;
       std::unique_ptr<LogWorker> logworker {LogWorker::createLogWorker()};
       auto handle = addDefaultLogger("my_test_log", "/tmp");
       initializeLogging(logworker.get()); // ref. g3log.hpp

       std::future<std::string> log_file_name = sinkHandle->call(&FileSink::fileName);
       std::cout << "The filename is: " << log_file_name.get() << std::endl;
       //   something like: /tmp/my_test_log.g3log.20150819-100300.log
       */
      std::unique_ptr<FileSinkHandle> addDefaultLogger(const std::string& log_prefix, const std::string& log_directory, const std::string& default_id = "g3log");

```

FileSink有一个很显著的缺点，那就是不能做文件大小限制。如果节点一直运行，日志打印的越多，文件会越来越大，难以维护。这个时候，就需要加入自定义的Sink了。

### SinkHandle
LogWorker调用addSink返回的是一个SinkHandle对象，也即是说，g3log不允许直接操作一个已添加过的Sink，所有的Sink操作都被委托给SinkHandle。

SinHandle触发的所有操作，都是同步异步调用的方式加入到对应Sink对象的任务线程中。这样做的好处是，可以保证线程安全。

```cpp
   template <class T>
   class SinkHandle {
      std::weak_ptr<internal::Sink<T>> _sink;
         
     public:
      SinkHandle(std::shared_ptr<internal::Sink<T>> sink) :
          _sink(sink) {}
            
      ~SinkHandle() = default;
         
      // Asynchronous call to the real sink. If the real sink is already deleted
      // the returned future will contain a bad_weak_ptr exception instead of the
      // call result.
      template <typename AsyncCall, typename... Args>
      auto call(AsyncCall func, Args&&... args) -> std::future<std::invoke_result_t<decltype(func), T, Args...>> {
         try {
            std::shared_ptr<internal::Sink<T>> sink(_sink);
            return sink->async(func, std::forward<Args>(args)...);
         } catch (const std::bad_weak_ptr& e) {
            typedef std::invoke_result_t<decltype(func), T, Args...> PromiseType;
            std::promise<PromiseType> promise;
            promise.set_exception(std::make_exception_ptr(e));
            return std::move(promise.get_future());
         }
      }

      /// Get weak_ptr access to the sink(). Make sure to check that the returned pointer is valid,
      /// auto p = sink(); auto ptr = p.lock(); if (ptr) { .... }
      /// ref: https://en.cppreference.com/w/cpp/memory/weak_ptr/lock
      std::weak_ptr<internal::Sink<T>> sink() {
         return _sink.lock();
      }  
   };    
```

如上面代码所示，SinkHandle维护的是一个弱智能指针，这样可以保证Sink对象的正常析构释放。同时，其在call接口中，捕捉了bad_weak_ptr异常。就算Sink对象被析构了也能正常运作。
整体来说，SinkHandle的设计还是很鲁棒的。


## 尾声

好了，以上就差不多是g3log的所有东西了。东西不多，但是很精妙。整体看下来，觉得其设计很轻巧。对于学习C++的人，值得一看。

## References

- [g3log作者的性能分析报告][g3log_perf_report]

[g3log_perf_report]: <https://kjellkod.wordpress.com/2015/06/30/the-worlds-fastest-logger-vs-g3log/>
[g3sinks]: <https://github.com/KjellKod/g3sinks>