#!/bin/bash

# Uses the Dashboard API to export API and Policy definitions, overwriting data used to bootstrap the base Tyk deployment

dashboard_base_url="http://tyk-dashboard.localhost:3000"

declare -a data_groups=("1" "2")
declare -a organisation_names=("$(cat .context-data/1-organisation-1-name)" "$(cat .context-data/2-organisation-1-name)")
declare -a dashboard_keys=("$(cat .context-data/1-dashboard-user-1-api-key)" "$(cat .context-data/2-dashboard-user-1-api-key)")

index=0
for data_group in "${data_groups[@]}"; do\
  echo "Exporting APIs for organisation: ${organisation_names[$index]}"
  apis=$(curl $dashboard_base_url/api/apis?p=-1 -s \
    -H "Authorization:${dashboard_keys[$index]}" \
    | jq -c '.apis[]')
  while read -r api; do
    if [[ "$api" != "" ]]; then
      api_is_oas=$(jq -r '.api_definition.is_oas' <<< $api) 
      api_name=$(jq -r '.api_definition.name' <<< $api)
      api_id=$(jq -r '.api_definition.id' <<< $api)
      api_file_name="api-$api_id.json"
      echo "  $api_name"
      # if API is OAS spec, then retrieve the OAS document and use a different file name
      if [[ "$api_is_oas" == "true" ]]; then
        api=$(curl $dashboard_base_url/api/apis/oas/$api_id -s \
          -H "Authorization:${dashboard_keys[$index]}")
        api_file_name="api-oas-$api_id.json"
      fi
      echo "$api" | jq '.' > "deployments/tyk/data/tyk-dashboard/${data_groups[$index]}/apis/$api_file_name"
    fi 
  done <<< "$apis"

  echo "Exporting Policies for organisation: ${organisation_names[$index]}"
  policies=$(curl $dashboard_base_url/api/portal/policies?p=-1 -s \
    -H "Authorization:${dashboard_keys[$index]}" \
    | jq -c '.Data | reverse | .[]')
  while read -r policy; do
    if [[ "$policy" != "" ]]; then
      policy_id=$(jq -r '._id' <<< $policy)
      echo "  $(jq -r '.name' <<< $policy)"
      echo "$policy" | jq '.' > "deployments/tyk/data/tyk-dashboard/${data_groups[$index]}/policies/policy-$policy_id.json"
    fi
  done <<< "$policies"
  
  index=$((index+1))
done