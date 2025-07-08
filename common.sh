function fetch_json {
  JSON=$(curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/runs/$RUN_ID/artifacts")
}

function get_artifact_id {
  while read entry; do
    if [[ $(echo "${entry}" | jq ".name" | sed 's/"//g') == "$1" ]]; then
      echo "${entry}" | jq ".id"
    fi
  done <<< $(echo "${JSON}" | jq -c '.artifacts.[]')
}

function fetch_artifact {
  curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/artifacts/$1/zip" > "$2"
}

function recheck_connections {
  CONNECTIONS="$(sudo wg show | grep 'latest handshake' | wc -l | tr -d ' ')" || true
}
