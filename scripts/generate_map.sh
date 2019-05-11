#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${DIR}/.."

source "$DIR/apollo_base.sh"

if [ $# -eq 0 ]; then
  echo "Please specify name of your map directory."
else
  dir_name=modules/map/data/$1
  bazel-bin/modules/map/tools/sim_map_generator --map_dir=${dir_name} --output_dir=${dir_name}
  bash scripts/generate_routing_topo_graph.sh --map_dir ${dir_name}
fi

