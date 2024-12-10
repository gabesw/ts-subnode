#!/bin/bash

# Set the location of the resolv.conf for the subnode
SUBNODE_RESOLV="./config/resolv.conf"
TEMP_RESOLV="${SUBNODE_RESOLV}.tmp"

# Get the Tailscale status in JSON format
TAILSCALE_STATUS=$(tailscale status --json)

# The Tailscale tag for DNS servers
DNS_TAG="tag:dns"

# Parse the Tailscale nodes for devices tagged as DNS servers and return their IPs as nameservers
TAILSCALE_DNS_SERVERS=$(echo "$TAILSCALE_STATUS" | jq -r --arg DNS_TAG "$DNS_TAG" '
  (.Peer[] | select(.Tags[]? | contains($DNS_TAG)) | "nameserver \(.TailscaleIPs[])"),
  (.Self | select(.Tags[]? | contains($DNS_TAG)) | "nameserver \(.TailscaleIPs[])")
')

# Get the MagicDNS Suffix to use as the search domain
TAILSCALE_SUFFIX=$(echo "$TAILSCALE_STATUS" | jq -r '
  ("search \(.MagicDNSSuffix)")
')

# Save the nameservers
echo "$TAILSCALE_DNS_SERVERS" > "$TEMP_RESOLV"
# Save the search domain
echo "$TAILSCALE_SUFFIX" >> "$TEMP_RESOLV"
# Add options
echo "options ndots:0" >> "$TEMP_RESOLV"

# Now overwrite the resolv file (ensure atomicity)
mv "$TEMP_RESOLV" "$SUBNODE_RESOLV"

echo "$(date): Updated resolv.conf for subnode"
