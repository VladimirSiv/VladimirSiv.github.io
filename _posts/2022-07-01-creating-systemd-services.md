---
title: "Understanding systemd and creating Linux services"
page_title: "Understanding systemd and creating Linux services"
excerpt: "Learning about the basics of systemd, dependencies, unit files, 
service configuration, and how to set up custom applications as systemd services"
date: July 1, 2022
toc: true
toc_label: "Content"
toc_sticky: true
last_modified_at: July 1, 2022
og_image: /assets/images/posts/systemd-service/header.jpg
---

{% include image.html
    src="/assets/images/posts/systemd-service/header.jpg"
    alt="similarity-header"
    caption="Image Source: <a href='https://www.pexels.com/' target='_blank'>Pexels</a>"
%}

## Introduction

I've worked on a project where we had multiple crawlers that gathered data which 
was stored for further processing and downstream ML training. To make things 
easier we wrote a small service that took care of managing and scheduling 
crawlers. The service was configured and managed using systemd, which gave us 
better monitoring, status reports, logging, unexpected error handling etc. 
Additionally, we used multiple oneshot services that handled different 
kinds of configuration setups and cleanup.

In this post we will cover basics of systemd, benefits of using it, and some 
examples that will prepare you to start off on the right foot. 

## systemd

### Basics

systemd serves as a system and service manager for Linux operating systems. It 
runs as an init system (PID 1) that starts the rest of the system, boostraps 
user space and manages processes. It's capable of starting services in parallel, 
which improves the boot time. Besides keeping track of processes, systemd 
provides replacements for various daemons, offers on-demand starting daemons, 
maintains mount points, includes logging daemon, controls basic system 
configuration like: system accounts, runtime directories, running containers and 
virtual machines, and many many more.

When Linux kernel handles control to systemd, during the boot process, it's 
the only process that's running. There are no background processes that 
manage network configuration, display managers, etc - rendering the system 
unusable. At this point, systemd checks the desired run-state of the system and 
starts running services. A run-state is called a **target**.

If you run `man bootup` you'll see a really neat chart:
<a name="bootup-chart"></a>


```
                                        cryptsetup-pre.target veritysetup-pre.target
                                                             |
           (various low-level                                v
            API VFS mounts:             (various cryptsetup/veritysetup devices...)
            mqueue, configfs,                                |    |
            debugfs, ...)                                    v    |
            |                                  cryptsetup.target  |
            |  (various swap                                 |    |    remote-fs-pre.target
            |   devices...)                                  |    |     |        |
            |    |                                           |    |     |        v
            |    v                       local-fs-pre.target |    |     |  (network file systems)
            |  swap.target                       |           |    v     v                 |
            |    |                               v           |  remote-cryptsetup.target  |
            |    |  (various low-level  (various mounts and  |  remote-veritysetup.target |
            |    |   services: udevd,    fsck services...)   |             |    remote-fs.target
            |    |   tmpfiles, random            |           |             |             /
            |    |   seed, sysctl, ...)          v           |             |            /
            |    |      |                 local-fs.target    |             |           /
            |    |      |                        |           |             |          /
            \____|______|_______________   ______|___________/             |         /
                                        \ /                                |        /
                                         v                                 |       /
                                  sysinit.target                           |      /
                                         |                                 |     /
                  ______________________/|\_____________________           |    /
                 /              |        |      |               \          |   /
                 |              |        |      |               |          |  /
                 v              v        |      v               |          | /
            (various       (various      |  (various            |          |/
             timers...)      paths...)   |   sockets...)        |          |
                 |              |        |      |               |          |
                 v              v        |      v               |          |
           timers.target  paths.target   |  sockets.target      |          |
                 |              |        |      |               v          |
                 v              \_______ | _____/         rescue.service   |
                                        \|/                     |          |
                                         v                      v          |
                                     basic.target         rescue.target    |
                                         |                                 |
                                 ________v____________________             |
                                /              |              \            |
                                |              |              |            |
                                v              v              v            |
                            display-    (various system   (various system  |
                        manager.service     services        services)      |
                                |         required for        |            |
                                |        graphical UIs)       v            v
                                |              |            multi-user.target
           emergency.service    |              |              |
                   |            \_____________ | _____________/
                   v                          \|/
           emergency.target                    v
                                         graphical.target
```

