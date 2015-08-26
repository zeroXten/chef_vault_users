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
  plugin 'etc'
end


node.groups.each_pair do |groupname, attr|

  group groupname do
    gid attr.has_key?('gid') ? attr['gid'] : nil
    system attr.has_key?('system') ? attr['system'] : nil
    append attr.has_key?('append') ? attr['append'] : nil
    action attr.has_key?('action') ? attr['action'].to_sym : :create
    members attr.has_key?('members') ? attr['members'] : nil
  end

end
