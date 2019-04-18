#!/bin/bash

docker build -t clemenko/dc19:0.1 -f 0.1.Dockerfile .
docker build -t clemenko/dc19:0.2 -f 0.2.Dockerfile .
docker build -t clemenko/dc19:0.3 -f 0.3.Dockerfile .

docker push clemenko/dc19:0.1
docker push clemenko/dc19:0.2
docker push clemenko/dc19:0.3
