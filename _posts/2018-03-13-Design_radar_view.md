---
layout: post
title:  "Design a responsive radar view with libyue & observer pattern"
date:   2018-03-13
excerpt: "Introduction to libyue usage based on C++"
image: "/images/cute-dolphin.jpg"
comments: true
tags: libyue demo observer c++
---

## Purpose

Usually a simple GUI tool can give you direct visual status about your dev system, and can offer great help during development.

This article demonstrates a GUI demo which fetches latest sensor data from radar & sonar sensors to draw.

The final UI is showed as follows. It's not beautiful actually, but it can helps. You can find the whole sample at [github](https://github.com/sunbingfeng/libyue_cpp_demo)

![](http://oonn91xrt.bkt.clouddn.com/Screen%20Shot%202018-03-13%20at%207.15.52%20PM.png){:height="300px" width="300px"}

## Introduction to libyue

For detail documents, pls refer to [libyue doc](http://libyue.com/docs/v0.3.1/cpp/index.html)

- libyue is a light-weight gui framework which you can design cross-platform gui painlessly.
- linux version is based on gtk, and mac version is based on native cocoa framework.
- It deeply relies on event & delegate design pattern, so you can use c++ lamda function to connect custom reaction to ui event easily.
- It uses Facebook Yoga as layout engine, and you can change view layout easily through call of **SetStyle** function.

## Observer pattern

Reference to Wikipedia:
>
>The observer pattern is a software design pattern in which an object, called the subject, maintains a list of its dependents, called observers, and notifies them automatically of any state changes, usually by calling one of their methods.
>

Using observer pattern, we donnot need to check if data was updated. We are notified with latest data instead. Then we can make a data-driven ui more responsive.

In this article, we use observable lib which can be found at [github](https://github.com/ddinu/observable), and you can find detail instructions in it.

## Data model

We design a test model which generate radar test data every second.

```cpp

class TestModel
{
  OBSERVABLE_PROPERTIES(TestModel)
public:
    // data-driven heartbeat
    observable_property<bool> dataHB { false };

public:
  typedef std::vector<ObjectInfo_77> objects_t;

  TestModel()
  {
    std::srand(std::time(nullptr)); // use current time as seed for random generator

    pAmpUpdateTh = new std::thread(&TestModel::gen_amp, this);
    pAmpUpdateTh->detach();
  }

  ~TestModel()
  {

  }

  SonarData m_sonar;
  std::unordered_map<int, objects_t> m_objs_map;

private:
  std::thread *pAmpUpdateTh;
  bool _toggle = false;

  void gen_amp(void)
  {
    while(1)
    {
      int cnt = std::rand() % 10;
      objects_t front, rear;
      for (int i = 0; i < cnt; ++i)
      {
          float Range = 0.1f * (std::rand() % 2000);  // cm
          float Azimuth = ((std::rand() % 180) - 90) * pi / 180;        
          front.push_back(ObjectInfo_77({Range,Azimuth}));
      }
      m_objs_map[0] = front;

      cnt = std::rand() % 10;
      for (int i = 0; i < cnt; ++i)
      {
          float Range = 0.1f * (std::rand() % 2000);  // cm
          float Azimuth = ((std::rand() % 180) - 90) * pi / 180;        
          rear.push_back(ObjectInfo_77({Range,Azimuth}));
      }
      m_objs_map[1] = rear;
      
      m_sonar = {
        0.1f * (std::rand() % 2000),
        0.1f * (std::rand() % 2000)
      };

      _toggle = !_toggle;

      dataHB = _toggle;

      std::this_thread::sleep_for(std::chrono::seconds(1));
    }
  }
}

```

## Draw with yue

### basic 2D drawing

A simple example listed below demonstrates how to draw a radar point.

```cpp

void drawRadarObstacle(nu::Painter *painter, nu::PointF center, float radius)
{
  painter->Save();

  painter->SetStrokeColor(nu::Color("#550000")); //"#550000"
  painter->SetFillColor(nu::Color("#DD0000"));  //"#DD0000"

  painter->BeginPath();
  painter->Arc(center, radius, 0, 2*pi);
  painter->ClosePath();

  painter->Fill();

  painter->Restore();
}

```

### redraw with callback

We use container view to manage radar view redraw procedure.

It consists of three steps:

1. draw a rectangle car body
2. draw sonar arc view
3. draw radar point view

During the every redraw, we get the latest sensor data from model object.

```cpp

  scoped_refptr<nu::Container> radar_view(new nu::Container);
  radar_view->SetStyle("position", "absolute", "width", window_width, "height", window_height, "top", 0, "right", 0);

  radar_view->on_draw.Connect([&](nu::Container* self, nu::Painter* painter, const nu::RectF& dirty){
    drawCar(painter);
    updateSonarArc(painter, &model);  
    updateRadarDetectedObjects(painter, &model);
  });
  
```

## Conclusion

In this article, we try to use libyue to design a simple GUI and it workes well. It can be applied to large GUI system also. You can have a try.

Hope you a nice journey!