This chart is a structural overview of well-known targets and their position 
in the boot-up logic.

Unless otherwise specified, systemd always starts the **default.target**, which 
is a symlink to the true target file. For desktops that's typically the
**graphical.target** i.e. **multi-user.target** with a GUI.

Targets are a set of services that are required to run a system at a specific 
level of functionality such as multi-user, GUI etc. What makes reaching targets 
difficult is that services depend on each other creating a dependency tree. 
Using `systemd-analyze` we can get more information about the systemd's 
execution tree, for example `systemd-analyze critical-chain` outputs blocking 
tree of daemons:

```
> system-analyze critical-chain
The time when unit became active or started is printed after the "@" character.
The time the unit took to start is printed after the "+" character.

graphical.target @9.024s
└─multi-user.target @9.024s
  └─docker.service @8.004s +1.020s
    └─network-online.target @7.974s
      └─NetworkManager-wait-online.service @2.474s +5.499s
        └─NetworkManager.service @2.440s +32ms
          └─dbus.service @2.398s +39ms
            └─basic.target @2.392s
              └─sockets.target @2.392s
                └─docker.socket @2.388s +4ms
                  └─sysinit.target @2.385s
                    └─systemd-backlight@backlight:intel_backlight.service @2.633s +4ms
                      └─system-systemd\x2dbacklight.slice @2.632s
                        └─system.slice @274ms
                          └─-.slice @274ms
```

In my case the NetworkManager and docker are definitely holding entire bootup 
:'D

> Other useful commands:
> - `systemd-analyze plot` - This command prints an SVG graphic detailing which 
> system services have been started at what time, highlighting the time they 
> spent on initialization
> - `systemd-analyze dot` - generates textual dependency graph description in 
> dot format for further processing with the GraphViz dot(1) tool

### Dependencies and Ordering

For systemd dependency doesn't mean ordering, those two things are different. 
We could set a dependency between services but systemd will run them at the same 
time in parallel.

There are two directives to set dependencies:
- **Wants**: If `service_1` wants `service_2`, both services will start. 
However, if `service_2` fails to start it will not have affect on the 
`service_1` running successfully
- **Requires**: If `service_1` requires `service_2`, both services will start. 
But now, if `service_2` fails to start the `service_1` will be deactivated

You can look at *Wants* as a weaker *Requires*. Man page of `systemd.unit` 
recommends *Wants* as a way to hook start-up of one service to the start-up of 
another service.

The dependency ordering can be set using:
- **Before**: If `service_1` has before `service_2` then the start-up of 
`service_2` is delayed until `service_1` has finished starting up
- **After**: If `service_1` has after `service_2` then the start-up of 
`service_1` is delayed until `service_2` has finished starting up

If two services have ordering dependency between them, during shut down the 
inverse of start-up ordering is applied. Of course, if no ordering dependency 
is defined between them, they are shut down or started simultaneously.

