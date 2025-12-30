# GazeboPortable

[中文](README_zh.md) | English

A portable Gazebo + PX4 + QEMU multi-drone simulation environment with one-click deployment on Windows platform.

## ✨ Features

- 🚀 **One-Click Launch**: Ready-to-use simulation environment without complex configuration
- 🎮 **Multi-Instance Management**: Run multiple drone instances simultaneously
- 🖥️ **Full Integration**: Integrated Gazebo, PX4, QEMU and QGroundControl
- 📦 **Portable Design**: All dependencies packaged, no system-level installation required
- 🔧 **Visual Management**: User-friendly GUI for instance and service management

## 🖼️ Feature Showcase

### Instance Manager

#### Service Startup
Start the QEMU virtual machine service to provide the runtime foundation for the simulation environment.

![Service Stopped](docs/images/service-stopped.png)

#### Virtual Machine Boot
First boot may take 1-2 minutes, please be patient.

![VM Starting](docs/images/vm-starting.png)

#### Create Instance
After the QEMU service is running, you can create and manage multiple Gazebo instances.

![No Instances](docs/images/no-instances.png)

#### Single Instance Running
Each instance runs independently with its own TCP port and MAVLink connection.

![Single Instance](docs/images/single-instance.png)

#### Multi-Instance Coordination
Support running multiple instances simultaneously to simulate multi-vehicle scenarios.

![Multiple Instances](docs/images/multiple-instances.png)

#### PX4 Activation
Activate the PX4 autopilot firmware after instance startup.

![PX4 Activated](docs/images/px4-activated.png)

### QGroundControl Integration

#### Multi-Vehicle Ground Station
Monitor and control multiple drones simultaneously in QGroundControl.

![QGC Multiple Vehicles](docs/images/qgc-multiple-vehicles.png)

#### Mission Execution
Support waypoint planning, mission upload and real-time flight monitoring.

![QGC Flying](docs/images/qgc-flying.png)

## 🚀 Quick Start

### Prerequisites

- Windows 10/11 (64-bit)
- At least 8GB RAM
- CPU with virtualization support

### Clone Repository

```bash
git clone https://github.com/coasho/GazeboPx4Qemu.git
cd GazeboPx4Qemu
```

> **Note**: This repository uses Git LFS for large files. Please install [Git LFS](https://git-lfs.github.com/) before cloning.

### Launch Steps

1. **Start Instance Manager**
   ```bash
   gazebo-win-desk.exe
   ```

2. **Start QEMU Service**
    - Click the "Start Service" button in the upper right corner
    - Wait for the virtual machine to boot (first boot takes 1-2 minutes)

3. **Create Instance**
    - Click "+ New Instance" to create a new Gazebo instance
    - Wait for the instance to start

4. **Activate PX4**
    - Click the "⚡ PX4" button next to the instance to activate autopilot
    - The instance will automatically connect to PX4 firmware

5. **Connect QGroundControl**
    - Launch QGroundControl
    - It will automatically discover and connect to running instances

## 📋 Instance Information

Each instance contains the following information:

- **TCP Port**: Gazebo communication port (e.g., 4560, 4561, 4562...)
- **Master Port**: ROS Master port (e.g., 11345, 11346, 11347...)
- **Status**: Running / Starting / Stopped

## 🔧 Port Configuration

Default port assignment:

| Instance | TCP Port | Master Port | MAVLink Port |
|----------|----------|-------------|--------------|
| #1       | 4560     | 11345       | 14550        |
| #2       | 4561     | 11346       | 14551        |
| #3       | 4562     | 11347       | 14552        |

## 📁 Directory Structure

```
GazeboPx4Qemu/
├── vm/
│   └── gazebo.qcow2          # QEMU VM image (Git LFS)
├── PX4-standalone/
│   └── home/Firmware/
│       └── bin/px4.exe       # PX4 firmware
├── gazebo-win-desk.exe  # Instance manager
└── README.md
```

## ⚙️ System Logs

The Instance Manager provides three log views:

- **System Logs**: System-level logs showing QEMU and manager status
- **PX4 Logs**: PX4 firmware runtime logs
- **CCS-Host Logs**: Custom control service logs

## 🐛 Troubleshooting

### QEMU Service Won't Start

- Ensure Windows virtualization is enabled (Hyper-V)
- Check if firewall is blocking QEMU process
- Try running as administrator

### Instance Creation Failed

- Confirm QEMU service is running properly
- Check if ports are already in use
- View System Logs for detailed error messages

### QGroundControl Can't Connect

- Confirm the instance has PX4 activated
- Check if MAVLink port is occupied
- Manually add UDP connection in QGC: `localhost:14550`

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🔗 Related Links

- [PX4 Autopilot](https://px4.io/)
- [Gazebo Simulator](http://gazebosim.org/)
- [QGroundControl](http://qgroundcontrol.com/)
- [QEMU](https://www.qemu.org/)

## 📧 Contact

For questions or suggestions, please contact us via GitHub Issues.

---

⭐ If this project helps you, please give it a star!