#!/bin/bash

{
jq 'select(.objectRef.resource=="secrets" and (.verb=="get" or .verb=="list"))' audit.log 2>/dev/null
jq 'select(.verb=="create" and .objectRef.subresource=="exec")' audit.log 2>/dev/null
jq 'select(.objectRef.resource=="pods" and .verb=="create" and .requestObject.spec.containers[]?.securityContext.privileged==true)' audit.log 2>/dev/null
jq 'select((.objectRef.resource=="rolebindings" or .objectRef.resource=="clusterrolebindings") and .verb=="create" and .requestObject.roleRef.name=="cluster-admin")' audit.log 2>/dev/null
} | jq -s '.' > audit-extract.json
