#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/apollo_base.sh"

function start() {
  front_6mm_channel="-c /apollo/sensor/camera/front_6mm/image "
  # camera_channels+="-c /apollo/sensor/camera/obstacle/front_6mm "
  front_12mm_channel="-c /apollo/sensor/camera/front_12mm/image "

  lidar_unified_channel="-c /apollo/sensor/lidar128/VelodyneScanUnified "
  lidar_raw_channel="-c /apollo/sensor/lidar128/PointCloud2 "
  lidar_compensated_channel="-c /apollo/sensor/lidar128/compensator/PointCloud2 "

  radar_channel="-c /apollo/sensor/conti_radar "

  gps_channels="-c /apollo/sensor/gnss/best_pose "
  gps_channels+="-c /apollo/sensor/gnss/corrected_imu "
  gps_channels+="-c /apollo/sensor/gnss/gnss_status "
  gps_channels+="-c /apollo/sensor/gnss/imu "
  gps_channels+="-c /apollo/sensor/gnss/raw_data "
  gps_channels+="-c /apollo/sensor/gnss/ins_stat "
  gps_channels+="-c /apollo/sensor/gnss/odometry "
  gps_channels+="-c /apollo/sensor/gnss/rtk_eph "
  gps_channels+="-c /apollo/sensor/gnss/rtk_obs "

  chassis_channels="-c /apollo/canbus/chassis "
  chassis_channels+="-c /apollo/canbus/chassis_detail "

  localization_channels="-c /apollo/localization/pose "
  perception_channels="-c /apollo/perception/obstacles "
  perception_channels+="-c /apollo/perception/traffic_light "
  prediction_channel="-c /apollo/prediction "

  record_cmd="cyber_recorder record -m 0 -i 0 "
  record_cmd_4channels=$record_cmd
  record_cmd_4channels+="-c /apollo/sensor/gnss/ins_stat -c /apollo/sensor/gnss/odometry "
  record_cmd_4channels+=$front_6mm_channel
  record_cmd_4channels+=$lidar_compensated_channel

  record_cmd+="-c /apollo/drive_event "
  record_cmd+="-c /tf "
  record_cmd+="-c /tf_static "
  record_cmd+="-c /apollo/monitor "
  record_cmd+="-c /apollo/monitor/static_info "
  record_cmd+=$gps_channels
  record_cmd+=$chassis_channels
  record_cmd+=$radar_channel
  record_cmd+=$localization_channels
  record_cmd+=$perception_channels
  record_cmd+=$prediction_channel

  # parse arguments
  while getopts "hsliurcvf" opt; do
    case $opt in
      h)
        help
        exit
        ;;
      u)
        echo "Recording VelodyneScanUnified channel."
        record_cmd+=$lidar_unified_channel
        ;;
      r)
        echo "Recording raw lidar channel."
        record_cmd+=$lidar_raw_channel
        ;;
      c)
        echo "Recording compensated lidar channel."
        record_cmd+=$lidar_compensated_channel
        ;;
      v)
        echo "Recording all lidar channels."
        record_cmd+=$lidar_raw_channel
        record_cmd+=$lidar_unified_channel
        record_cmd+=$lidar_compensated_channel
        ;;
      s)
        echo "Recording image_short channel."
        record_cmd+=$front_6mm_channel
        ;;
      l)
        echo "Recording image_long channel."
        record_cmd+=$front_12mm_channel
        ;;
      i)
        echo "Recording all image channels."
        record_cmd+=$front_6mm_channel
        record_cmd+=$front_12mm_channel
        ;;
      f)
        echo "Recording four basic channels(ins_stat, odometry, image_short, lidar_compensated) for simulator."
        record_cmd=$record_cmd_4channels
    esac
  done

  if [ $# -eq 0 ]; then
    echo "Recording basic channels."
  fi

  # echo $record_cmd

  record_dir="/media/lgsvl/raid0/$(date '+%Y-%m-%d-%H-%M-%S')"
  # record_dir="/apollo/data/bag/$(date '+%Y-%m-%d-%H-%M-%S')"
  mkdir $record_dir
  cd $record_dir
  echo
  echo $record_cmd
  echo
  # Start recording.
  record_bag_env_log

  NUM_PROCESSES="$(pgrep -c -f "cyber_recorder record")"
  if [ "${NUM_PROCESSES}" -eq 0 ]; then
    $record_cmd
    echo $'\n'"Cyber record files written to $record_dir"
  fi
}

function help() {
  echo "Usage:"
  echo
  echo "$0                           if no argument, it will record basic channels."
  echo "$0 -h                        Show this help message."
  echo "$0 -v                        Record all velodyne lidar channels."
  echo "$0 -i                        Record all image channels."
  echo
  echo "$0 -c                        Record /compensator/PointCloud2 channel"
  echo "$0 -r                        Record raw PointCloud2 channel"
  echo "$0 -u                        Record VelodyneScanUnified channel"
  echo "$0 -s                        Record /front_6mm channel"
  echo "$0 -l                        Record /front_12mm channel"
  echo
  echo "$0 -f                        Record four basic channels(ins_stat, odometry, front_6mm, lidar_compensated)"
}

start $@
