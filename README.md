# HAProxy Load Balancer

HAProxy docker container with Lua, ALPN and HTTP/2 support. based on [million12](https://github.com/million12/docker-haproxy) image

# Features

* **Support for HTTP/2** with ALPN
* CentOS 7 based
* Ability to **provide any arguments to haproxy** process  
  Any extra parameters provided to `docker run` will be passed directly to `haproxy` command.  
  For example, if you run `docker run [run options] f4group/haproxy -n 1000` you pass `-n 1000` to haproxy daemon.
* Pretty **lightweight**, only ~290M (with OpenSSL and HAProxy compiled from source).
* **Default [haproxy.cfg](container-files/etc/haproxy/haproxy.cfg) provided** for demonstration purposes. You can easily mount your own or point to different location using `HAPROXY_CONFIG` env.
* **Auto restart when config changes**  
  This container comes with inotify to monitor changes in HAProxy config and **reload** HAProxy daemon. The reload is done in a way that no connection is lost.
* Lua, to be able to use [haproxy-acme-validation-plugin](https://github.com/janeczku/haproxy-acme-validation-plugin)

## ENV variables

**HAPROXY_CONFIG**  
Default: `HAPROXY_CONFIG=/etc/haproxy/haproxy.cfg`  
If you mount your config to different location, simply edit it.


## Usage

### Basic

`docker run -ti -p 80:80 -p 443:443 f4group/haproxy`

### Mount custom config , override some options

`docker run -d -p 80:80 -v /my-haproxy.cfg:/etc/haproxy/haproxy.cfg f4group/haproxy -n 10000`  
Note: in this case config is mounted to its default location, so you don't need to modify `HAPROXY_CONFIG` variable.

### Check version and build options

`docker run -ti f4group/haproxy -vv`

### Stats
The default URL for stats is `http://CONTAINER_IP/admin?stats` with username:password ser to `admin:admin`.

## Authors

Author: Marcin ryzy Ryzycki (<marcin@m12.io>)  
Author: Przemyslaw Ozgo (<linux@ozgo.info>)
