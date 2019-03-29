#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${DIR}/.."

source "$DIR/apollo_base.sh"

echo `pwd`
bazel-bin/cyber/bridge/cyber_bridge
mainboard -d modules/drivers/tools/image_decompress/dag/image_decompress.dag  
