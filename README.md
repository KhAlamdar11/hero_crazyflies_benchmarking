# Sim2Real Benchmarking Connectivity and Battery-aware algorithms with Crazyflies 

This work accompanies sim2real framework for benchmarking connectivity and battery aware algorithms with Crazyflie UAVs. It is supporting both simulation using CrazySim + Gazebo and real hardware experiments.




## Prerequisites
To start this framework, there are several requirements: 
- Docker
- NVIDIA Docker (optional, for GPU acceleration)
- Linux (tested on Ubuntu 24.04)

To be able to start graphical applications in container please run locally: 
```
echo "xhost +local:docker > /dev/null" >> ~/.profile
```

## Simulation Environment

To build simulation environment position yourself into the repo and use building script with `sim` argument:

```
./build.sh sim
```

This will build `crazy_sim`. To run the container `crazy_sim_container` use first run scriptwith `sim` argument: 

```
./first_run.sh sim
```

If you want to start the container that was already once ran, you can do that with:
```
docker start -i crazy_sim_container

```


## Real Environment

### Requirements for the real setup
Before being able to run everything on the real setup, there are several prerequisites:
#### Motion Capture tracking - prerequisites: 
To obtain data from motion capture system, please install locally [NatNetSDK](https://github.com/whoenig/NatNetSDKCrossplatform) as given in README instructions.

#### USB permissions - prerequisites: 
Copy file: `to_copy/99-bitcraze.rules` to  `/etc/udev/rules.d` directory. Please check these links on USB permissions: [crazyradio](https://www.bitcraze.io/documentation/repository/crazyflie-lib-python/master/installation/usb_permissions/). This enables to use the USB Radio and Crazyflie 2 over USB without being root.


### Staring the docker
To build environment for the real setup position yourself into the repo and use building script sith `real` argument:

```
./build.sh real
```

This will build `crazy_real`. To run the container `crazy_real_container` use first run scriptwith `real` argument: 

```
./first_run.sh real
```

If you want to start the container that was already once ran, you can do that with:
```
docker start -i crazy_real_container

```