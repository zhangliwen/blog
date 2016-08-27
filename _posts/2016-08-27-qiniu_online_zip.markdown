---
layout: post
title: 在七牛服务器上压缩文件
subtitle: "qiniu online-zip"
categories: [rails]
---

# 需求

在类似一个ERP系统中，需要导出批量订单数据以及每个订单有若干加工图片，订单数据生成Excel。如果图片是存储在本地服务器，我想要实现这个挺简单的，使用[rubyzip](https://github.com/rubyzip/rubyzip)就可以轻松解决，这里就直接跳过。我们来谈谈，如果图片是放在云储存中，如何实现zip压缩？

# ZIP的方案

* 方案一：[rubyzip](https://github.com/rubyzip/rubyzip) 是不支持非本地图片的压缩，也许你会想到，将需要压缩的图片全部下载到本地，而后再进行压缩，可以写一个worker完成整个业务。 

缺点很明显，需要下载全部图片后，才能开始zip，增加等待时间，并且需要一定的存储空间和内存开销。

* 方案二：使用[zipline](https://github.com/fringd/zipline)，压缩的文件路径可以是url。这是通过open-uri获取到文件流，然后再进行压缩，同样也支持延迟执行。当然，要像unicorn/rainbows或者其他支持streaming的服务器，才能使用。

这个就是方案一的改良版，有效的解决了方案一突出的问题。然而，如果有没有更优的方案？有没有可能不需要使用服务器的CPU就能完成压缩？答案是肯定的，七牛有提供这样的功能，又拍云和OSS有没有，就未可知了。

* 方案三：七牛提供了[多文件压缩(mkzip)](http://developer.qiniu.com/docs/v6/api/reference/fop/mkzip.html)功能，提供了批量文件的压缩存储功能，可以将若干七牛空间的资源通过七牛后端压缩后储存在七牛空间内，需要下载时，还融合CDN加速进行下载。是不是觉得这个方案太棒了？

# 代码(方案一跳过)

方案二：

* controller.rb

```ruby
  require 'reset_open_uri'  # 作用下列会介绍，关于图片小于10KB而造成的错误

  zipfile_name = "target.zip"
  zipfile_url = "tmp/zip/#{ zipfile_name }"
  Zip.unicode_names = true  # 解决解压后中文文件名乱码问题
  excel_path = "tmp/zip/excel.xls"  # 可以是实时生成

  Zip::File.open(zipfile_url, Zip::File::CREATE) do |zipfile|
    zipfile.add("excel.xls", excel_path)

    zipfile.mkdir('图片') # 在压缩文件中，生成叫【图片】的文件夹
    image_datas = [{ name: '图片1', url: 'http://www.qiniu.com/image1.png' }, { name: '图片2', url: 'http://www.qiniu.com/image2.png' }]
    zipfile_add_img(zipfile, '图片', image_datas)
  end
  send_data open(zipfile_url).read, filename: zipfile_name, type: "application/zip", disposition: 'inline', stream: 'true'

  def zipfile_add_img zipfile, file_name, urls
    return if urls.blank?
    urls.each do |img_data|
      file = open(img_data[:url])
      zipfile.add("#{ zipfile.get_entry(file_name).name }#{ img_data[:name] }.png", file)
    end
  end
```
  
* lib/reset_open_uri.rb

```ruby
  # 如果图片小于10KB，file的类型就不再是Tempfile，而是StringIO，而StringIO是不能打包的，强制将10KB降低到0KB
    require 'open-uri'
    # Don't allow downloaded files to be created as StringIO. Force a tempfile to be created.
    OpenURI::Buffer.send :remove_const, 'StringMax' if OpenURI::Buffer.const_defined?('StringMax')
    OpenURI::Buffer.const_set 'StringMax', 0
```

方案三：
先将实时生成的excel.xle上传到指定空间，然后在压缩。注意：压缩的资源必须在同一个空间内才行，否则出错。
mkzip文档请参照：[mkzip](http://developer.qiniu.com/docs/v6/api/reference/fop/mkzip.html)

* 生成一个model，作为压缩记录：rails g model mkzip_record

```ruby
    create_table :mkzip_records do |t|
      t.integer :user_id
      t.string :title
      t.string :persistent_id
      t.string :finish_time
      t.string :url
      t.string :desc

      t.timestamps
    end
```

* controller.rb

```ruby
    zipfile_name = "target.zip"
    record = MkzipRecord.search(url_cont: zipfile_name).result.first  # 如果已存在，就无需再生成
    if record.nil?
      excel_path = "tmp/zip/excel.xls"  # 可以是实时生成
      code, result, res_headers = Qiniu::Storage.upload_with_token_2( get_qiniu_uptoken("excel.xls"), excel_path, "excel.xls")  #上传到七牛

      image_datas = [{ name: '图片1', url: 'http://www.qiniu.com/image1.png' }, { name: '图片2', url: 'http://www.qiniu.com/image2.png' }]
      image_datas << { name: 'excel', url: "#{ $cloud_storage }#{ result['key'] }" }
      record = MkzipRecord.create_mkzip(image_datas, zipfile_name, "加工单", current_user.id)
    end
```
  
* models/mkzip_record.rb

```ruby

    # tag_bucket: 压缩完的zip存储的七牛空间名; image_bucket: 图片和excel所在的空间名
    # 七牛的pipeline不可缺少，先申请
    def self.create_mkzip urls, zip_name, title, user_id = nil, tag_bucket = 'zipfile'
      image_bucket, key, pipeline, url_encodes = 'sdimage', 'pipeline', 'pipeline', ''
      notify_url = "#{ $domain }payments/qiniu_mkzip_notify"

      urls.each do |u| 
        url_encodes += '/url/' + Qiniu::Utils.urlsafe_base64_encode(u[:url])
        url_encodes += '/alias/' + Qiniu::Utils.urlsafe_base64_encode("#{ u[:name] }.#{ u[:url].split('.').last }") unless u[:name].blank?
      end

      fops = 'mkzip/2' + url_encodes
      saveas_key = Qiniu::Utils.urlsafe_base64_encode("#{ tag_bucket }:#{ zip_name }")
      fops = fops+'|saveas/'+ saveas_key
      pfops  = Qiniu::Fop::Persistance::PfopPolicy.new( image_bucket, key, fops, notify_url)
      pfops.pipeline = pipeline
      code, result, res_headers = Qiniu::Fop::Persistance.pfop(pfops)
      return unless code == 200

      create(user_id: user_id, title: title, persistent_id: result['persistentId'], url: "#{ $zip_storage }#{ zip_name }")
    end
```
    
* initializers/qiniu_sdk.rb

```ruby
    #!/usr/bin/env ruby
    require 'qiniu'
    Qiniu.establish_connection! :access_key => ENV['qiniu_access_key'], :secret_key => ENV['qiniu_secret_key'] 
    
```
然后就大功告成，唯一一个缺点就是：zip的中文名乱码
