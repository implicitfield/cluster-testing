# Cluster Testing

This is a sandbox for experimenting with creating a cluster/network of runners to accelerate time-consuming builds. The architecture looks roughly like this:

primary runner:
0. clean up the runner / install dependencies
1. publish encrypted external IP/port + keep NAT mapping active
2. wait for all auxiliary runners to publish IP/port combinations
3. decrypt auxiliary metadata + generate wireguard config
4. for each auxiliary runner:
 - start sending packets toward the auxiliary runner
 - wait until a new wireguard connection is detected
5. run project specific build steps.

auxiliary runners:
0. choose a local port / install dependencies
1. generate wireguard config + start distccd + publish encrypted external IP/port + keep NAT mapping active
2. if this is #0:
 - wait for step #1 to succeed on the primary runner
else:
 - wait for step #3 to succeed on the previous auxiliary runner
3. decrypt primary metadata + start sending packets toward it + connect via wireguard
4. print logs until a specific artifact has been published

Some notes:
Sometimes the first auxiliary runner fails to connect to the primary one. Retrying has never fixed this, only waiting and then running an entirely new workflow has.
This could be due to varying network topography maybe (the packets only have a TTL of 4), but that doesn't explain everything either.
It's always the first auxiliary runner that fails (if it does). I've never seen any of the other auxiliary runners fail to connect in case the first one connected fine.
I've also seen a random auxiliary runner stop responding to distcc a few times. Could be due to the NAT changing the mapping even though it's in use (there's a keepalive ping that wireguard uses), but I've no evidence that that's what actually happens. This is not a complete disconnect because the runner still detects the eventual release.
The auxiliary runners could technically connect in parallel, but that's not currently being done because the connection process is somewhat unstable anyway.
IPs, ports, and public keys are encrypted to add some security through obscurity. Publishing these in plaintext should be fine, but there's also no need to do that either. Private keys never leave the runner on which they were generated, and should never appear in the logs.
You'll need to set up a new secret called ENCRYPTION_KEY if you fork this. The limit for the length of that seems to be 48 KB.

References:
https://github.com/ValdikSS/nat-traversal-github-actions-openvpn-wireguard
https://gist.github.com/chrisswanda/88ade75fc463dcf964c6411d1e9b20f4
