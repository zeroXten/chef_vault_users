# chef\_vault\_users cookbook

Manage systems users with credentials stored in chef-vault.

# Requirements

Uses the [http://community.opscode.com/cookbooks/chef-vault](chef-vault) cookbook.

It also requires the following gems (installed automatically by chef):

* ruby-shadow
* unix-crypt

# Usage

## Chef-vault

The best way of using this cookbook is by storing user credentials securely using chef-vault.

Firstly, create an encrypted data bag using chef vault:

    $ knife vault blah

chef\_vault\_users looks at the users attribute for a hash of which users to manage. This means the chef-vault databag can be reused as it only stores username/password combinations.

The simplest usage uses all defaults

    override['users']['a_user']['password'] = true

This will read the password from the chef-vault databag with all attributes set to default values (see below).

For more control you can also define a user using attributes:

    override['chef_vault_users']['users']['a_user'] = { 
      'password' => true,
      'password_is_plain' => true,
      'uid' => 1005,
      'gid' => 1005
    }

In this case, we will get a plaintext password from chef-vault which will then be hashed using UnixCrypt::SHA512.build\(\).

If you omit 'password\_is\_plain' attribute, or set it to false, then we will expect to find a hashed password.

## Plain text password

Instead of using chef-vault, you can also specify the password directly.

    override['chef_vault_users']['users']['a_user']['password'] = 'mypassword'

## Password hash

You can also put a password hash directly in the attributes:

    override['chef_vault_users']['users']['a_user']['password'] = '$6$xxxxxxxxx$yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'

# Attributes

See `attributes/default.rb` for default values.

Main attributes:

* `node['users']` - The hash of users
* `node['chef_vault_users']['default_shell']` - The default shell for users 
* `node['chef_vault_users']['databag']` - Name of the default chef-vault data bag

You can add your user's ssh public keys to an array in:

* `node['users'][USERNAME]['ssh_keys']`

The following attributes are mapped onto the standard chef user resource:

* `node['users'][USERNAME]['comment']`
* `node['users'][USERNAME]['uid']`
* `node['users'][USERNAME]['gid']`
* `node['users'][USERNAME]['home']`
* `node['users'][USERNAME]['shell']`
* `node['users'][USERNAME]['system']`
* `node['users'][USERNAME]['action']`
* `node['users'][USERNAME]['manage_home']`

If you want to reuse the user configuration, consider putting it in a role or a users cookbook.
