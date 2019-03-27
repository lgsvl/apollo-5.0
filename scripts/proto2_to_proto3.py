'''
This script convert all protos under <topdir> from proto2 to proto3 inplace
and generate all csharp protobuf files in <save_directory>

usage:
	python proto2_to_proto3.py for all protos
	python proto2_to_proto3.py your_proto_path for one proto
'''

# After conversion, replace "Apollo.Drivers.ContiRadar" with "Apollo.Drivers.Conti_Radar" for only whole word
# in Drivers/ContiRadar.cs and Drivers/ContiRadar/ContiRadarConf.cs
# in Drivers/ContiRadar.cs Change typeof(global::Apollo.Drivers.Conti_Radar), global::Apollo.Drivers.Conti_Radar.Parser
# to typeof(global::Apollo.Drivers.ContiRadar), global::Apollo.Drivers.ContiRadar.Parser

import sys, os
import re
topdir = '.' # find all protos under this topdir
save_directory = "./csharp_protos"


def add_dummy_enum(data):
	enum_dummy = "_DUMMY = 0;\n"
	enum_end_positions = [m.end() - 1 for m in re.finditer('enum [A-Z]', data)] # note: end() is the actual end position + 1, here it is also the start of type name

	for pos in enum_end_positions[::-1]: # reversed to avoid later enum type end_positions change
		idx = 1
		while data[pos+idx] != '{':
			idx +=1

		# retrieve type name to have different dummy enum for each type
		type_name = data[pos:pos+idx-1]

		if type_name == "SensorType":
			# look for 1st -1
			idx2 = 1
			while data[pos+idx+idx2] != ';':
				idx2 += 1
			first_enum = data[pos+idx+1:pos+idx+idx2+1]
			# look for 1st 0
			idx3 = idx2 + 1
			while data[pos+idx+idx3] != ';':
				idx3 += 1
			second_enum = data[pos+idx+idx2+1:pos+idx+idx3+1]
			print first_enum, second_enum
			data = data[:pos+idx+1] + second_enum + first_enum + data[pos+idx+idx3+1:]
			continue

		# check whether the first enum is 0
		idx2 = 1
		while data[pos+idx+idx2] != '=':
			idx2 +=1

		# if the first enum equals 0, satisfy constraint of proto3
		if data[pos+idx+idx2+2] == '0' or (data[pos+idx+idx2+2:pos+idx+idx2+4] == ' 0'):
			continue

		data = data[:pos+idx+2] + "    " + type_name.upper() + enum_dummy + data[pos+idx+2:] # add dummy enum after '{\n'
		# print("\t added one dummy enum")
		# print data

	return data


def remove_default(data):
	# search [, and find ], get their positions
	strings_to_delete = set()
	for idx, char in enumerate(data):
		if char == '[':
			string_start = idx
		if char == ']':
			string_end = idx
			strings_to_delete.add(data[string_start:string_end+1])

	for string in strings_to_delete:
		data = data.replace(string, "")

	return data


def proto2_to_proto3(proto_file_path):
	# replace "proto2" with "proto3"
	# remove "optional "
	# remove default values

	# read file
	f = open(proto_file_path, 'r')
	file_data = f.read()
	f.close()

	global protos_without_base
	if file_data.find('package') == -1:
		protos_without_base.add(proto_file_path)

	data = file_data.replace("optional ", "").replace("proto2", "proto3").replace("required", "")
	data = remove_default(data)
	data = add_dummy_enum(data)

	f = open(proto_file_path, 'w')
	f.write(data)
	f.close()



def find_all_protos(topdir, extension):
	# return the list of all proto paths

	paths = []

	def step(ext, dirname, names):
		ext = ext.lower()

		for name in names:
			if name.lower().endswith(ext) and name.find("racobit") == -1: # do not convert Racobit due to naming conflict and we are not using this radar
				# print(os.path.join(dirname, name))
				paths.append(os.path.join(dirname, name))

	os.path.walk(topdir, step, extension)
	return paths


''' Convert all proto files and Generate CS protobuf files '''
cmd = "~/Documents/protoc-3.3.0-linux-x86_64/bin/protoc -I. --csharp_out=./csharp_protos/ --csharp_opt=base_namespace=Apollo"
cmd_without_base = "~/Documents/protoc-3.3.0-linux-x86_64/bin/protoc -I. --csharp_out=./csharp_protos/"
protos_without_base = set()
os.chdir('..')

if not os.path.exists(save_directory):
    os.makedirs(save_directory)

if len(sys.argv) > 1:
	all_proto_files = [sys.argv[1]]
else:
	all_proto_files = find_all_protos(topdir, '.proto')

for proto_file in all_proto_files:
	proto2_to_proto3(proto_file)
	print("Converted file:", proto_file)
print("\nTotal: " + str(len(all_proto_files)) + " proto files.")

# separate two steps since some protos are depending on others
for proto_file_path in all_proto_files:
	if proto_file_path in protos_without_base:
		os.system(cmd_without_base + " " + proto_file_path)
	else:
		os.system(cmd + " " + proto_file_path)
	print("Generated csharp proto file:", proto_file_path)
	print

# checkout all protos
os.system("git checkout *.proto")
print("Checkout all protos back\n")
