---
layout: post
title: 在Rails项目里面使用七牛作文Assets文件分发，CDN分发
subtitle: "Rails项目capistrano过程中，压缩后的Assets作为静态文件上传到七牛，共享CDN加速"
categories: [rails]
---
# 为什么使用七牛云存储

为什么会选择七牛，国内云存储比较出名的有：七牛，又拍云，以及阿里的OSS。其中用过七牛和又拍云，至于OSS，听说那时候不支持图片处理，虽然服务器使用阿里的，但还是直接PASS。一开始是使用又拍云的，在图片处理、SDK开发包、CDN加速以及价格上都挺满意的，唯一一点就是不稳定，经常莫名其妙的某些规格的图片就访问不了，而这时候（在当时）客服的qq状态变成手机在线的时候，据说是连客服都去抢修了。最后决定改版，从又拍云勇敢撤离，选择七牛。

在图片处理、SDK开发包、CDN加速在七牛上会表现的更加淋漓尽致，最主要的是稳定，现在发现撤离又拍云是正确的选择，最少在静态文件上不用再花时间了。

# 让七牛结合在 CarrierWave 里面使用

如果你想在 CarrierWave 里面使用七牛作为存储介质，那么你需要用:

[https://github.com/huobazi/carrierwave-qiniu](https://github.com/huobazi/carrierwave-qiniu)

Gemfile

```ruby
gem "carrierwave"
gem "qiniu"
gem "carrierwave-qiniu"
```
只需要简单的配置就能很好的将他们结合起来:

config/initializes/carrierwave.rb

```ruby
CarrierWave.configure do |config|
  config.storage             = :qiniu
  config.qiniu_access_key    = ENV["qiniu_access_key"]
  config.qiniu_secret_key    = ENV["qiniu_secret_key"]
end
```

app/uploaders/image_uploader.rb

```ruby
class ImageUploader < CarrierWave::Uploader::Base
  storage :qiniu
  self.qiniu_bucket = "空间名"
  self.qiniu_bucket_domain = '空间域名'
  self.qiniu_protocal = 'https'
  self.qiniu_can_overwrite = true
  ...
end
```

细节配置信息github都有，这里就不再细说了。如何使用图片功能可以参考[《在 Rails 项目里面使用又拍云用于存储上传图片》](http://huacnlee.com/blog/rails-app-image-store-with-carrierwave-upyun/#use-upyun-image-space)，在代码层这一块，七牛和云拍云是完全一样的，只有一点区别就是：相对又拍云需要先定义好图片规格250x250，七牛甚至连规格都不需要定义，可以用代码来表示```url/?imageView2/2/w/250/h/250/q/95```来表示```url!250x250```

# 使用七牛来部署你的Assets
使用又拍云的小伙伴们完全可以参照[《在 Rails 项目里面使用又拍云用于存储上传图片》](http://huacnlee.com/blog/rails-app-image-store-with-carrierwave-upyun/#cdn-asset-files)来配置，本人亲自使用，没有问题，太棒了！

* ```config/environments/production.rb``` - 将 config.action_controller.asset_host = 七牛空间域名
* 在七牛的官网下载qrsync的上传工具
* 创建lib/tasks/assets/cdn.rake文件:

```ruby
require 'ftp_sync'
namespace :assets do
  desc 'sync assets to cdns'
  task :cdn => :environment do 

    # 主要为了生成cdn_conf.json, 可以考虑template来生成
    f = File.new("#{Rails.root}/cdn_conf.json", "w+")
    conf = "{ \n"
    conf += "\"src\":\"#{Rails.root}/public/assets/\",\n"
    conf += "\"dest\":\"qiniu:access_key=#{ ENV['qiniu_access_key'] }&secret_key=#{ ENV['qiniu_secret_key'] }&bucket=空间名&key_prefix=assets/\",\n"
    conf += "\"deletable\":    0,\n"
    conf += "\"debug_level\":  1\n"
    conf += " }"
    f.write conf
    f.close

    system("/root/qiniu_tool/qrsync #{Rails.root}/cdn_conf.json") # 注意qrsync路径
  end
end
```

* config/deploy.rb - 在 Capistrano 的部署过程中，加入 rake assets:cdn

PS：存储Assets文件，要选择文件空间；当你在 rake assets:precomplie 编译出 Assets 文件以后，就可以执行 rake assets:cdn 将预编译好的 Assets 文件同步到七牛里面了。

# 使用HTTPS的CDN加速

七牛的存储内容已经融合了CDN加速了，但是在HTTP的CDN，所以如果你不是HTTPS的话，请忽略这一节内容。

如果你有幸开启了HTTPS，千万别忘记了申请泛域名的HTTPS，因为你要留有其中两个给七牛作为HTTPS的自定义域名，一个图片空间，一个Assets空间，这样算下来，泛域名的HTTPS比较合算。七牛配置比较简单，这里不讲解，不懂得可以提出工单。

配置完之后，每个自定义加速域名都会有CNAME，在域名解析中添加一条CNAME，记录值填写七牛给你的CNAME，然后项目里的静态文件的url就可以是自定义的域名了。

想要看看你的CDN评分，通过[【性能魔方】](http://www.mmtrix.com/evaluate/applist)这个来评测，免费的，超好用。

# 引用
[《在 Rails 项目里面使用又拍云用于存储上传图片》](http://huacnlee.com/blog/rails-app-image-store-with-carrierwave-upyun)
