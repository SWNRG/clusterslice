#!/bin/bash

# Define the output JSON file path
OUTPUT_JSON="/tmp/vxlan.json"

# Create the JSON file if it doesn't exist
if [ ! -f "$OUTPUT_JSON" ]; then
    mkdir -p $(dirname "$OUTPUT_JSON")
    echo '{"Nodes":[],"Link":[]}' > "$OUTPUT_JSON"
fi

# Get the pod information from the specific namespace
NAMESPACE="he-codeco-netma"
POD_INFO=$(kubectl get pods -o wide -n $NAMESPACE)

# Extract node and IP information of switches
NODES=($(echo "$POD_INFO" | awk '/l2sm-switch/ {print $7}'))
IPS=($(echo "$POD_INFO" | awk '/l2sm-switch/ {print $6}'))
PODS=($(echo "$POD_INFO" | awk '/l2sm-switch/ {print $1}'))

# Check if we have at least two switches to connect
if [ ${#NODES[@]} -lt 2 ]; then
    echo "Not enough switches found. At least two switches are required."
    exit 1
fi

# Create nodes array and links array for the JSON content
NODES_JSON=$(jq -n --argjson nodes "[]" '$nodes')
LINKS_JSON=$(jq -n --argjson links "[]" '$links')

# Add nodes to the nodes array
for i in "${!NODES[@]}"; do
    NODE_JSON=$(jq -n \
        --arg name "${NODES[$i]}" \
        --arg ip "${IPS[$i]}" \
        '{name: $name, nodeIP: $ip}')
    NODES_JSON=$(echo "$NODES_JSON" | jq --argjson node "$NODE_JSON" '. += [$node]')
done

# Create full mesh links between all switches
for i in "${!NODES[@]}"; do
    for j in $(seq $((i + 1)) ${#NODES[@]}); do
        [ $j -ge ${#NODES[@]} ] && break
        LINK_JSON=$(jq -n \
            --arg endpointA "${NODES[$i]}" \
            --arg endpointB "${NODES[$j]}" \
            '{endpointA: $endpointA, endpointB: $endpointB}')
        LINKS_JSON=$(echo "$LINKS_JSON" | jq --argjson link "$LINK_JSON" '. += [$link]')
    done
done

# Combine nodes and links into the final JSON structure
FINAL_JSON=$(jq -n \
    --argjson nodes "$NODES_JSON" \
    --argjson links "$LINKS_JSON" \
    '{Nodes: $nodes, Link: $links}')

# Write the JSON content to the file
echo "$FINAL_JSON" > "$OUTPUT_JSON"

# Output success message
echo "Configuration file created/updated successfully at $OUTPUT_JSON"

# Executing vxlan creation script in switch pods
for i in "${!PODS[@]}"; do
   echo "Copying vxlan.json to POD ${PODS[$i]}"
   kubectl -n $NAMESPACE cp $OUTPUT_JSON ${PODS[$i]}:/etc/l2sm/switchConfig.json
   kubectl -n $NAMESPACE exec -it ${PODS[$i]} -- /bin/bash -c 'l2sm-vxlans --node_name=$NODENAME /etc/l2sm/switchConfig.json'
done

