# rosbot-webots-navigation
ROSbot autonomous navigation demo in webots simulation
![ROSbot in webots simulator](.docs/rosbot.png)

## Run with `docker compose`
To start simulation build and run webots simulator container. It will take a while because the container has to download required assets:
```bash
cd demo
docker compose -f compose.rosbot.webots.yaml up --build
```

Wait until this messages show up in the Webots console.
> INFO: 'rosbot' extern controller: connected.
>
> INFO: 'Ros2Supervisor' extern controller: connected.


Open new terminal and run navigation2 with slam-toolbox:
```bash
cd demo
docker compose -f compose.rosbot.mapping.yaml up
```

Then run rviz2 to navigate the ROSBot:
```bash
cd demo
docker compose -f compose.rviz.yaml up
```
Demo is launched. Now go to rviz2 choose option `Nav2 Goal` and select position for ROSbot.
![ROSbot in rviz2 is going to pose](.docs/go_to_pose.png)