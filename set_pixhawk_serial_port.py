import os
import xml.etree.ElementTree as ET

# 환경 변수 읽기
pixhawk_serial_port = os.getenv('PIXHAWK_SERIAL_PORT', 'ttyACM0')

# SDF 파일 경로
sdf_file_path = '/home/user/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/models/iris_hitl/iris_hitl.sdf'

# SDF 파일 읽기
tree = ET.parse(sdf_file_path)
root = tree.getroot()

# serialDevice 태그 찾기 및 변경
for serial_device in root.findall('.//serialDevice'):
    serial_device.text = f'/dev/{pixhawk_serial_port}'

# 변경된 SDF 파일 저장
updated_sdf_file_path = '/home/user/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/models/iris_hitl/iris_hitl.sdf'
tree.write(updated_sdf_file_path, encoding='utf-8', xml_declaration=True)

print(f"Updated SDF file saved as '{updated_sdf_file_path}'")

