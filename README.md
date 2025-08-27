# frigate-config

Associated files from my blog article titled ***[Frigate 0.16 Installation Tutorial](https://beardedtek.org/frigate-0-16-installation-tutorial/)***

|                   |                   |                                                                         |
| :---------------- | :---------------- | ----------------------------------------------------------------------- |
| [models](models)  | [export_yolov9.sh](models/export_yolov9.sh) | builds docker build command that exports YOLOv9 models to ONNX |
| [models](models)  | [Dockerfile](models/Dockerfile) | Dockerfile for YOLOv9 export |
| [config.yml](config.yml) | | Full example config.yml for frigate |
| [docker-compose.yml](docker-compose.yml)| | Full docker-compose.yml example |
| [.env](.env) | | Complete .env example |

# Instructions

### Clone this repository

```
git clone https://github.com/beardedtek/frigate-config
cd friate-config
```

### Run YOLOv9 Model Export Script

Execute the script and follow the prompts

```
./models/export_yolov9.sh
```

### Adjust the docker-compose.yml and .env to your environment

You may need to make changes to paths and values in the .env to suit your setup.

### Bring it up
```
docker compose up -d
```
