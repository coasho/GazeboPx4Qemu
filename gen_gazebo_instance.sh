#!/bin/bash
# gen_gazebo_instance.sh - 生成 Gazebo 多实例配置（TCP 端口）
# 用法: ./gen_gazebo_instance.sh <instance_id> [output_dir]

set -e

INSTANCE_ID=${1:-1}
OUTPUT_DIR=${2:-"./gazebo_instance_${INSTANCE_ID}"}
GZ_SITL_ROOT=${GZ_SITL_ROOT:-"/mavlink_sitl_gazebo"}

# ============== GPS 配置（按实例号） ==============
# 格式: GPS_<实例号>="纬度,经度,海拔,航向"
# 没配置的实例使用 DEFAULT

DEFAULT="30.70723657,103.95386864,520.3,0"

GPS_1="30.70723657,103.95386864,520.3,0"  # 原点
GPS_2="30.70724837,103.95385287,520.3,0"  # 左侧2米
GPS_3="30.70722477,103.95388441,520.3,0"  # 右侧2米
# GPS_4="..."
# GPS_5="..."

# ============== 读取配置 ==============
VAR_NAME="GPS_${INSTANCE_ID}"
GPS_CONFIG="${!VAR_NAME:-$DEFAULT}"
IFS=',' read -r LATITUDE LONGITUDE ELEVATION HEADING <<< "$GPS_CONFIG"

# ============== 端口计算 ==============
OFFSET=$((INSTANCE_ID - 1))
TCP_PORT=$((4560 + OFFSET))
GAZEBO_MASTER_PORT=$((11345 + OFFSET))

echo "=========================================="
echo "  Gazebo 实例 #${INSTANCE_ID}"
echo "  TCP: ${TCP_PORT} | Master: ${GAZEBO_MASTER_PORT}"
echo "  GPS: ${LATITUDE}, ${LONGITUDE} @ ${ELEVATION}m, 航向${HEADING}°"
echo "=========================================="

mkdir -p "${OUTPUT_DIR}/models/iris_hitl_${INSTANCE_ID}"
mkdir -p "${OUTPUT_DIR}/worlds"

# model.config
cat > "${OUTPUT_DIR}/models/iris_hitl_${INSTANCE_ID}/model.config" << EOF
<?xml version="1.0"?>
<model>
  <name>iris_hitl_${INSTANCE_ID}</name>
  <version>1.0</version>
  <sdf version='1.5'>iris_hitl.sdf</sdf>
  <description>Iris HITL Instance ${INSTANCE_ID} - TCP:${TCP_PORT}</description>
</model>
EOF

# 修改 SDF 中的 TCP 端口
TEMPLATE_SDF="${GZ_SITL_ROOT}/models/iris_hitl/iris_hitl.sdf"
sed "s|<mavlink_tcp_port>4560</mavlink_tcp_port>|<mavlink_tcp_port>${TCP_PORT}</mavlink_tcp_port>|g" \
    "${TEMPLATE_SDF}" > "${OUTPUT_DIR}/models/iris_hitl_${INSTANCE_ID}/iris_hitl.sdf"
HEADING_RAD=$(echo "scale=6; ${HEADING} * 3.14159265359 / 180" | bc)
# world 文件
cat > "${OUTPUT_DIR}/worlds/hitl_iris_${INSTANCE_ID}.world" << EOF
<?xml version="1.0" ?>
<sdf version="1.5">
  <world name="hitl_iris_world_${INSTANCE_ID}">
    <spherical_coordinates>
      <surface_model>EARTH_WGS84</surface_model>
      <latitude_deg>${LATITUDE}</latitude_deg>
      <longitude_deg>${LONGITUDE}</longitude_deg>
      <elevation>${ELEVATION}</elevation>
      <heading_deg>${HEADING}</heading_deg>
    </spherical_coordinates>

    <scene>
      <ambient>0.7 0.7 0.7 1</ambient>
      <background>0.7 0.7 0.7 1</background>
      <shadows>false</shadows>
    </scene>

    <include><uri>model://sun</uri></include>

    <physics name='default_physics' default='0' type='ode'>
      <gravity>0 0 -9.8066</gravity>
      <max_step_size>0.004</max_step_size>
      <real_time_factor>1</real_time_factor>
      <real_time_update_rate>250</real_time_update_rate>
      <magnetic_field>2.0e-5 0 -4.2e-5</magnetic_field>
    </physics>

    <include><uri>model://ground_plane</uri></include>
    <include><uri>model://asphalt_plane</uri></include>

    <include>
      <uri>model://iris_hitl_${INSTANCE_ID}</uri>
      <pose>1.01 0.98 0.83 0 0 ${HEADING_RAD}</pose>
    </include>
  </world>
</sdf>
EOF

# 启动脚本
cat > "${OUTPUT_DIR}/run.sh" << EOF
#!/bin/bash
export GAZEBO_MASTER_URI=http://localhost:${GAZEBO_MASTER_PORT}
export GAZEBO_MODEL_PATH="\${GAZEBO_MODEL_PATH}:${OUTPUT_DIR}/models:${GZ_SITL_ROOT}/models"
export GAZEBO_PLUGIN_PATH="${GZ_SITL_ROOT}/plugins:\${GAZEBO_PLUGIN_PATH}"
export LD_LIBRARY_PATH="${GZ_SITL_ROOT}/plugins:\${LD_LIBRARY_PATH}"
echo "Gazebo #${INSTANCE_ID} | TCP:${TCP_PORT} | Master:${GAZEBO_MASTER_PORT}"
source /mavlink_sitl_gazebo/setup.sh \$(pwd) \$(pwd)/build/px4_sitl_default
export HEADLESS=1
gzserver --verbose "${OUTPUT_DIR}/worlds/hitl_iris_${INSTANCE_ID}.world"
EOF
chmod +x "${OUTPUT_DIR}/run.sh"

echo "完成: ${OUTPUT_DIR}/run.sh"