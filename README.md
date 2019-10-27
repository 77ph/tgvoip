# tgvoip
tgvoip project

VoIP Contest: Round 1
General info about the contest is available on @contest. 

The task in this round of the VoIP Contest is to build a system for testing voice calls with two participants.

Contest Overview
A is a user making a voice call (caller).
B is a user receiving a voice call from A (callee).
The VoIP Relay is an intermediary server, which takes data from each of the participants and relays it to the other party. The relay has an IP-address, a port, and 2 “tags” per call – to distinguish between different calls and different participant roles in each of the calls (caller/callee).
All data exchanged by A and B is encrypted. For the call to work, both parties must use the same encryption key.
Depending on the network conditions (Edge, 3G, LTE, Wi-Fi) data packets may be lost or reordered and the sound may get distorted.
Your goal is to automate the process of testing sound transmission under various conditions.
[ Caller A ] <-> [ VoIP Relay ] <-> [ Callee B ]