> To learn more about dependency and ordering please read 
[`man systemd.unit`](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#){:target="_blank"}

### Unit

Until now we only talked about services but systemd can manage a lot more. An 
object that systemd manages is called a **unit**, it can be of many types and 
the most common type is a service. A unit is defined using unit files. If a 
unit is of type service it will have a unit file that ends with `.service`. 

Other types are: 

- `.socket`: an IPC or network socket or a file system FIFO controlled and 
supervised by systemd, for socket-based activation. 
Ref: [systemd.socket](https://www.freedesktop.org/software/systemd/man/systemd.socket.html#){:target="_blank"}
- `.device`: a device unit as exposed in the sysfs/udev device tree. This may 
be used to define dependencies between devices and other units. 
Ref: [systemd.device](https://www.freedesktop.org/software/systemd/man/systemd.device.html#){:target="_blank"}
- `.mount`: a file system mount point controlled and supervised by systemd. 
Ref: [systemd.mount](https://www.freedesktop.org/software/systemd/man/systemd.mount.html#){:target="_blank"}
- `.automount`: configures a mount point that will be automatically mounted. 
For each automount unit file a matching mount unit file must exist. 
Ref: [systemd.automount](https://www.freedesktop.org/software/systemd/man/systemd.automount.html#){:target="_blank"}
- `.swap`: a swap device or file for memory paging controlled and supervised 
by systemd. Swap units must be named after the devices or files they control. 
Ref: [systemd.swap](https://www.freedesktop.org/software/systemd/man/systemd.swap.html#){:target="_blank"}
- `.target`: target unit of systemd, which is used for grouping units during 
start-up. Target units do not offer any additional functionality on top of 
the generic functionality provided by units. They exist merely to group units 
via dependencies, and to establish standardized names for synchronization 
points used in dependencies between units. 
Ref: [systemd.target](https://www.freedesktop.org/software/systemd/man/systemd.target.html#){:target="_blank"}
- `.path`: a path monitored by systemd, for path-based activation. For each 
path file, a matching unit file must exist, describing the unit to activate 
when the path changes. 
Ref: [systemd.path](https://www.freedesktop.org/software/systemd/man/systemd.path.html#){:target="_blank"}
- `.timer`: a timer controlled and supervised by systemd, for timer-based 
activation. Similar to a cron job, a matching unit will be started when the 
timer is reached. 
Ref: [systemd.timer](https://www.freedesktop.org/software/systemd/man/systemd.timer.html#){:target="_blank"}
- `.slice`: a slice unit. A slice unit is a concept for hierarchically 
managing resources of a group of processes. This management is performed by 
creating a node in the Linux Control Group (cgroup) tree. 
Ref: [systemd.slice](https://www.freedesktop.org/software/systemd/man/systemd.slice.html#){:target="_blank"}
- `.scope`: a scope unit. Scopes units manage a set of system processes. Unlike 
service units, scope units manage externally created processes, and do not 
fork off processes on its own. 
Ref: [systemd.scope](https://www.freedesktop.org/software/systemd/man/systemd.scope.html#){:target="_blank"}

Many of these units are interconnected and work together to build a specific 
functionality. If you are interested in understanding more about these types, 
please go through referenced man pages.

### Unit file syntax

If you've worked with python's 
[ConfigParser](https://docs.python.org/3/library/configparser.html){:target="_blank"} 
you are familiar with configuration files that use `[Sections]` similar to 
`.toml` or `.ini`. systemd's unit files also have sections, general directives, 
and section specific directives.

#### Unit

The first section is `[Unit]`, which is used for defining metadata of a unit 
and configuring dependencies to other units. Some directives define generic 
information about the unit that is not dependent on the type of a 
unit:
- `Description=` - a short human readable title of the unit
- `Documentation=` - a space-separated list of URIs referencing documentation 
for this unit or its configuration
- `Wants=` - this is how we define *Wants* between units - mentioned above
- `Requires=` - this is how we define *Requires* between units - mentioned above
- `Before=, After=` - this is how we define *Before/After* between units - mentioned above
- `StopWhenUnneeded=` - if true, unit will be stopped when it's no longer needed
- `OnFailure=` - defines one or more units that will be activated when the unit 
enters the `failed` state
- `OnSuccess=`- defines one or more units that will be activated when the unit 
enters the `inactive` state

> See 
[`man systemd.unit`](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#){:target="_blank"} 
to get the full list of generic directives

#### Service

Some directives are unit-specific, for example `[Service]` takes:
- `Type=` - configures the process start-up type for this service unit. Takes 
one of: `simple`, `exec`, `forking`, `oneshot`, `dbus`, `notify`, or `idle`.
- `RemainAfterExit=` - specifies whether the service shall be considered 
active even when all its processes exited
- `Restart=` - defines when a service should be restarted. Takes one of: 
`on-success`, `on-failure`, `on-abnormal`, `on-watchdog`, `on-abort`, or 
`always`.
- `RestartSec=` - the time to sleep before restarting a service 
- `TimeoutStartSec=` - the time to wait for start-up

> See 
[`man systemd.service`](https://www.freedesktop.org/software/systemd/man/systemd.service.html#){:target="_blank"} 
to get the full list of service directives

#### Install

The second section is `[Install]`, which carries installation information for 
the unit. This section is used by `enable` and `disable` commands of 
`systemctl` (described in the section below) during installation of a unit. 
Some of the generic directives for this sections are:
- `Alias=` - a space-separated list of additional names this unit shall be 
installed under
- `Also=` - additional units to install/deinstall when this unit is 
installed/deinstalled 

Now let's take a look at a unit file, for example: `docker.service` located 
at `/usr/lib/systemd/service`:

```ini
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
```

### systemctl

To interact with and send commands to systemd we use `systemctl` command that 
allows us to view, start, stop, restart, enable, or disable system services. 

The following are some basic `systemctl` commands:

| Command                                     | Action                                                                         |
|---------------------------------------------|--------------------------------------------------------------------------------|
| `systemctl start name.service`              | Executes instructions in the service's unit file and starts a systemd service  |
| `systemctl stop name.service`               | Stops a currently running service                                              |
| `systemctl restart name.service`            | Restarts a running service                                                     |
| `systemctl reload name.service`             | Reloads application's configuration files without restarting it                |
| `systemctl status name.service`             | Checks the status of a service                                                 |
| `systemctl enable name.service`             | Configures a service to be automatically started at boot by creating a symlink |
| `systemctl disable name.service`            | Disables auto start at boot                                                    |
| `systemctl list-units --type service --all` | Outputs a list of all services                                                 |
| `systemctl list-dependencies name.service`  | Outputs a list of dependencies for specified service                           |
| `systemctl mask name.service`               | Completely disables a service - cannot be started automatically or manually    |

The `systemctl status name.service` command prints some basic information about 
the service and most recent logs:

```text
> systemctl status docker.service
● docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
     Active: active (running) since Sun 2022-06-26 16:19:36 CEST; 1h 29min ago
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 950 (dockerd)
      Tasks: 64 (limit: 14057)
     Memory: 448.9M
        CPU: 37.684s
     CGroup: /system.slice/docker.service
             ├─  950 /usr/bin/dockerd -H fd://
             ├─  961 containerd --config /var/run/docker/containerd/containerd.toml --log-level info
             ├─ 5276 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 4000 -container-ip 172.17.0.3 -contai...
             ├─ 5283 /usr/bin/docker-proxy -proto tcp -host-ip :: -host-port 4000 -container-ip 172.17.0.3 -container-p...

Jun 26 17:14:20 vladimir dockerd[961]: time="2022-06-26T17:14:20.421914499+02:00" level=warnin...
Jun 26 17:14:23 vladimir dockerd[961]: time="2022-06-26T17:14:23.791570816+02:00" level=info m...
...
```

We can see that the `docker.service` was triggered by `docker.socket` which is 
consistent with the unit file that we saw above. 

> Also I'm running this site as a docker container for local testing, that's
why there are PIDs 5276 and 5283

It's quite interesting to see a list of dependencies of a service and how  
everything is connected. From **swap.target**, **local-fs.target** to the 
whole **sysinit.target** and **network-online.target** to **docker.socket**, 
and finally **docker.service**. Run 
`systemctl list-dependencies docker.service` and compare the output to 
the [chart](#bootup-chart) above.

### journalctl

systemd has its own logging system called the **journal**. It's started and 
managed using the service **systemd-journald.service**. To query the journal 
i.e. logs of systemd and services, we use **journalctl** command.

The following are some basic journalctl commands:

| Command                            | Action                                                                       |
|------------------------------------|------------------------------------------------------------------------------|
| `journalctl -n 15`                 | get first 15 log records                                                     |
| `journalctl --since "yesterday"`   | get log records of yesterday                                                 |
| `journalctl --since "2 hours ago"` | get log records of the last 2 hours                                          |
| `journalctl -b`                    | get log records from the current boot                                        |
| `journalctl -b -n`                 | (where $n∈N$) get log records from the n-th boot relative to the current one |
| `journalctl --list-boots`          | list boots                                                                   |
| `journalctl -u name.service`       | get logs from a specific service                                             |
| `journalctl -f`                    | get tail log records                                                         |

Alright, now we know more than enough to start playing around with systemd 
services and create our own units!

## Creating a service

### Simple script

Let's start with a simple script. It will run when we start the service 
and then exit. Create a file `simple_script.py` that has the following content:

```python
print("I'm just a poor script, I need no sympathy!")
```

Then create a `simple_script.service` in `/usr/lib/systemd/system/`:

```text
[Unit]
Description=A simple script
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/env python <path>/simple_script.py

[Install]
WantedBy=multi-user.target
```

> If you're wondering why `/usr/bin/env python`, please see: 
> [What is the difference between "#!/usr/bin/env bash" and "#!/usr/bin/bash"?](https://stackoverflow.com/questions/16365130/what-is-the-difference-between-usr-bin-env-bash-and-usr-bin-bash){:target="_blank"}

Now we can run it using `systemctl start simple_script.service` and check 
the status:

```text
○ simple_script.service - A simple script
     Loaded: loaded (/usr/lib/systemd/system/simple_script.service; disabled; vendor preset: disabled)
     Active: inactive (dead)

Jun 29 20:45:15 vladimir systemd[1]: Started A simple script.
Jun 29 20:45:15 vladimir env[11994]: I'm just a poor script, I need no sympathy!
Jun 29 20:45:15 vladimir systemd[1]: simple_script.service: Deactivated successfully.
```

Service is in `inactive (dead)` status, but looking at logs we see that it has 
been executed and successfully deactivated.

### Script timer

The idea here is to create a `.timer` service that will trigger `.service` 
every X seconds.

> Of course, the same can be done using the cron. However, there are differences: 
[Cron vs systemd timers](https://unix.stackexchange.com/questions/278564/cron-vs-systemd-timers){:target="_blank"} 
and [ArchWiki - systemd/Timers](https://wiki.archlinux.org/title/Systemd/Timers#As_a_cron_replacement){:target="_blank"}

Let's create a `timer_script.py`:

```python
print("Too late, my time has come.")
```

timer unit `timer_script.timer`:

```text
[Unit]
Description=Timer trigger

[Timer]
OnUnitActiveSec=10s
OnBootSec=10s

[Install]
WantedBy=timers.target
```

and finally a service `timer_script.service`:

```text
[Unit]
Description=A simple script
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/env python <path>/timer_script.py

[Install]
WantedBy=multi-user.target
```

You may be asking yourself "How does it know to trigger the right service?" 
Well, the name of the timer has to be the same as the name of the service.

Now, we need to start the timer service and it will trigger the service every 
10s: `systemctl start timer_script.timer`. Check the logs using
`journalctl -u timer_script.service` to confirm the execution.

### Execute script before/after activating/deactivating a service

The combination of `ExecStartPre=`, `ExecStartPost=`, and `ExecStopPost=` can 
be used to achieve this.

Let's create `pre_post_script.service` with the following content:

```text
[Unit]
Description=pre/post script
After=multi-user.target

[Service]
Type=simple
ExecStartPre=/usr/bin/env python -c "print('Easy come, easy go, will you let me go')"
ExecStart=/usr/bin/env python -c "print('No, we will not let you go')"
ExecStartPost=/usr/bin/env python -c "print('Never let you go')"
ExecStopPost=/usr/bin/env python -c "print('Mama mia, let me go')"

[Install]
WantedBy=multi-user.target
```

If you start the service and then check logs, you'll see:

```
Jun 29 22:03:41 vladimir systemd[1]: Starting pre/post script...
Jun 29 22:03:41 vladimir env[17421]: Easy come, easy go, will you let me go
Jun 29 22:03:41 vladimir env[17422]: No, we will not let you go
Jun 29 22:03:41 vladimir env[17423]: Never let you go
Jun 29 22:03:41 vladimir env[17424]: Mama mia, let me go
Jun 29 22:03:41 vladimir systemd[1]: pre_post_script.service: Deactivated successfully.
```

### Oneshot service

The biggest difference between a oneshot and a simple service is how they manage 
activation of the follow-up services. Basically, simple services start 
immediately without waiting for a service to finish the process. On the other 
hand, oneshot service will wait until the completion before it starts other 
services.

> If you are looking for a deep dive on this subject, please see this 
awesome post: 
[Simple vs Oneshot - Choosing a systemd Service Type](https://trstringer.com/simple-vs-oneshot-systemd-service/){:target="_blank"} 

A real life example would be to have a oneshot service that is started in 
order to fetch and set some parameters before activating a new service that 
will use those parameters.

The most important directive here is `RemainAfterExit` which tells systemd 
to keep the oneshot service active even after the service exits. This is 
useful for multiple things, for example: running a cleanup service before 
shutting down.

Let's create a simple example of setup/teardown oneshot service:

```text
[Unit]
Description=Simple oneshot service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/env python -c "print('Galileo setup')"
RemainAfterExit=true
ExecStop=/usr/bin/env python -c "print('Figaro teardown')"

[Install]
WantedBy=multi-user.target
```

Starting this service and checking its status gives us:

```
● simple_oneshot.service - Simple oneshot service
     Loaded: loaded (/usr/lib/systemd/system/simple_oneshot.service; disabled; vendor preset: disabled)
     Active: active (exited) since Thu 2022-06-30 23:57:14 CEST; 5s ago
    Process: 4675 ExecStart=/usr/bin/env python -c print('Galileo setup') (code=exited, status=0/SUCCESS)
   Main PID: 4675 (code=exited, status=0/SUCCESS)
        CPU: 29ms

Jun 30 23:57:14 vladimir systemd[1]: Starting Simple oneshot service...
Jun 30 23:57:14 vladimir env[4675]: Galileo setup
Jun 30 23:57:14 vladimir systemd[1]: Finished Simple oneshot service.
```

We can see that the service has been started and setup was completed, 
but it's status still remains `active`. If we stop it, the following 
will happen:

```
Jun 30 23:59:07 vladimir env[4837]: Figaro teardown
Jun 30 23:59:07 vladimir systemd[1]: simple_oneshot.service: Deactivated successfully.
Jun 30 23:59:07 vladimir systemd[1]: Stopped Simple oneshot service.
```

### Web application service

Another common example is managing a web application using systemd. Let's 
say that we have a 
[Flask](https://flask.palletsprojects.com/en/2.1.x/){:target="_blank"} or 
[Django](https://www.djangoproject.com/){:target="_blank"} 
application and we are running it using 
[gunicorn](https://gunicorn.org/){:target="_blank"} or 
[uWSGI](https://uwsgi-docs.readthedocs.io/en/latest/){:target="_blank"} and 
[Nginx](https://www.nginx.com/){:target="_blank"} as a reverse proxy.

We could create a simple service that starts gunicorn:

```text
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=user
Group=www-data
WorkingDirectory=<working-dir-path>
ExecStart=<gunicorn-path> \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn.sock \
          myproject.wsgi:application

[Install]
WantedBy=multi-user.target
```

> If you are interested in the details, please see 
[How To Set Up Django with Postgres, Nginx, and Gunicorn on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-ubuntu-16-04){:target="_blank"}

However, there is a more involved setup that uses systemd `.socket` service to 
create a unix socket for incoming gunicorn requests. In this setup, systemd will 
listen on the socket and automatically start gunicorn when traffic arrives. 

To achieve this we need to create a `web_app.socket` and `web_app.service` of 
type `notify`. That way systemd will automatically set up a communication 
socket and it will listen for messages in that socket. The final step is to 
configure Nginx to proxy the traffic to the `web_app.socket`.

> To learn more please see 
[Deploying Gunicorn - Systemd](https://docs.gunicorn.org/en/stable/deploy.html#systemd){:target="_blank"}

## Final words

If you are just starting out with configuring your services using systemd it 
can be difficult to wrap your head around what's going on. Understanding how 
systemd defines units, differences between them, multiple options, and how to 
combine multiple units into a specific functionality can take some time and a 
lot of *man-paging*[^1].

[^1]: I'm pretty sure this word does not exist. Nevertheless, it's a perfect opportunity for a wordplay with *man pages* and memory management - *paging* :D

I hope this post gave a better understanding of how systemd works and a 
starting point for defining new services.

If you have any questions or suggestions, please reach out, I'm always 
available.

## Resources

- [Understanding Systemd Units and Unit Files](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files){:target="_blank"}
- [systemd man pages](https://www.freedesktop.org/software/systemd/man/index.html){:target="_blank"}
- [Red Hat - System Administrators Guide - Managing Services with systemd](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/chap-managing_services_with_systemd#doc-wrapper){:target="_blank"}
