#!/bin/bash

base_url="https://assets.yadvashem.org/image/upload/t_f_low_image/f_auto/v1/remote_media/documentation4/16/12612299_03263622/"

for i in {1..700}
do
    wget "${base_url}$(printf "%05d" $i).JPG"
done
