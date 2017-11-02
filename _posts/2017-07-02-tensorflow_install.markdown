---
layout: post
title: Tensorflow说明与安装
subtitle: "tensorflow install"
categories: [rails]
---

# Tensorflow是说明？

TensorFlow深度学习框架

Google不仅是大数据和云计算的领导者，在机器学习和深度学习上也有很好的实践和积累，在2015年年底开源了内部使用的深度学习框架TensorFlow。

与Caffe、Theano、Torch、MXNet等框架相比，TensorFlow在Github上Fork数和Star数都是最多的，而且在图形分类、音频处理、推荐系统和自然语言处理等场景下都有丰富的应用。最近流行的Keras框架底层默认使用TensorFlow，著名的斯坦福CS231n课程使用TensorFlow作为授课和作业的编程语言，国内外多本TensorFlow书籍已经在筹备或者发售中，AlphaGo开发团队Deepmind也计划将神经网络应用迁移到TensorFlow中，这无不印证了TensorFlow在业界的流行程度。

现在如果你还有兴趣了解，请点击[TensorFlow深度学习，一篇文章就够了](http://blog.jobbole.com/105602/)开始学习之旅。
下面讲解ruby 使用tensorflow的方法：

# 要求

Ruby version > 2.2.0

## Install Bazel

[Bazel Installation](https://docs.bazel.build/versions/master/install.html)

举个例子，在ubuntu环境下安装:

```
sudo apt-get install openjdk-8-jdk
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update && sudo apt-get install oracle-java8-installer
echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install bazel
```

## Install Tensorflow

[Tensorflow Installation](https://www.tensorflow.org/install/install_linux)

```
sudo apt-get install python-pip python-dev python-virtualenv
virtualenv --system-site-packages targetDirectory
cd targetDirectory
source ./bin/activate
  easy_install -U pip
  pip install --upgrade tensorflow
  pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.3.0-cp27-none-linux_x86_64.whl
```

## Clone and Install TensorFlow

具体的参数可以修改，如果需要支持，需要安装一些依赖的库

```
git clone --recurse-submodules https://github.com/tensorflow/tensorflow
cd tensorflow
./configure
  Please specify the location of python. [Default is /usr/bin/python]: /usr/bin/python
  Please input the desired Python library path to use.  Default is [/usr/local/lib/python2.7/dist-packages] /usr/local/lib/python2.7/dist-packages
  Do you wish to build TensorFlow with jemalloc as malloc support? [Y/n]: Y
  Do you wish to build TensorFlow with Google Cloud Platform support? [Y/n]: Y
  Do you wish to build TensorFlow with Hadoop File System support? [Y/n]: Y
  Do you wish to build TensorFlow with Amazon S3 File System support? [Y/n]: Y
  Do you wish to build TensorFlow with XLA JIT support? [y/N]: N
  Do you wish to build TensorFlow with GDR support? [y/N]: N
  Do you wish to build TensorFlow with VERBS support? [y/N]: N
  Do you wish to build TensorFlow with OpenCL support? [y/N]: N
  Do you wish to build TensorFlow with CUDA support? [y/N]: N
  Do you wish to build TensorFlow with MPI support? [y/N]: N
  Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -march=native]: -march=native

bazel build -c opt //tensorflow:libtensorflow.so  

# Linux
sudo cp bazel-bin/tensorflow/libtensorflow.so /usr/lib/
sudo cp bazel-bin/tensorflow/libtensorflow_framework.so /usr/lib/ #官网不需要执行这一步骤，我亲自验证不执行会出错

# OSX
sudo cp bazel-bin/tensorflow/libtensorflow.so /usr/local/lib
export LIBRARY_PATH=$PATH:/usr/local/lib (may be required)

```

## Install Swig

[安装包](http://www.swig.org/download.html)

```
tar -zxvf swig-3.0.12.tar.gz
cd swig-3.0.12
./configure
make
make install
```

## Install tensorflow.rb

```
git clone https://github.com/somaticio/tensorflow.rb.git
cd tensorflow.rb/ext/sciruby/tensorflow_c
(rvm use 2.2.2)
ruby extconf.rb (如果出错，则没安装swig)
make
make install # Creates ../lib/ruby/site_ruby/X.X.X/<arch>/sciruby/Tensorflow.{bundle, so}
cd ./../../..
bundle install  (可以Gemfile修改为source 'https://ruby.taobao.org')
bundle exec rake install
```

https://storage.googleapis.com/download.tensorflow.org/models/inception5h.zip下载后解压

将imagenet_comp_graph_label_strings.txt和tensorflow_inception_graph.pb放在tensorflow.rb/image目录下

## Test

```
cd tensorflow.rb/image && rvm 2.2.0
ruby classify_image.rb
```

结果:

```
I tensorflow/core/platform/cpu_feature_guard.cc:137] Your CPU supports instructions that this TensorFlow binary was not compiled to use: SSE4.1 SSE4.2 AVX
Trying to classify image file: ./mysore_palace.jpg
The top five results are 
palace
0.7095823287963867
monastery
0.14657701551914215
mosque
0.08988487720489502
church
0.01842896267771721
bell cote
0.012109429575502872
castle
0.007050110027194023
```

## grape-on-rack

将Tensorflow搭建成Grape接口，作为rack的app, Ruby Version >= 2.2.0

执行bundle install, Gemfile如下：

```
source 'https://ruby.taobao.org'

ruby '2.2.2'

gem 'grape', '~> 0.16'
gem 'grape-entity'
gem 'grape-swagger'
gem 'grape-swagger-entity'
gem 'json'
gem 'rack-cors'
gem 'mime-types'
gem 'nokogiri'

gem 'listen', '3.1.1'
gem 'tensorflow', '0.0.1'
gem 'grape_logging', '1.2.1'

group :development do
  gem 'rake'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rack'
  gem 'rubocop'
end
```

app/biaker_app.rb文件：

```
module Biaker
  class App
    def initialize
      @filenames = ['', '.html', 'index.html', '/index.html']
      @rack_static = ::Rack::Static.new(
        lambda { [404, {}, []] },
        root: File.expand_path('../../public', __FILE__),
        urls: ['/']
      )
    end

    def self.instance
      @instance ||= Rack::Builder.new do
        use Rack::Cors do
          allow do
            origins '*'
            resource '*', headers: :any, methods: :get
          end
        end

        run Biaker::App.new
      end.to_app
    end

    def call(env)
      # api
      response = Biaker::API.call(env)

      # Check if the App wants us to pass the response along to others
      if response[1]['X-Cascade'] == 'pass'
        # static files
        request_path = env['PATH_INFO']
        @filenames.each do |path|
          response = @rack_static.call(env.merge('PATH_INFO' => request_path + path))
          return response if response[0] != 404
        end
      end

      # Serve error pages or respond with API response
      case response[0]
      when 404, 500
        content = @rack_static.call(env.merge('PATH_INFO' => "/errors/#{response[0]}.html"))
        [response[0], content[1], content[2]]
      else
        response
      end
    end
  end
end
```

app/api.rb文件：

```
module Biaker
  class API < Grape::API
    prefix 'api'
    format :json

    # log
    logfile = File.open('log/api.log', 'a')
    logfile.sync = true
    logger Logger.new GrapeLogging::MultiIO.new(STDOUT, logfile)
    use GrapeLogging::Middleware::RequestLogger, logger: logger, format: GrapeLogging::Formatters::Default.new
    
    # 接收所抛出的异常, 状态码为404
    rescue_from :all do |e|
      API.logger.error e  #error log
      error! e.message, 404
    end
    

    helpers do
      def render_json(data, total = nil, msg = 'OK', code = 200)
        present({msg: msg, code: code, total: total, data: data})
      end
    end


    mount ::Biaker::ImageRecognition
    add_swagger_documentation api_version: 'v1'
  end
end
```

此时可以参照tensorflow.rb/image/classify_image.rb文件，建立一个接口，api/image recognition.rb文件如下：

注意tensorflow_inception_graph.pb 和 imagenet_comp_graph_label_strings.txt文件的存放位置

```
module Biaker
  class ImageRecognition < Grape::API
    format :json
    desc '图案识别.'
    resource :image_recognitions do
      params do
        requires :path, type: String, desc: '必须是本地图片的path，不能是图片url'
      end
      post do
        require 'tensorflow'
        scope_class = Tensorflow::Scope.new
        image_file = params[:path]
        raise ArgumentError, "Cannot find image file: #{image_file}" unless File.file?(image_file)

        input = Const(scope_class, image_file)
        output = input.operation.g.AddOperation(Tensorflow::OpSpec.new('ReadFile', 'ReadFile', nil, [input]))
        output = input.operation.g.AddOperation(Tensorflow::OpSpec.new('DecodeJpeg', 'DecodeJpeg', Hash['channels' => 3], [output.output(0)]))
        output = input.operation.g.AddOperation(Tensorflow::OpSpec.new('Cast', 'Cast', Hash['DstT' => 1], [output.output(0)]))
        output = input.operation.g.AddOperation(Tensorflow::OpSpec.new('ExpandDims', 'ExpandDims', nil, [output.output(0), Const(scope_class.subscope('make_batch'), 0, :int32)]))
        output = input.operation.g.AddOperation(Tensorflow::OpSpec.new('ResizeBilinear', 'ResizeBilinear', nil, [output.output(0), Const(scope_class.subscope('size'), [224, 224], :int32)]))
        output = input.operation.g.AddOperation(Tensorflow::OpSpec.new('Sub', 'Sub', nil, [output.output(0), Const(scope_class.subscope('mean'), 117.00, :float)]))
        output = input.operation.g.AddOperation(Tensorflow::OpSpec.new('Div', 'Div', nil, [output.output(0), Const(scope_class.subscope('scale'), 1.00, :float)])).output(0)
        graph = scope_class.graph
        session_op = Tensorflow::Session_options.new
        session = Tensorflow::Session.new(graph, session_op)
        out_tensor = session.run({}, [output], [])

        # Run inference on *imageFile.
        # For multiple images, session.Run() can be called in a loop (and
        # concurrently). Alternatively, images can be batched since the model
        # accepts batches of image data as input.
        graph = Tensorflow::Graph.new
        graph.read_file('/home/liwen/桌面/tensorflow.rb/image/tensorflow_inception_graph.pb')
        tensor = Tensorflow::Tensor.new(out_tensor[0], :float)
        sess = Tensorflow::Session.new(graph)
        hash = {}
        hash[graph.operation('input').output(0)] = tensor

        # predictions is a vector containing probabilities of
        # labels for each image in the "batch". The batch size was 1.
        # Find the most probably label index.
        predictions = sess.run(hash, [graph.operation('output').output(0)], [])

        predictions.flatten!
        labels = {}
        j = 0
        File.foreach('/home/liwen/桌面/tensorflow.rb/image/imagenet_comp_graph_label_strings.txt') do |line|
            labels[line] = predictions[j]
            j += 1
        end
        result = labels.sort { |a, b| b[1].to_f <=> a[1].to_f }
        render_json result[0..5]
      end
    end
  end
end
```

最后启动rackup：

```
rackup -D -p 9300 -P ./tmp/pids/tensorflow.pid
```

可以在终端执行：

```
curl -X POST -i -F path=/...绝对路径.../mobile.png http://localhost:9300/api/image_recognitions
```

或者在其他rails项目中调用此接口：

```
uri = URI('http://localhost:9300/api/image_recognitions')
data = { path: '/...绝对路径.../mobile.png' }
res = Net::HTTP.post_form(uri, data)
result = JSON.parse(res.body)

# result => {"msg"=>"OK", "code"=>200, "total"=>nil, "data"=>[["palace\n", 0.7095823287963867], ["monastery\n", 0.14657701551914215], ["mosque\n", 0.08988487720489502], ["church\n", 0.01842896267771721], ["bell cote\n", 0.012109429575502872], ["castle\n", 0.007050110027194023]]}
```
