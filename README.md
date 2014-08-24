docker-baseimage
================

docker-baseimage base on phusion/baseimage-docker ... with the difference that only cover the image .. for build trusted repository on docker ... tools and other stuff remove from it ... sshd service at the moment will be commented out/or remove to try without it ... 

This image will be use to builds others image for quantumobject at the moment ....


use documentation from  
https://github.com/phusion/baseimage-docker 


More importand reference:


<a name="using"></a>
## Using docker-baseimage as base image

<a name="getting_started"></a>
### Getting started

The image is called `angelrr7702/docker-baseimage`, and is available on the Docker registry.

   
    FROM angelrr7702/docker-baseimage
    
    # Set correct environment variables.
    ENV HOME /root
    
    # Use baseimage-docker's init system.
    CMD ["/sbin/my_init"]
    
    # ...put your own build instructions here...
    
    # Clean up APT when done.
    RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

<a name="adding_additional_daemons"></a>
### Adding additional daemons

You can add additional daemons (e.g. your own app) to the image by creating runit entries. You only have to write a small shell script which runs your daemon, and runit will keep it up and running for you, restarting it when it crashes, etc.

The shell script must be called `run`, must be executable, and is to be placed in the directory `/etc/service/<NAME>`.

Here's an example showing you how a memcached server runit entry can be made.

    ### In memcached.sh (make sure this file is chmod +x):
    #!/bin/sh
    # `/sbin/setuser memcache` runs the given command as the user `memcache`.
    # If you omit that part, the command will be run as root.
    exec /sbin/setuser memcache /usr/bin/memcached >>/var/log/memcached.log 2>&1

    ### In Dockerfile:
    RUN mkdir /etc/service/memcached
    ADD memcached.sh /etc/service/memcached/run

Note that the shell script must run the daemon **without letting it daemonize/fork it**. Usually, daemons provide a command line flag or a config file option for that.

<a name="running_startup_scripts"></a>
### Running scripts during container startup

The docker-baseimage init system, `/sbin/my_init`, runs the following scripts during startup, in the following order:

 * All executable scripts in `/etc/my_init.d`, if this directory exists. The scripts are run in lexicographic order.
 * The script `/etc/rc.local`, if this file exists.

All scripts must exit correctly, e.g. with exit code 0. If any script exits with a non-zero exit code, the booting will fail.

The following example shows how you can add a startup script. This script simply logs the time of boot to the file /tmp/boottime.txt.

    ### In logtime.sh (make sure this file is chmod +x):
    #!/bin/sh
    date > /tmp/boottime.txt

    ### In Dockerfile:
    RUN mkdir -p /etc/my_init.d
    ADD logtime.sh /etc/my_init.d/logtime.sh

<a name="environment_variables"></a>
### Environment variables

If you use `/sbin/my_init` as the main container command, then any environment variables set with `docker run --env` or with the `ENV` command in the Dockerfile, will be picked up by `my_init`. These variables will also be passed to all child processes, including `/etc/my_init.d` startup scripts, Runit and Runit-managed services. There are however a few caveats you should be aware of:

 * Environment variables on Unix are inherited on a per-process basis. This means that it is generally not possible for a child process to change the environment variables of other processes.
 * Because of the aforementioned point, there is no good central place for defining environment variables for all applications and services. Debian has the `/etc/environment` file but it only works in some situations.
 * Some services change environment variables for child processes. Nginx is one such example: it removes all environment variables unless you explicitly instruct it to retain them through the `env` configuration option. If you host any applications on Nginx 

`my_init` provides a solution for all these caveats.

<a name="envvar_central_definition"></a>
#### Centrally defining your own environment variables

