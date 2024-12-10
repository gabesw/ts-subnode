# Tailscale Subnodes
Do you have Pi-hole running on Tailscale? Do you want to use your Pi-hole as an exit node? Then this project is for you! When you run Tailscale on a Pi-hole, you have to set `--accept-dns=false` on Tailscale so the server doesnt use itself as a DNS resolver. This is critical, as if the Pi-hole looses connectivity, you will not be able to SSH into the machine as it will loose all internet access. The downside of this is that using the same machine as an exit node means all of the traffic will bypass the Pi-hole and any restrictions that may be imposed. This can all be avoided with <b>Subnodes</b>!

A Subnode is an [ephemeral Tailscale node](https://tailscale.com/kb/1111/ephemeral-nodes) running in a Docker container in another machine using Tailscale. Using a subnode, you can use the host's DNS server without risking the loss of connectivity to the host. I encountered two problems while setting up subnodes. The first is that setting the accept DNS tag on the Docker instance of tailscale does not properly set the DNS servers. Even when entering the container and running the `tailscale set` command, `tailscale dns status` reports that tailscale DNS is enabled, but the `resolv.conf` of the container is never modified, still bypassing the host's DNS. The second problem that I encountered is that 100.100.100.100, the nameserver set automatically by Tailscale when DNS is enabled, does not resolve on the docker container. I finally found that manually setting the tailscale IPs of my dns servers each as individual nameservers in `resolv.conf` properly routed traffic through my DNS servers!

The `configure_subnode_dns.sh` file automatically grabs the Tailscale IPs of my DNS servers using the tag I have set for my Pi-hole nodes. It then creates a `resolv.conf` file in the `./config` folder. The docker compose then links this as a volume in the container, so the DNS servers are set on startup. You can run this script before starting the container for the first time, or create a cron job to run the script on a schedule (preferable) which keeps the DNS servers up to date without manual intervention.

## Setup
### Tailscale
Follow [this guide](https://tailscale.com/kb/1085/auth-keys) to create an <i>ephemeral</i> auth key. Replace `<YOUR AUTHKEY HERE>` with the generated key in `docker-compose.yaml`. 
### Getting Started
The script is configured by default to look for devices tagged as "tag:dns". If you are using a different tag for your DNS servers in Tailscale, change the `DNS_TAG` variable in `configure_subnode_dns.sh` to the tag that you are using.

Before starting the subnode for the first time, you must run `./configure_subnode_dns.sh` to create the `resolv.conf` for the subnode. Then just start the container with `docker compose up -d`.
