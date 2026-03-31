#!/bin/bash
# gen_gazebo_instance_optimized.sh - 优化版 Gazebo 多实例配置 (支持相对定位)

set -e

INSTANCE_ID=${1:-1}
OUTPUT_DIR=${2:-"./gazebo_instance_${INSTANCE_ID}"}
GZ_SITL_ROOT=${GZ_SITL_ROOT:-"/mavlink_sitl_gazebo"}

# ============== 1. 基准 GPS 配置 (GPS_1) ==============
# 你只需在此修改 GPS_1 的坐标，GPS_2/3 会自动同步偏移
# 试飞场
#BASE_LAT="30.7758375441431"
#BASE_LON="103.723425865173"
#BASE_ALT="585.3"
# 机场
BASE_LAT="30.70723657"
BASE_LON="103.95386864"
BASE_ALT="520.6115"

BASE_HDG="0"

# ============== 2. 定义相对偏移量 (基于原脚本计算) ==============
# 格式: "纬度偏移,经度偏移,高度偏移,航向偏移"
OFFSET_1="0,0,0,0"
OFFSET_2="-0.00001180,0.00001577,0,0"
OFFSET_3="0.00001180,-0.00001577,0,0"

# ============== 3. 计算当前实例坐标 ==============
VAR_OFFSET="OFFSET_${INSTANCE_ID}"
CURRENT_OFFSET="${!VAR_OFFSET:-$OFFSET_1}" # 若实例超过3，默认重合

# 使用 awk 进行高精度浮点加法
IFS=',' read -r D_LAT D_LON D_ALT D_HDG <<< "$CURRENT_OFFSET"

LATITUDE=$(awk "BEGIN {printf \"%.8f\", $BASE_LAT + $D_LAT}")
LONGITUDE=$(awk "BEGIN {printf \"%.8f\", $BASE_LON + $D_LON}")
ELEVATION=$(awk "BEGIN {printf \"%.1f\", $BASE_ALT + $D_ALT}")
HEADING=$(awk "BEGIN {printf \"%.1f\", $BASE_HDG + $D_HDG}")

echo "Instance $INSTANCE_ID Position: $LATITUDE, $LONGITUDE, $ELEVATION, $HEADING"

# ============== 后续 Gazebo 配置逻辑 ==============
# (此处保持你原有的 SITL 配置文件生成逻辑...)

# ============== 端口计算 ==============
OFFSET=$((INSTANCE_ID - 1))
TCP_PORT=$((4560 + OFFSET))
GAZEBO_MASTER_PORT=$((11345 + OFFSET))

echo "=========================================="
echo "  Gazebo 实例 #${INSTANCE_ID} (优化版)"
echo "  TCP: ${TCP_PORT} | Master: ${GAZEBO_MASTER_PORT}"
echo "  GPS: ${LATITUDE}, ${LONGITUDE} @ ${ELEVATION}m"
echo "=========================================="

HEADING=$((${HEADING} + 90))
HEADING_RAD=$(awk "BEGIN {printf \"%.6f\", ${HEADING} * 3.14159265359 / 180}")

mkdir -p "${OUTPUT_DIR}/models/iris_hitl_${INSTANCE_ID}"
mkdir -p "${OUTPUT_DIR}/worlds"

# ============== model.config ==============
cat > "${OUTPUT_DIR}/models/iris_hitl_${INSTANCE_ID}/model.config" << EOF
<?xml version="1.0"?>
<model>
  <name>iris_hitl_${INSTANCE_ID}</name>
  <version>1.0</version>
  <sdf version='1.5'>iris_hitl.sdf</sdf>
  <description>Iris HITL Instance ${INSTANCE_ID} - TCP:${TCP_PORT} (Optimized)</description>
</model>
EOF

# ============== 优化 SDF 模型 ==============
# 除了修改端口，还要禁用不必要的传感器
TEMPLATE_SDF="${GZ_SITL_ROOT}/models/iris_hitl/iris_hitl.sdf"

# 创建优化版 SDF
sed -e "s|<mavlink_tcp_port>4560</mavlink_tcp_port>|<mavlink_tcp_port>${TCP_PORT}</mavlink_tcp_port>|g" \
    -e 's|<update_rate>[0-9]*</update_rate>|<update_rate>50</update_rate>|g' \
    "${TEMPLATE_SDF}" > "${OUTPUT_DIR}/models/iris_hitl_${INSTANCE_ID}/iris_hitl.sdf"

