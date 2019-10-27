#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat 19 Oct 2019 02:34:47 AM EDT

@author: a.leb
"""
### версия использовавшаяся в тестах netem

import requests
import json

auth_token="127859963:525cec3227216c14addebfc4241793c6ef4e"
url="https://api.contest.com/voip" + auth_token + "/getConnection?call={call}"
querystring=""
r=requests.get(url, params=querystring)
acc = r.json()
print(json.dumps(acc, indent=2)) 

if acc['ok'] == True:
        cfg = acc["result"]["config"]
        encryption_key = acc["result"]["encryption_key"]
        id = acc["result"]["endpoints"][0]["id"]
        ipv4 = acc["result"]["endpoints"][0]["ip"]
        port = acc["result"]["endpoints"][0]["port"]
        peer_tags_caller = acc["result"]["endpoints"][0]["peer_tags"]["caller"]
        peer_tags_callee = acc["result"]["endpoints"][0]["peer_tags"]["callee"]

        print("----")
        print(cfg)
        print("----")
        print(encryption_key)
        print("----")
        print(id)
        print("----")
        print(ipv4)
        print("----")
        print(port)
        print("----")
        print(peer_tags_caller)
        print("----")
        print(peer_tags_callee)
        print("----")
        hs = open("config.json", 'w')
        hs.write(json.dumps(cfg))
        hs.close()


        #./tgvoipcall 127.0.0.1:555 ssssssssss -k encryption_key_hex -i /path/to/sound_A.ogg -o /path/to/sound_output_B.ogg -c config.json
        ss = open("start_A.sh","w")
        run = "../cpp/tgvoipcall " + ipv4 + ":" + port + " " + peer_tags_caller + " -k " + encryption_key + " -i ../python/sample17.ogg -o ../python/sound_output_B.raw -c ../python/config.json" + " -l " + id + " -r caller"
        ss.write(run)
        ss.close() 
        ss = open("start_B.sh","w")
        run = "../cpp/tgvoipcall " + ipv4 + ":" + port + " " + peer_tags_callee + " -k " + encryption_key + " -i ../python/sample17.ogg  -o ../python/sound_output_A.raw -c ../python/config.json" + " -l " + id + " -r callee"
        ss.write(run)
        ss.close()