During startup, before running any [startup scripts](#running_startup_scripts), `my_init` imports environment variables from the directory `/etc/container_environment`. This directory contains files who are named after the environment variable names. The file contents contain the environment variable values. This directory is therefore a good place to centrally define your own environment variables, which will be inherited by all startup scripts and Runit services.

For example, here's how you can define an environment variable from your Dockerfile:

    RUN echo Apachai Hopachai > /etc/container_environment/MY_NAME

You can verify that it works, as follows:

    $ docker run -t -i <YOUR_NAME_IMAGE> /sbin/my_init -- bash -l
    ...
    *** Running bash -l...
    # echo $MY_NAME
    Apachai Hopachai
    
If you've looked carefully, you'll notice that the 'echo' command actually prints a newline. Why does $MY_NAME not contain a newline then? It's because `my_init` strips the trailing newline, if any. If you intended on the value having a newline, you should add *another* newline, like this:

    RUN echo -e "Apachai Hopachai\n" > /etc/container_environment/MY_NAME
    
  <a name="envvar_dumps"></a>
#### Environment variable dumps

While the previously mentioned mechanism is good for centrally defining environment variables, it by itself does not prevent services (e.g. Nginx) from changing and resetting environment variables from child processes. However, the `my_init` mechanism does make it easy for you to query what the original environment variables are.

During startup, right after importing environment variables from `/etc/container_environment`, `my_init` will dump all its environment variables (that is, all variables imported from `container_environment`, as well as all variables it picked up from `docker run --env`) to the following locations, in the following formats:

 * `/etc/container_environment`
 * `/etc/container_environment.sh` - a dump of the environment variables in Bash format. You can source the file directly from a Bash shell script.
 * `/etc/container_environment.json` - a dump of the environment variables in JSON format.

The multiple formats makes it easy for you to query the original environment variables no matter which language your scripts/apps are written in.

Here is an example shell session showing you how the dumps look like:

    $ docker run -t -i \
      --env FOO=bar --env HELLO='my beautiful world' \
      angelrr7702/docker-baseimage /sbin/my_init -- \
      bash -l
    ...
    *** Running bash -l...
    # ls /etc/container_environment
    FOO  HELLO  HOME  HOSTNAME  PATH  TERM  container
    # cat /etc/container_environment/HELLO; echo
    my beautiful world
    # cat /etc/container_environment.json; echo
    {"TERM": "xterm", "container": "lxc", "HOSTNAME": "f45449f06950", "HOME": "/root", "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", "FOO": "bar", "HELLO": "my beautiful world"}
    # source /etc/container_environment.sh
    # echo $HELLO
    my beautiful world

<a name="modifying_envvars"></a>
#### Modifying environment variables

It is even possible to modify the environment variables in `my_init` (and therefore the environment variables in all child processes that are spawned after that point in time), by altering the files in `/etc/container_environment`. After each time `my_init` runs a [startup script](#running_startup_scripts), it resets its own environment variables to the state in `/etc/container_environment`, and re-dumps the new environment variables to `container_environment.sh` and `container_environment.json`.

But note that:

 * modifying `container_environment.sh` and `container_environment.json` has no effect.
 * Runit services cannot modify the environment like that. `my_init` only activates changes in `/etc/container_environment` when running startup scripts.

<a name="envvar_security"></a>
#### Security

Because environment variables can potentially contain sensitive information, `/etc/container_environment` and its Bash and JSON dumps are by default owned by root, and accessible only by the `docker_env` group (so that any user added this group will have these variables automatically loaded).

If you are sure that your environment variables don't contain sensitive data, then you can also relax the permissions on that directory and those files by making them world-readable:

    RUN chmod 755 /etc/container_environment
    RUN chmod 644 /etc/container_environment.sh /etc/container_environment.json

<a name="workaroud_modifying_etc_hosts"></a>
### Working around Docker's inability to modify /etc/hosts

It is currently not possible to modify /etc/hosts inside a Docker container because of [Docker bug 2267](https://github.com/dotcloud/docker/issues/2267). Baseimage-docker includes a workaround for this. You have to be explicitly opt-in for the workaround.

The workaround involves modifying a system library, libnss_files.so.2, so that it looks for the host file in /etc/workaround-docker-2267/hosts instead of /etc/hosts. Instead of modifying /etc/hosts, you modify /etc/workaround-docker-2267/hosts instead.

Add this to your Dockerfile to opt-in for the workaround. This command modifies libnss_files.so.2 as described above.

    RUN /usr/bin/workaround-docker-2267

(You don't necessarily have to run this command from the Dockerfile. You can also run it from a shell inside the container.)

To verify that it works, [open a bash shell in your container](#inspecting), modify /etc/workaround-docker-2267/hosts, and check whether it had any effect:

    bash# echo 127.0.0.1 my-test-domain.com >> /etc/workaround-docker-2267/hosts
    bash# ping my-test-domain.com
    ...should ping 127.0.0.1...

**Note on apt-get upgrading:** if any Ubuntu updates overwrite libnss_files.so.2, then the workaround is removed. You have to re-enable it by running `/usr/bin/workaround-docker-2267`. To be safe, you should run this command every time after running `apt-get upgrade`.  

<a name="container_administration"></a>
## Container administration

One of the ideas behind Docker is that containers should be stateless, easily restartable, and behave like a black box. However, you may occasionally encounter situations where you want to login to a container, or to run a command inside a container, for development, inspection and debugging purposes. This section describes how you can administer the container for those purposes.

<a name="oneshot"></a>
### Running a one-shot command in a new container

_**Note:** This section describes how to run a command insider a -new- container. To run a command inside an existing running container, see [Running a command in an existing, running container](#run_inside_existing_container)._

Normally, when you want to create a new container in order to run a single command inside it, and immediately exit after the command exits, you invoke Docker like this:

    docker run YOUR_IMAGE COMMAND ARGUMENTS...

However the downside of this approach is that the init system is not started. That is, while invoking `COMMAND`, important daemons such as cron and syslog are not running. Also, orphaned child processes are not properly reaped, because `COMMAND` is PID 1.

Baseimage-docker provides a facility to run a single one-shot command, while solving all of the aforementioned problems. Run a single command in the following manner:

    docker run YOUR_IMAGE /sbin/my_init -- COMMAND ARGUMENTS ...

This will perform the following:

 * Runs all system startup files, such as /etc/my_init.d/* and /etc/rc.local.
 * Starts all runit services.
 * Runs the specified command.
 * When the specified command exits, stops all runit services.

For example:

    $ docker run phusion/baseimage:<VERSION> /sbin/my_init -- ls
    *** Running /etc/rc.local...
    *** Booting runit daemon...
    *** Runit started as PID 80
    *** Running ls...
    bin  boot  dev  etc  home  image  lib  lib64  media  mnt  opt  proc  root  run  sbin  selinux  srv  sys  tmp  usr  var
    *** ls exited with exit code 0.
    *** Shutting down runit daemon (PID 80)...
    *** Killing all processes...

You may find that the default invocation is too noisy. Or perhaps you don't want to run the startup files. You can customize all this by passing arguments to `my_init`. Invoke `docker run YOUR_IMAGE /sbin/my_init --help` for more information.

The following example runs `ls` without running the startup files and with less messages, while running all runit services:

    $ docker run angelrr7702/docker-baseimage /sbin/my_init --skip-startup-files --quiet -- ls
    bin  boot  dev  etc  home  image  lib  lib64  media  mnt  opt  proc  root  run  sbin  selinux  srv  sys  tmp  usr  var

<a name="run_inside_existing_container"></a>
### Running a command in an existing, running container
<a name="login_nsenter"></a>
### Login to the container, or running a command inside it, via nsenter

You can use the `nsenter` tool on the Docker host OS to login to any container that is based on baseimage-docker. You can also use it to run a command inside a running container. `nsenter` works by using Linux kernel system calls.

Here's how it compares to [using SSH to login to the container or to run a command inside it](#login_ssh):

 * Pros
   * Does not require running an SSH daemon inside the container.
   * Does not require setting up SSH keys.
   * Works on any container, even containers not based on baseimage-docker.
 * Cons
   * Processes executed by `nsenter` behave in a slightly different manner than normal. For example, they cannot be killed by any normal processes inside the container. This applies to all child processes as well.
   * If the `nsenter` process is terminated by a signal (e.g. with the `kill` command), then the command that is executed by nsenter is *not* killed and cleaned up. You will have to do that manually. (Note that terminal control commands like Ctrl-C *do* clean up all child processes, because terminal signals are sent to all processes in the terminal session.)
   * Requires learning another tool.
   * Requires root privileges on the Docker host.
   * Requires the `nsenter` tool to be available on the Docker host. At the time of writing (July 2014), most Linux distributions do not ship it. However, baseimage-docker provides a precompiled binary, and allows you to easily use it, through its [docker-bash](#docker_bash) tool.
   * Not possible to allow users to login to the container without also letting them login to the Docker host.

<a name="nsenter_usage"></a>
#### Usage

First, ensure that `nsenter` is installed. At the time of writing (July 2014), almost no Linux distribution ships the `nsenter` tool. However, we provide [a precompiled binary](#docker_bash) that anybody can use.

Now that you have the container's main process PID, you can use `nsenter` to login to the container, or to execute a command inside it:

    # Login to the container
    nsenter --target <MAIN PROCESS PID> --mount --uts --ipc --net --pid bash -l

    # Running a command inside the container
    nsenter --target <MAIN PROCESS PID> --mount --uts --ipc --net --pid -- echo hello world
    
<a name="docker_bash"></a>
#### The `docker-bash` tool

Looking up the main process PID of a container and typing the long nsenter command quickly becomes tedious. Luckily, we provide the `docker-bash` tool which automates this process. This tool is to be run on the *Docker host*, not inside a Docker container.

This tool also comes with a precompiled `nsenter` binary, so that you don't have to install `nsenter` yourself. `docker-bash` works out-of-the-box!

First, install the tool on the Docker host:

    curl --fail -L -O https://github.com/phusion/baseimage-docker/archive/master.tar.gz && \
    tar xzf master.tar.gz && \
    sudo ./baseimage-docker-master/install-tools.sh

Then run the tool as follows to login to a container:

    docker-bash YOUR-CONTAINER-ID

You can lookup `YOUR-CONTAINER-ID` by running `docker ps`.

By default, `docker-bash` will open a Bash session. You can also tell it to run a command, and then exit:

    docker-bash YOUR-CONTAINER-ID echo hello world
    
