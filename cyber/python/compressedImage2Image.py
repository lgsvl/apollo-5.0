# ****************************************************************************
# Copyright 2018 The Apollo Authors. All Rights Reserved.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ****************************************************************************
# -*- coding: utf-8 -*-
from modules.common.util.testdata.simple_pb2 import SimpleMessage
from cyber_py import cyber
from modules.drivers.proto.sensor_image_pb2 import Image, CompressedImage

"""Module for example of talker."""

import time
import sys
import io
from PIL import Image as PIL_Image

sys.path.append("../")

videoWidth = 1920;
videoHeight = 1080;

def callback(data):
    """
    reader message callback.
    """
    # print "="*80
    # print "py:reader callback msg->:"
    print("header.timestamp_sec:", data.header.timestamp_sec)
    # print len(data.data), type(data.data)
    image_stream = io.BytesIO(data.data)
    image_file = PIL_Image.open(image_stream)
    # print("image size:", image_file.size)
    # print("="*80)

    image_msg = Image()
    image_msg.header.timestamp_sec = data.header.timestamp_sec
    image_msg.header.module_name = data.header.module_name
    image_msg.header.sequence_num = data.header.sequence_num
    image_msg.header.lidar_timestamp = data.header.lidar_timestamp
    image_msg.header.camera_timestamp = data.header.camera_timestamp
    image_msg.header.radar_timestamp = data.header.radar_timestamp
    image_msg.header.version = data.header.version
    image_msg.header.frame_id = data.header.frame_id

    image_msg.frame_id = data.frame_id
    image_msg.measurement_time = data.measurement_time
		
    image_msg.height = videoHeight
    image_msg.width = videoWidth
    image_msg.encoding = "rgb8"
    image_msg.step = videoWidth * 3

    image_msg.data = image_file.tobytes()
    writer.write(image_msg)


def decompress():
    """
    reader message.
    """
    print "=" * 120
    print "Waiting"
    test_node.create_reader("/apollo/sensor/camera/"+frame_id+"/image/compressed",
            CompressedImage, callback)
    test_node.spin()



if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python compressedImage2Image.py <frame_id>")
        exit()
    print("frame_id is: ", sys.argv[1])

    frame_id = sys.argv[1]
    cyber.init("compressedImage2Image")
    test_node = cyber.Node("decompress_"+frame_id)
    writer = test_node.create_writer("/apollo/sensor/camera/"+frame_id+"/image",
                                     Image, 6)
    decompress()
    cyber.shutdown()
