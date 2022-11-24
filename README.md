# rosbot-webots-navigation
ROSbot autonomous navigation demo in webots simulation

# Run with `docker compose`
To start simulation start webots service:
```
cd demo
docker compose -f compose.rosbot.webots.yaml up --build
```

After `Ros2Supervisor` is connected.
```
INFO: 'rosbot' extern controller: connected.
INFO: 'Ros2Supervisor' extern controller: connected.
```

Open new terminal and run navigation2 with slam-toolbox:
```
cd demo
docker compose -f compose.rosbot.mapping.yaml up
```

Then run rviz2 to navigate the ROSBot:
```
cd demo
docker compose -f compose.rviz.yaml up
```