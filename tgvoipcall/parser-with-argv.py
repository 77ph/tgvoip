#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat 19 Oct 2019 02:34:47 AM EDT

@author: 77ph
"""
### версия для сдечи проекта от 26-10-19. 

import requests
import json
import sys
import os

if(len(sys.argv) < 5):
        print("Usage: {} ./sound_A.ogg ./sound_output_B.ogg ./sound_B.ogg ./sound_output_A.ogg".format(sys.argv[0]))
        sys.exit(1)

file1 = sys.argv[1]
file2 = sys.argv[2]
file3 = sys.argv[3]
file4 = sys.argv[4]

suffix = ".opus"

if file1.endswith(suffix):
        print("Please use {} with .ogg".format(file1))
        sys.exit(1)

if file2.endswith(suffix):
        print("Please use {} with .ogg".format(file2))
        sys.exit()

if file3.endswith(suffix):
        print("Please use {} with .ogg".format(file3))
        sys.exit(1)

if file4.endswith(suffix):
        print("Please use {} with .ogg".format(file4))
        sys.exit(1)

auth_token="127859963:525cec3227216c14addebfc4241793c6ef4e"
url="https://api.contest.com/voip" + auth_token + "/getConnection?call={call}"
querystring=""
r=requests.get(url, params=querystring)
acc = r.json()

if acc['ok'] == True:
        cfg = acc["result"]["config"]
        encryption_key = acc["result"]["encryption_key"]
        id = acc["result"]["endpoints"][0]["id"]
        ipv4 = acc["result"]["endpoints"][0]["ip"]
        port = acc["result"]["endpoints"][0]["port"]
        peer_tags_caller = acc["result"]["endpoints"][0]["peer_tags"]["caller"]
        peer_tags_callee = acc["result"]["endpoints"][0]["peer_tags"]["callee"]
        hs = open("config.json", 'w')
        hs.write(json.dumps(cfg))
        hs.close()


        #./tgvoipcall 127.0.0.1:555 ssssssssss -k encryption_key_hex -i /path/to/sound_A.ogg -o /path/to/sound_output_B.ogg -c config.json
        ss = open("start_A.sh","w")
        run = "../cpp/tgvoipcall " + ipv4 + ":" + port + " " + peer_tags_caller + " -k " + encryption_key + " -i " + file1 + " -o " + file2 + " -c config.json" + " -l " + id + " -r caller"
        ss.write(run)
        ss.close() 
        ss = open("start_B.sh","w")
        run = "../cpp/tgvoipcall " + ipv4 + ":" + port + " " + peer_tags_callee + " -k " + encryption_key + " -i " + file3 + " -o " + file4 + " -c config.json" + " -l " + id + " -r callee"
        ss.write(run)
        ss.close()
        os.system('chmod 755 start*sh')
else:
        print("comminication error with {}".format(url))

sys.exit(0)
