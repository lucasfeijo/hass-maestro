# Add-on build container

The Dockerfile uses the standard Home Assistant base images defined in
`build.yaml` and is built with `home-assistant/builder`.

Local builds mirror the Home Assistant process:

```bash
docker build -t maestro-addon ./docker
docker run --rm maestro-addon
```
