#!/bin/bash

mkdir -p package/python

pip install -r requirements.txt -t package/python

cp lambda_function.py package/
cp config.json package/

cd package
zip -r ../lambda_function.zip .

cd ..
rm -rf package