# Sim2Real Benchmarking Connectivity and Battery-aware algorithms with Crazyflies 

This work accompanies sim2real framework for benchmarking connectivity and battery aware algorithms with Crazyflie UAVs. It is supporting both simulation using CrazySim + Gazebo and real hardware experiments.
<p align="center">
  <img width="339" alt="ICUAS_ARCH_vert" src="https://github.com/user-attachments/assets/f16c46ab-3097-4005-af72-0e34d4a4549b" />
</p>


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

### Scaling beyond ~5 simulated Crazyflies (low‑RTF mitigations)

Upstream CrazySim hits a wall around 5 drones: Gazebo's real‑time factor (RTF) drops, the cf2 SITL firmware (whose scheduler is paced by sim‑time IMU samples) becomes slow to answer CRTP queries, and the parallel cflib connection storm during `open_links()` causes crazyflies to never finish their TOC/parameter handshake. This fork applies five layers of mitigation. None of them coarsen the physics step (which the upstream author's `max_step_size=0.002` / IMU `500 Hz` workaround does and which destabilises hover).

| Layer | File | What changed |
|---|---|---|
| L1 — Plugin | `to_copy/crazysim_plugin/crazysim_plugin.{cpp,h}` (overlay; copied into `/root/CrazySim/...` by Dockerfile) | Four firmware‑bound queues (imu/baro/odom/cflib‑to‑firmware) unified into one `m_queueSendCfFirm` with capacity 256. `sendCfFirmwareThread` now uses blocking `wait_dequeue_bulk_timed` instead of a `try_dequeue_bulk` tight loop. Busy‑spin `while(!socketInit) continue;` loops replaced with 1 ms sleeps. Eliminates the per‑drone busy CPU burn that itself drives RTF down. |
| L2 — Connection batching | `scripts/crazyflie_server_sim.py` | `swarm.open_links()` (parallel) replaced with a sequential/batched loop. Tunable via ROS params `connection_batch_size` (default 1 = fully sequential) and `connection_batch_delay_sec` (default 1.0). Each drone now finishes its TOC/param handshake before the next one competes for firmware CPU. |
| L3 — cflib resend timeout | `Dockerfile` (sed patch) | Default `timeout=0.2` → `1.0` in `cflib/crazyflie/__init__.py::send_packet`. At low RTF the firmware answers in >0.2 s, so the original default fires resends every 0.2 s and floods the firmware further, slowing it more. 1.0 s breaks that feedback loop. |
| L4a — Sensor rates | `to_copy/models/crazyflie/model.sdf.jinja` | Baro 50 → 20 Hz, camera 30 → 15 Hz, odom 200 → 50 Hz. **IMU kept at 1000 Hz** because it is the firmware's stabilizer clock and changing it destabilises hover. |
| L4b — Visual load | `worlds/*_world.sdf` | `<shadows>false</shadows>` and `<cast_shadows>false</cast_shadows>` on the sun. Big GPU win at large N; the GUI still works. |
| L5 — CPU pinning | `launch/sitl_multiagent_text.sh` | Gazebo pinned to cores `0..GZ_CORES-1` (default 2); cf2 firmware instances round‑robined across the remaining cores with `taskset -c`. Override via `GZ_CORES=N` env. Prevents Linux from preempting all firmware instances onto the same cores as Gazebo physics. |

**Rebuild matrix:**

| Files touched | What to re‑run |
|---|---|
| `to_copy/crazysim_plugin/*`, `to_copy/models/*`, `Dockerfile` (L1, L3, L4a) | `./build.sh sim` (rebakes the image) and delete `~/ros2_ws/install ~/ros2_ws/build` before `./first_run.sh sim` so colcon rebuilds |
| `scripts/crazyflie_server_sim.py` (L2) | `colcon build --packages-select hero_crazyflies_benchmarking` inside the container |
| `worlds/*.sdf`, `launch/sitl_multiagent_text.sh` (L4b, L5) | Just relaunch — volume‑mounted, no rebuild |

**Runtime tuning:** start with defaults. If you still see timeouts as you ramp N, raise `connection_batch_delay_sec` (it's the cheapest knob to turn). If the firmware processes are starving each other, set `GZ_CORES=1` (or `0` on low‑core hosts) to give cf2 more cores.


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