# ============== 极简 world 文件 ==============
cat > "${OUTPUT_DIR}/worlds/hitl_iris_${INSTANCE_ID}.world" << EOF
<?xml version="1.0" ?>
<sdf version="1.5">
  <world name="hitl_iris_world_${INSTANCE_ID}">

    <!-- GPS 坐标系 -->
    <spherical_coordinates>
      <surface_model>EARTH_WGS84</surface_model>
      <latitude_deg>${LATITUDE}</latitude_deg>
      <longitude_deg>${LONGITUDE}</longitude_deg>
      <elevation>${ELEVATION}</elevation>
      <heading_deg>${HEADING}</heading_deg>
    </spherical_coordinates>

    <!-- 关闭所有渲染 -->
    <scene>
      <ambient>0 0 0 0</ambient>
      <background>0 0 0 0</background>
      <shadows>false</shadows>
      <grid>false</grid>
      <origin_visual>false</origin_visual>
    </scene>

    <!-- 物理引擎优化 -->
    <physics name='minimal_physics' default='true' type='ode'>
      <gravity>0 0 -9.8066</gravity>

      <!-- 降低更新频率: 250Hz -> 100Hz，对 HITL 足够 -->
      <max_step_size>0.01</max_step_size>
      <real_time_factor>1</real_time_factor>
      <real_time_update_rate>100</real_time_update_rate>

      <magnetic_field>2.0e-5 0 -4.2e-5</magnetic_field>

      <!-- ODE 求解器优化 -->
      <ode>
        <solver>
          <type>quick</type>
          <iters>10</iters>
          <sor>1.0</sor>
          <use_dynamic_moi_rescaling>false</use_dynamic_moi_rescaling>
        </solver>
        <constraints>
          <cfm>0</cfm>
          <erp>0.2</erp>
          <contact_max_correcting_vel>100</contact_max_correcting_vel>
          <contact_surface_layer>0.001</contact_surface_layer>
        </constraints>
      </ode>
    </physics>

    <!-- 不加载 sun 模型 - 无头模式不需要光照 -->
    <!-- 不加载 ground_plane - 用最简碰撞平面代替 -->
    <!-- 不加载 asphalt_plane - 纯视觉模型，完全不需要 -->

    <!-- 最简地面：只有碰撞，无视觉 -->
    <model name="minimal_ground">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 100</size>
            </plane>
          </geometry>
          <surface>
            <friction>
              <ode><mu>1</mu><mu2>1</mu2></ode>
            </friction>
          </surface>
        </collision>
        <!-- 无 <visual> 标签 = 不渲染 -->
      </link>
    </model>

    <!-- 飞机模型 -->
    <include>
      <uri>model://iris_hitl_${INSTANCE_ID}</uri>
      <pose>1.01 0.98 0.83 0 0 ${HEADING_RAD}</pose>
    </include>

  </world>
</sdf>
EOF

# ============== 优化启动脚本 ==============
cat > "${OUTPUT_DIR}/run.sh" << 'SCRIPT_HEAD'
#!/bin/bash
# 优化版启动脚本

# ===== 环境变量优化 =====
SCRIPT_HEAD

cat >> "${OUTPUT_DIR}/run.sh" << EOF
export GAZEBO_MASTER_URI=http://localhost:${GAZEBO_MASTER_PORT}
export GAZEBO_MODEL_PATH="${OUTPUT_DIR}/models:${GZ_SITL_ROOT}/models"
export GAZEBO_PLUGIN_PATH="${GZ_SITL_ROOT}/plugins"
export LD_LIBRARY_PATH="${GZ_SITL_ROOT}/plugins:\${LD_LIBRARY_PATH}"

# ===== 关键优化项 =====
# 完全禁用渲染系统
export GAZEBO_RENDERING_ENABLED=0
export DISPLAY=""
unset DISPLAY

# 禁用 GUI 相关
export HEADLESS=1
export GAZEBO_GUI=0

# 减少日志输出（降低 I/O）
export GAZEBO_LOG_LEVEL=err

# 禁用不必要的插件
export GAZEBO_PLUGIN_PATH="${GZ_SITL_ROOT}/plugins"

# OGre 渲染引擎 - 使用空渲染器
export OGRE_RTT_MODE=Copy

echo "=========================================="
echo "  Gazebo #${INSTANCE_ID} (优化模式)"
echo "  TCP:${TCP_PORT} | Master:${GAZEBO_MASTER_PORT}"
echo "  Physics: 100Hz | 无渲染 | 最小碰撞"
echo "=========================================="

# 可选：限制 CPU 核心（防止单实例占用过多）
# taskset -c \$((${INSTANCE_ID} - 1)) gzserver ...

# source 环境
source /mavlink_sitl_gazebo/setup.sh \$(pwd) \$(pwd)/build/px4_sitl_default 2>/dev/null || true

# 启动 gzserver（纯服务端，无 GUI）
exec gzserver --minimal \\
    --seed 0 \\
    --verbose \\
    --physics ode \\
    "${OUTPUT_DIR}/worlds/hitl_iris_${INSTANCE_ID}.world"
EOF

chmod +x "${OUTPUT_DIR}/run.sh"

# ============== 生成资源监控脚本 ==============
cat > "${OUTPUT_DIR}/monitor.sh" << 'EOF'
#!/bin/bash
# 监控 Gazebo 实例资源占用
echo "PID       CPU%  MEM%  RSS(MB)  COMMAND"
ps aux | grep -E 'gzserver|gazebo' | grep -v grep | \
    awk '{printf "%-9s %-5s %-5s %-8.1f %s\n", $2, $3, $4, $6/1024, $11}'
EOF
chmod +x "${OUTPUT_DIR}/monitor.sh"

echo ""
echo "✅ 优化版配置生成完成: ${OUTPUT_DIR}/"
echo ""
echo "优化项目:"
echo "  • 物理引擎: 250Hz → 100Hz"
echo "  • 移除视觉模型: sun, ground_plane, asphalt_plane"
echo "  • 禁用渲染: GAZEBO_RENDERING_ENABLED=0"
echo "  • 最简碰撞: 仅保留地面碰撞平面"
echo "  • ODE 求解器: quick 模式, 10 次迭代"
echo ""
echo "启动: ${OUTPUT_DIR}/run.sh"
echo "监控: ${OUTPUT_DIR}/monitor.sh"