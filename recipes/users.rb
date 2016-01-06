#
# Cookbook Name:: chef_vault_users
# Recipe:: users
#
# Copyright (C) 2014 zeroXten
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

ohai 'reload_passwd' do
  action :nothing
  plugin 'etc'
end

node.users.each_pair do |username, attr|

  user_action = attr.has_key?('action') ? attr['action'].to_sym : :nothing
  user_is_active = [:create, :manage, :modify, :unlock].include?(user_action)

  if user_is_active and attr.has_key?('password') 

    case attr['password']
      when String
        password = attr['password']
      when TrueClass
        if Chef::Config[:solo]
          password = 'dummy_solo_password'
        else
          chef_gem 'chef-vault'
          require 'chef-vault'
          chef_gem 'ruby-shadow'
          password = ChefVault::Item(node.chef_vault_users.databag, username)['password']
        end
    end

    if attr.has_key?('password_is_plain') and attr['password_is_plain']
      chef_gem 'unix-crypt'
      require 'unix_crypt'
      password = UnixCrypt::SHA512.build(password)
    end
  else
    password = nil
  end

  user username do
    comment attr.has_key?('comment') ? attr['comment'] : username
    uid attr.has_key?('uid') ? attr['uid'] : nil
    gid attr.has_key?('gid') ? attr['gid'] : nil
    home attr.has_key?('home') ? attr['home'] : "/home/#{username}"
    shell attr.has_key?('shell') ? attr['shell'] : node['chef_vault_users']['default_shell']
    system attr.has_key?('system') ? attr['system'] : false
    action user_action
    password password
    supports :manage_home => (attr.has_key?('manage_home') ? attr['manage_home'] : true)
    notifies :reload, "ohai[reload_passwd]", :immediately
  end

  directory "create #{username} .ssh" do
    path "/home/#{username}/.ssh"
    owner username
    group username
    mode 0700
    action :create
    only_if { user_is_active and attr.has_key?('ssh_keys') }
  end
  
  file "create #{username} authorized_keys" do
    path "/home/#{username}/.ssh/authorized_keys"
    owner username
    group username
    mode 0600
    action :create
    content [attr['ssh_keys']].flatten.join("\n") 
    only_if { user_is_active and attr.has_key?('ssh_keys') }
  end

  file "create #{username} authorized_keys" do
    path "/home/#{username}/.ssh/authorized_keys"
    action :delete
    not_if { user_is_active }
  end

  directory "delete #{username}" do
    path "/home/#{username}"
    action :delete
    recursive true
    only_if { user_action == :remove }
  end

end
