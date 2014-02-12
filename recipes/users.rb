#
# Cookbook Name:: chef_vault_users
# Recipe:: default
#
# Copyright (C) 2014 Burberry, LTD
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
  plugin 'passwd'
end

node['chef_vault_users'].to_hash.fetch('users') { {} }.each_pair do |username,attr|

  password = nil
  if attr.has_key?('password')

    chef_gem 'chef-vault'
    require 'chef-vault'
    chef_gem 'ruby-shadow'

    case attr['password']
      when String
        password = attr['password']
      when TrueClass
        password = ChefVault::Item('users', user)['password']
      when Hash
        password = ChefVault::Item(attr['password']['data_bag'], attr['password']['id'])['password']
      when Array
        password = ChefVault::Item(attr['password'][0], attr['password'][1])['password']
    end

    if attr.has_key?('password_is_plain') and attr['password_is_plain']
      chef_gem 'unix-crypt'
      require 'unix_crypt'
      case node['chef_vault_users']['default_password_hash'].upcase
        when 'DES'
          password = UnixCrypt::DES.build(password)
        when 'MD5'
          password = UnixCrypt::MD5.build(password)
        when 'SHA256'
          password = UnixCrypt::SHA256.build(password)
        else
          password = UnixCrypt::SHA512.build(password)
      end
    end
  end

  user username do
    comment attr.has_key?('comment') ? attr['comment'] : username
    uid attr.has_key?('uid') ? attr['uid'] : nil
    gid attr.has_key?('gid') ? attr['gid'] : nil
    home attr.has_key?('home') ? attr['home'] : "/home/#{username}"
    shell attr.has_key?('shell') ? attr['shell'] : node['chef_vault_users']['default_shell']
    system attr.has_key?('system') ? attr['system'] : false
    action attr.has_key?('action') ? attr['action'].to_sym : :create
    password password
    supports :manage_home => (attr.has_key?('manage_home') ? attr['manage_home'] : true)
    notifies :reload, "ohai[reload_passwd]", :immediately
  end

  directory "/home/#{username}/.ssh" do
    owner username
    group username
    mode 0700
    only_if { attr.has_key?('ssh_keys') }
  end

  file "/home/#{username}/.ssh/authorized_keys" do
    owner username
    group username
    mode 0600
    content [attr['ssh_keys']].flatten.join("\n") 
    only_if { attr.has_key?('ssh_keys') }
  end

end
