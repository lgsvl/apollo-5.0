# LGSVL Fork of Apollo 5.0
This repository is a fork of [Apollo](https://github.com/ApolloAuto/apollo) maintained by LG Electronics which has been modified and configured to be used with [SVL Simulator](https://github.com/lgsvl/simulator).

**The software and source code in this repository are intended only for use with SVL Simulator and *should not* be used in a real vehicle.**

## How to Use

Instructions for using this repository appear in the **Running Apollo 5.0 with SVL Simulator** section of the [SVL Simulator documentation](https://www.svlsimulator.com/docs/installation-guide/system-under-test/apollo5-0-instructions.md).


## Other Information
### Building and Publishing a Standalone Runtime Docker Image

After you have tested your changes to Apollo 5.0 using your local cluster, you can create a much smaller Docker image, which cannot be used to re-build modified Apollo, but can be shared with other people to run Apollo without the need to build it locally. You can also publish it to a publicly accessible Docker registry (e.g., [Docker Hub](https://hub.docker.com/)).

To build the Docker image, run:

``` console
docker/build/standalone.x86_64.sh
```

If the development container is not running, you will see this message:
```console
Error: No such container: apollo_dev_USER
ERROR: apollo_dev_USER isn't running or doesn't have /apollo/bazel directory
       make sure it's running (you can use docker/scripts/dev_start.sh)
       and build Apollo there or add "rebuild" parameter to this script
       and it will be started and built automatically
```

Upon successful completion, you will see:

```console
...
Docker image with prebuilt files was built and tagged as lgsvl/apollo-5.0:standalone-x86_64-14.04-5.0-20210319, you can start it with:
  docker/scripts/runtime_start.sh
and switch into it with:
  docker/scripts/runtime_into_standalone.sh
```

Confirm operation of the image by starting it:

```console
docker/scripts/runtime_start.sh
```

entering into it:

```console
docker/scripts/runtime_into_standalone.sh
```

and running the appropriate commands to verify its functionality.

Finally, tag the image and push it to the publicly accessible Docker registry:

```console
docker image tag lgsvl/apollo-5.0:standalone-x86_64-14.04-5.0-20210319 REGISTRY/IMAGE:TAG
docker image push REGISTRY/IMAGE:TAG
```

To use such an image (without having to clone this repository):

```console
docker image pull REGISTRY/IMAGE:TAG
docker image tag REGISTRY/IMAGE:TAG lgsvl/apollo-5.0:standalone-x86_64-14.04-5.0-20210319

docker run --rm lgsvl/apollo-5.0:standalone-x86_64-18.04-5.0-20210319 sh -c 'tar -cf - -C /apollo standalone-scripts' | tar -xf -
cd standalone-scripts

mkdir -p modules/map/data

bash docker/scripts/runtime_start.sh
bash docker/scripts/runtime_into_standalone.sh
```

The `modules/map/data` directory is used as a volume for maps. You can either use the maps included in [simulator branch](https://github.com/lgsvl/apollo-5.0/tree/simulator/modules/map/data) of the LGSVL fork of Apollo 5.0 or download individual HD Maps as described above.
