---
layout: post
title: Monit - 监控你的服务器
subtitle: "monitor your unix system"
categories: [ssl]
---

# 背景

服务器需要安装一个监控，用于监控每个服务的运行状况，内存、CPU、时间、交换空间等信息（可以自行配置）。经过Monit、god、eye之间，我选择了monit。其有点是占用内存小，而且基于unix与ruby无关。

monit在设置邮箱信息之后，当服务运行数据超过设置的参数数据时，会自动发出邮件的警报信息。

# Installation

在官网https://mmonit.com/monit/下载Source code的tar.gz文件，解压后执行：

```shell
 cd monit
 ./configure
 make
 make install
```

# Setting
本人使用自动部署工具[capistrano3](https://github.com/capistrano/capistrano),这里介绍monit + capistrano3的配置：

在config/deploy.rb文件中，添加：

```
...
load 'config/recipes/monit.rb'  # 监控参数的配置，警报
load 'config/recipes/mysh.rb'   #通过shell来完成服务开启和关闭
load 'config/recipes/base.rb'   #定义monit全局方法

set :monit_port, 2000
set :monit_password, '***'

# 自动发邮件警报
set :gmail_username, '***'
set :gmail_password, '***'

...
```

在config中添加一个文件夹：recipes

recipes/monit.rb

```ruby
namespace :monit do

  desc 'Server setup tasks'
  task :setup do
    invoke 'mysh:setup'

    # 这里的monit:*_config的配置文件，都存放在lib/templates/monit/文件夹中
    invoke 'monit:monitrc_config'
    invoke 'monit:nginx_config'
    invoke 'monit:redis_config'
    invoke 'monit:sidekiq_config'
    invoke 'monit:solr_config'
    invoke 'monit:unicorn_config'

    invoke 'monit:syntax'
    invoke 'monit:reload'
  end

  %w[monitrc nginx redis sidekiq solr unicorn].each do |name|
    desc "Generate config file for #{ name } process"
    task "#{ name }_config" do
      on roles :app do
        upload! monit_template(name), tmp_path(name)
        final_path(name)
      end
    end
  end

  %w[start stop restart syntax reload].each do |command|
    desc "Run Monit #{command} script"
    task command do
      on roles :app do
        execute :sudo, "service monit #{command}"
      end
    end
  end
  after 'deploy:started', 'monit:reload'

end

```

recipes/mysh.rb文件

```ruby
namespace :mysh do

  task :setup do
    invoke :'mysh:thin'
    invoke :'mysh:sidekiq'
    invoke :'mysh:redis-server'
    invoke :'mysh:solr'
    invoke :'mysh:unicorn'

    %w[startRedis.sh].each do |name|
      on roles :app do
        upload! mysh_template(name), tmp_path(name)
        execute :sudo, :chmod, "a+x #{tmp_path(name)}"
      end
    end
  end

  %w[thin sidekiq redis-server solr unicorn].each do |name|
    desc "Generate shell file for #{ name } start shell"
    task name do
      on roles :app do
        upload! mysh_template("#{ name }.sh"), tmp_path("#{ name }.sh")
        execute :sudo, :chmod, "a+x #{tmp_path("#{ name }.sh")}"
        execute :sudo, :cp, "#{tmp_path("#{ name }.sh")} /etc/init.d/#{ name }" if %w[sidekiq redis-server].include?(name)
      end
    end
  end
  
end
```

recipes/base.rb文件

```ruby
def monit_template(template_name)
  menu_path = File.expand_path('../../../lib/templates/monit', __FILE__)
  main_menu_template = ERB.new(File.read("#{menu_path}/#{ template_name }.erb"))
  StringIO.new main_menu_template.result(binding)
end

def mysh_template(template_name)
  menu_path = File.expand_path('../../../lib/templates/mysh', __FILE__)
  main_menu_template = ERB.new(File.read("#{menu_path}/#{ template_name }.erb"))
  StringIO.new main_menu_template.result(binding)
end

def tmp_path(process_name)
  "/tmp/#{process_name}"
end

def final_path(name, path = nil)
  path ||= "/etc/monit/conf.d/#{name}.conf"

  execute :sudo, :chmod, "644 #{tmp_path(name)}"
  execute :sudo, :mv, "#{tmp_path(name)} #{path}"
  execute :sudo, :chown, "root #{path}"
  execute :sudo, :chmod, "644 #{path}"
end
```

在lib/templates/monit/文件夹下定义各个服务的监控参数,列举几个，如：

lib/templates/monit/monitrc.erb

```ruby
set daemon 30

set logfile /var/log/monit.log
set idfile /var/lib/monit/id
set statefile /var/lib/monit/state

set eventqueue
  basedir /var/lib/monit/events
  slots 100

set mailserver smtp.gmail.com port 587
  username "<%= fetch :gmail_username %>" 
  password "<%= fetch :gmail_password %>"
  using tlsv1
  with timeout 30 seconds

<%= "set alert #{fetch(:monit_alert_email)}" unless fetch(:monit_alert_email).nil? %>

<% unless fetch(:monit_password).nil? %>
  set httpd port <%= fetch :monit_port %>
  allow admin:"<%= fetch :monit_password %>"
<% end %>
```

nginx.erb

```ruby
check process nginx with pidfile /var/run/nginx.pid
  start program = "/etc/init.d/nginx start"
  stop program = "/etc/init.d/nginx stop"
  if children > 250 then restart
```

unicorn.erb

```ruby
check process <%= fetch :unicorn_process_name %> with pidfile <%= fetch :unicorn_pid %>
  start = "/bin/bash <%= fetch(:unicorn_sh)%> start" as uid <%= fetch(:user) %> and gid <%= fetch(:user) %>
  stop = "/bin/bash <%= fetch(:unicorn_sh)%> stop"
  if memory usage > 30% for 1 cycles then restart
  if cpu > 48% for 3 cycles then restart
  

<% fetch(:unicorn_workers_number).times do |n| %>
  <% pid = fetch(:unicorn_pid).sub(".pid", ".#{n}.pid") %>
  check process <%= fetch :unicorn_worker_name %><%= n %> with pidfile <%= pid %>
    stop program = "/usr/bin/test -s <%= pid %> && /bin/kill -QUIT `cat <%= pid %>`"
<% end %>
```

sidekiq.erb

```ruby
check process sidekiq
  with pidfile <%= fetch(:sidekiq_pid)%>
  start program = "/etc/init.d/sidekiq start" with timeout 90 seconds
  stop program = "/etc/init.d/sidekiq stop" with timeout 90 seconds
```

solr.erb

```ruby
check process solr
  with pidfile <%= fetch(:solr_pid)%>
  start = "/bin/bash <%= fetch(:solr_sh)%> start"
  stop = "/bin/bash -c '/bin/sh <%= fetch(:solr_sh)%> stop'"
```

在lib/templates/mysh/文件夹里，存放的是通过shell启动的服务启动器，如：

lib/templates/mysh/sidekiq.sh.erb

```
#!/bin/bash
start () {
  cd <%= current_path %> && ( RVM_BIN_PATH=<%= fetch(:rvm_home)%>/bin/rvm/bin <%= fetch(:rvm_home)%>/bin/rvm <%= fetch(:rvm_ruby_version)%> do bundle exec sidekiq --index 0 --pidfile <%= fetch(:sidekiq_pid)%> --environment RAILS_ENV=<%= fetch(:rails_env)%> --logfile <%= fetch(:sidekiq_log)%> --daemon )
}

stop () {
  cd <%= current_path %> && ( RVM_BIN_PATH=<%= fetch(:rvm_home)%>/bin/rvm/bin <%= fetch(:rvm_home)%>/bin/rvm <%= fetch(:rvm_ruby_version)%> do bundle exec sidekiqctl stop <%= fetch(:sidekiq_pid)%> 10 )
}

case $1 in
  start)
    start
  ;;
  stop)
    stop
  ;;
  *)
  echo $"Usage: $0 {start|stop}"
  exit 1
  ;;
esac

exit 0
```

lib/templates/mysh/solr.sh.erb

```
#!/bin/bash
start () {
  cd <%= current_path%> && ( RVM_BIN_PATH=<%= fetch(:rvm_home)%>/bin/rvm/bin RAILS_ENV=<%= fetch(:rails_env)%> <%= fetch(:rvm_home)%>/bin/rvm <%= fetch(:rvm_ruby_version)%> do bundle exec rake sunspot:solr:start
}

stop () {
  cd <%= current_path%> && ( RVM_BIN_PATH=<%= fetch(:rvm_home)%>/bin/rvm/bin RAILS_ENV=<%= fetch(:rails_env)%> <%= fetch(:rvm_home)%>/bin/rvm <%= fetch(:rvm_ruby_version)%> do bundle exec rake sunspot:solr:stop
}

case $1 in
  start)
    start
  ;;
  stop)
    stop
  ;;
  *)
  echo $"Usage: $0 {start|stop}"
  exit 1
  ;;
esac

exit 0
```

lib/templates/mysh/unicorn.sh.erb

```
#!/bin/bash

# Set the environment, as required by Monit
export GEM_PATH="<%= fetch(:rvm_home) %>/gems/<%= fetch(:rvm_ruby_version) %>:<%= fetch(:rvm_home) %>/gems/<%= fetch(:rvm_ruby_version) %>@global"
export GEM_HOME="<%= fetch(:rvm_home) %>/gems/<%= fetch(:rvm_ruby_version) %>"

start () {
  cd <%= current_path %> && ( RVM_BIN_PATH=<%= fetch(:rvm_home)%>/bin/rvm/bin RAILS_ENV=<%= fetch(:rails_env)%> BUNDLE_GEMFILE=<%= current_path%>/Gemfile <%= fetch(:rvm_home)%>/bin/rvm <%= fetch(:rvm_ruby_version)%> do bundle exec unicorn -c <%= fetch(:unicorn_config_path)%> -E <%= fetch(:rails_env)%> -D  )
}

stop () {
  cd <%= current_path %> && ( RVM_BIN_PATH=<%= fetch(:rvm_home)%>/bin/rvm/bin /usr/bin/env kill -s QUIT `cat <%= fetch(:unicorn_pid)%>` )
}

restart () {
  cd <%= current_path %> && ( RVM_BIN_PATH=<%= fetch(:rvm_home)%>/bin/rvm/bin /usr/bin/env kill -s USR2 `cat <%= fetch(:unicorn_pid)%>` )
  sleep 5
  cd <%= current_path %> && ( RVM_BIN_PATH=<%= fetch(:rvm_home)%>/bin/rvm/bin /usr/bin/env kill -s QUIT `cat <%= fetch(:unicorn_pid)%>` )
}

case $1 in
  start)
    start
  ;;
  stop)
    stop
  ;;
  restart)
    restart
  ;;
  *)
  echo $"Usage: $0 {start|stop|restart}"
  exit 1
  ;;
esac

exit 0
```

效果如图所示：
![](https://sources.biaker.com/pattern/image_url/biaker_20171031182540.png)
![](https://sources.biaker.com/pattern/image_url/biaker_20171031182721.png)
