---
layout: post
title: 实时显示用户在线情况与操作轨迹
subtitle: "show online users real time"
categories: [rails]
---

# Gems

* [Ahoy](https://github.com/ankane/ahoy)
* [Faye](faye.jcoglan.com/)
* [Redis](https://github.com/redis/redis-rb)

# Ahoy

Ahoy为追踪Visits和Events提供基础，作用与ruby、js或者原生app。

作用： 收集访客以及操作轨迹，作为分析数据中的元数据，可用于：搭建用户画像、分析平台布局、客服实时答疑、分析引流效果、分析活动效果等。

* Visits:
  当有人访问你的网站时，Ahoy创建一个visit记录，附带大量有用的访客信息:
  * 流量来源：referrer(上线url)，referring domain(上线域名), landing page(登录页面), search keyword(搜索关键字)
  * 访问地点：国家，省，城市，IP，经纬度
  * 技术：浏览器信息，操作系统OS，设备类型，屏幕大小
  * utm参数: source, medium, term, content, campaign
  Ahoy与User结合，访客登录用记录user id，获取User的详细信息
* Events
  用户浏览的页面、用户点击的所有按钮/链接，都能称之为一个事件，按事件顺序记录用户一段时间内的所有浏览和点击的操作轨迹。

* Installation:

  Add this line to your application’s Gemfile:

  ```
  gem 'ahoy_matey'
  ```

  And add the javascript file in app/assets/javascripts/application.js after jQuery.

  ```javascript
  //= require jquery
  //= require ahoy
  ```

  Choose a Data Store(PostgreSQL, MySQL, or SQLite数据库的请执行：)
  ```
  rails generate ahoy:stores:active_record
  rake db:migrate
  ```

  track events(load ahoy.js)：

  ```javascript
  ahoy.track("$click", {title: "图案详情按钮"});
  ahoy.track("$view", {title: "购物车页面"});
  ```

# Faye

Faye是一个pub/sub的消息推送系统:即发布及订阅功能。基于事件的系统中，Pub/Sub是目前广泛使用的通信模型，它采用事件作为基本的通信机制，提供大规模系统所要求的松散耦合的交互模式：订阅者以事件订阅的方式接收消息数据；发布者可将消息（数据）推送给指定的用户，同时还能拓展成广播形式。

Faye使用Thin作为它的webserver，配置方式如下（将Faye看成一个Rack）

```ruby
Faye::WebSocket.load_adapter('thin')
Faye.logger = Logger.new('log/faye.log')
faye_server = Faye::RackAdapter.new(
  :mount => '/faye', 
  :timeout => 60,
  :engine  => {                               #引擎使用redis
    :type  => Faye::Redis,
    :host  => 'localhost',
    :port => "6300",                          # redis端口
    :database => 15, 
    :password => ENV['REDIS_PASSWORD'],       #redis密码，可以没有
    :namespace => 'faye_redis' 
  }
)
faye_server.add_extension MessagesService.new #如果有拓展，使用add_extension

faye_server.on(:unsubscribe) do |client_id, channel|  #监听:取消订阅的client_id，代表下线
  OnlineRecord.mark_offline(client_id)
end

faye_server.on('disconnect') do |client_id|           #监听:无法连接的client_id，代表下线
  OnlineRecord.mark_offline(client_id)
end

run faye_server
```
通过```FAYE_ENV=production thin start -R faye.ru -p 4000```启动Thin服务器，Faye服务端搭建完毕。

**【Faye Client】**

faye的client如果想要接收到某个channel的聊天信息, 需要先subscribe这个channel

```javascript
var faye = new Faye.Client("localhost:9292/faye");

faye.subscribe('/chat/channelXX', function (data) {
  XXXXXXXXXXXXXx
})
```
在进行subscribe时候, 会使用特定的channel /meta/subscribe, 并且faye server会对faye client分配一个唯一的```client_id```,该client_id是关键,下面会用到

**【Publish Message】**

使用ruby后台发布消息


```ruby
def faye_pub channel, data
  uri = URI.parse("#{ domain_page }faye")
  data[:domain] = domain_page
  message = {:channel => channel, :data => data}
  Net::HTTP.post_form(uri, :message => message.to_json)
end

# channel => '/chat/channelXX/' + receiver.id
# data => { receiver_id: receiver_id, content: content, url: url }
faye_pub(channel, data)
```

添加一个model: online_record.rb，用于记录在线用户

```ruby
class OnlineRecord < ActiveRecord::Base
  belongs_to :visit
  belongs_to :user
  has_one :visit_user, :through => :visit, :source => 'user'
  has_many :ahoy_events, :through => :visit

  # 上线时，判断visit_id为唯一,一个visit可以有n个client
  # arg = { visit_id: '', client_id: '', user_id: 1 }
  def self.mark_online *arg
    _visit_ids = arg.map { |a| a['visit_id'] }
    records = where(visit_id: _visit_ids)
    records.update_all(state: 'online')
    other_visit_ids = _visit_ids - records.pluck('visit_id').map(&:to_s)
    create_datas = arg.select { |a| other_visit_ids.include?(a['visit_id']) }
    create_datas.each { |d| d[:state] = 'online' }
    create(create_datas)
  end

  # 下线时，寻找到响应的client_id来下线
  def self.mark_offline client_ids
    puts "mark_offline: #{ client_ids }"
    client_ids = [client_ids] unless client_ids.is_a?(Array)
    where(client_id: client_ids, state: 'online').update_all(state: 'offline')
  end

end

```

在前端文件pubjic.js添加：

```javascript
...
if(window.Faye){ 
    window.faye_client.addExtension({
        incoming: function(message, callback) {
            var visit_id = ahoy.getVisitId();
            message.ext = message.ext || {};
            message.ext.visit_id = visit_id;

            if(window.get_cookie('last_visit_id') != visit_id){
                window.set_cookie('last_visit_id', visit_id, Both.Config.faye_visit_hour);
                var data = { client_id: message.clientId, visit_id: visit_id };
                PC.post('/api/online_users/catch_online_users', data, function(){ });
            }
             
            callback(message);
        }
    });
}
...
```

为online_users开放一个接口：apis/online_user_api.rb

```ruby
class OnlineUserAPI < API

  resource :online_users do
    desc "记录在线用户" ,{
    	headers:{
    	  "Content-Type" => { description: "application/json", required: true }, 
    	  "Authorization" => {description: "Bearer *access_token*",required: true}
    	}
    }
    params do
  	  optional :client_id, type: String, desc: ""
  	  optional :visit_id, type: String, desc: ""
    end
    post :catch_online_users do
      guard!
      return if params[:client_id].blank? || params[:visit_id].blank?
      data = params_data
      data[:user_id] = current_user.id if is_login?
      track = OnlineRecord.mark_online(online_params(data))
      render_json 'ok'
    end

  end

  helpers do
    def online_params data
      ActionController::Parameters.new(data).permit(:client_id, :visit_id, :user_id)
    end
  end  
end

```

效果图如下：
![](https://sources.biaker.com/pattern/image_url/biaker_20171031160301.png)
