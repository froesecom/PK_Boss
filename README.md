# PK Boss
A simple command line script to manage public keys via ssh, using Elixir. It allows you to manage public keys for multiple servers in one location.

## Installation
This script requires Elixir. Installation instructions can be [found here.](http://elixir-lang.org/install.html)

## Setup
- For each server you want to manage, create a file in the pk_boss/auth_keys directory. The name of the file should be the IP address of the server.
- Add cofiguration of Module attributes to the pk_boss.exs file:
```elixir
@remote_auth_keys_path "/remote/path/to/auth_keys/file"
@local_auth_keys_dir "/local/path/to/pk_boss/auth_keys/dir"
@remote_user "root"
```

##Usage
To add a key to all servers:

`elixir pk_boss.exs --add "key here"`

To remove a key from all servers:

`elixir pk_boss.exs --remove "key here"`

To add a key to one or more servers:
- Manually add the key to the file(s)
- Push all auth_key files to the servers:

`elixir pk_boss.exs --deploy-all`

To view help:

`elixir pk_boss.exs h`

##To do
- Add and remove a key from one or more auth key files

##Contributors
[@dtcristo](https://github.com/dtcristo)

[@Jayzz55](https://github.com/Jayzz55)


