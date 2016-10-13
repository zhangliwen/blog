---
layout: post
title: Rails瘦身
subtitle: "rails on a diet"
categories: [rails]
---

# 背景

新的项目启动时，Ruby on Rails是一个不错的选择。Rails很大程度上提高开发效率，你不需要重复发明轮子，不太需要关注安全性，在项目初期，你甚至不需要关注性能方面的问题。而事实上，Rails框架相对于其他一些轻灵（如Sinatra）的框架来说还是太重了。为什么会这样？这里有两个最常见的原因：依赖以及占用高资源。Rails瘦身中可以让你使用其他组件（如Sequel代替默认的ActiveRecord）和提高系统安全性。

# Rails 模块化

这是最简单的方式来选择你需要用到的Rails模块。在初始化模块时：

```ruby
# in config/application.rb
retuire 'rails/all'
```

换成：

```ruby
# in config/application.rb
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_model/railtie'
require 'sprockets/railtie'
```

当你看到这些模块时，你可以移除如active_record如果你使用其他数据库。

# 中间件

Rails默认开启一些中间件。Rails4.1有：

```
Rack::Sendfile
ActionDispatch::Static
Rack::Lock
Rack::Runtime
Rack::MethodOverride
ActionDispatch::RequestId
#<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x007ff931376400>
Rails::Rack::Logger
ActionDispatch::ShowExceptions
ActionDispatch::DebugExceptions
ActionDispatch::RemoteIp
ActionDispatch::Reloader
ActionDispatch::Callbacks
ActionDispatch::Cookies
ActionDispatch::Session::CookieStore
ActionDispatch::Flash
ActionDispatch::ParamsParser
Rack::ConditionalGet
Rack::ETag
YouApp::Application.routes
```

你可以通过执行 ```rake middleware``` 来查看你开启的中间件。

不知道各个中间件有什么作用的话，可以看看[Rails on Rack](http://guides.ruby-china.org/rails_on_rack.html)

Rails的设计目标是提供Web开发的最佳实践，所以无论你需要不需要，Rails默认提供了开发Web所有可能的组件，也许其中有一些你可能一辈子都用不上。Rails的哲学是： **提供最全的功能集给你，如果你用不到，你自己手工一个一个关闭** 。但是这样带来的结果就是默认带了太多不必要的冗余功能，造成性能损耗极大。关闭的方式很简单，如下：

```
#config/application.rb
config.middleware.delete Rack::ETag
```

# Rails Api

如果你想搭建纯api的项目，可以使用gem [rails-api](https://github.com/spastorino/rails-api) 或者 [Grape](https://github.com/ruby-grape/grape)。如果没了解过Grape，这里资料的比较全面[Community projects](http://www.ruby-grape.org/projects/)

我们可以看看这篇[Ruby社区应该去Rails化了](http://robbinfan.com/blog/40/ruby-off-rails),相信大家都看过，API分离是发展的需要。

# Gemfile太肥了

引用太多gem会让你的项目“更重”。你应该检查一下你的Gemfile，确保你引入的gem是否有必要存在，是否在合适的group中，能否设置require: false等。

要定时给rails升级，升级有可能让已有的问题可到改善，[升级心得](http://zhangliwen.site/rails/2016/09/13/how_to_upgrade_to_rails_4_2.html)。将有内存大泄露的[Gem](https://ruby-china.org/topics/27761)升级或替换掉

# 引用

[Ruby社区应该去Rails化了](http://robbinfan.com/blog/40/ruby-off-rails)

[Rails on Rack](http://guides.ruby-china.org/rails_on_rack.html)

[Rails on a diet](http://naturaily.com/blog/post/rails-on-a-diet)

[Putting Ruby on Rails on a diet](https://www.amberbit.com/blog/2014/2/14/putting-ruby-on-rails-on-a-diet/)
