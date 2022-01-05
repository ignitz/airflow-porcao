#!/bin/bash

BACKEND_S3_BUCKET=yuriniitsuma
CI_PROJECT_PATH=boizao
terraform init --backend-config="bucket=$BACKEND_S3_BUCKET" --backend-config="key=terraform/$CI_PROJECT_PATH" --backend-config="region=us-east-1"