# Apollo 3.5 Cyber bridge

This is bridge that exposes custom TCP socket for accepting and transmitting Cyber messages.

# Building

Place this contents of this folder in new `/apollo/cyber/bridge` folder.

Run the build:

    bazel build //cyber/bridge:cyber_bridge

# Running

Go in `/apollo` folder and execute:

    ./bazel-bin/cyber/bridge/cyber_bridge

For extra logging:

    GLOG_v=4 GLOG_logtostderr=1 ./bazel-bin/cyber/bridge/cyber_bridge

Add extra `-port 9090` argument for custom port (9090 is default).


# Example

In on terminal launch bridge:

    ./bazel-bin/cyber/bridge/cyber_bridge

In another terminal launch example talker:

    python cyber/python/examples/talker.py 

In one more terminal launch example listener:

    python cyber/python/examples/listener.py 

Now you should see talker and listener sending & receiving message with incrementing integer.

Now open Unity project. Change bridge IP in `CyberTest.cs` file and run the projec. You should
see in console log output same integer as talker.py is publishing. If you press `[space]` key
Unity will send message to Cyber - you should see current time as integer & string appearing
in listener.py terminal.
