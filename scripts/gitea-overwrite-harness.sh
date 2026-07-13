#!/usr/bin/env bash
set -euo pipefail

gitea_url="http://127.0.0.1:3000"
api_url="${gitea_url}/api/v1"
container="action-gh-release-gitea-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
temp_directory="$(mktemp -d)"
test_user="release-harness"
test_password="Issue803-Harness-${GITHUB_RUN_ID}!"
test_repository="release-overwrite"
tag_name="issue803-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
asset_name="release-asset.txt"
action_bundle="${ACTION_BUNDLE:-${GITHUB_WORKSPACE}/action-under-test/dist/index.js}"

cleanup() {
  local exit_code=$?
  trap - EXIT

  if [[ "$exit_code" -ne 0 || "${KEEP_CONTAINER_LOGS}" == "true" ]]; then
    echo "Gitea container logs:"
    docker logs "$container" 2>&1 || true
  fi

  docker rm --force --volumes "$container" >/dev/null 2>&1 || true
  rm -rf "$temp_directory"
  echo "Removed ephemeral Gitea container, anonymous volumes, and temporary credentials."
  exit "$exit_code"
}
trap cleanup EXIT

api() {
  local method=$1
  local path=$2
  shift 2
  curl --fail --silent --show-error \
    --request "$method" \
    --header "Authorization: token ${gitea_token}" \
    --header "Content-Type: application/json" \
    "$@" \
    "${api_url}${path}"
}

wait_for_gitea() {
  for _ in $(seq 1 90); do
    if curl --fail --silent "${api_url}/version" >/dev/null 2>&1; then
      return
    fi
    sleep 2
  done

  echo "Gitea did not become ready" >&2
  return 1
}

run_action() {
  local output_file=$1
  local log_file=$2

  : >"$output_file"
  (
    cd "$repository_directory"
    env \
      CI=true \
      GITHUB_API_URL="$api_url" \
      GITHUB_EVENT_NAME=workflow_dispatch \
      GITHUB_EVENT_PATH="${temp_directory}/event.json" \
      GITHUB_OUTPUT="$output_file" \
      GITHUB_REF="refs/tags/${tag_name}" \
      GITHUB_REPOSITORY="${test_user}/${test_repository}" \
      GITHUB_SERVER_URL="$gitea_url" \
      GITHUB_SHA="$commit_sha" \
      GITHUB_WORKSPACE="$repository_directory" \
      INPUT_FAIL_ON_UNMATCHED_FILES=true \
      INPUT_FILES="$asset_name" \
      INPUT_NAME="Issue 803 overwrite" \
      INPUT_OVERWRITE_FILES=true \
      INPUT_REPOSITORY="${test_user}/${test_repository}" \
      INPUT_TAG_NAME="$tag_name" \
      INPUT_TARGET_COMMITISH="$commit_sha" \
      INPUT_TOKEN="$gitea_token" \
      node "$action_bundle"
  ) >"$log_file" 2>&1
}

wait_for_repository() {
  local repository

  for _ in $(seq 1 30); do
    repository="$(api GET "/repos/${test_user}/${test_repository}")"
    if jq -e '.empty == false' <<<"$repository" >/dev/null; then
      return
    fi
    sleep 1
  done

  echo "Gitea still reports the pushed repository as empty" >&2
  return 1
}

release_snapshot() {
  local destination=$1
  local releases release_id

  releases="$(api GET "/repos/${test_user}/${test_repository}/releases?limit=100")"
  release_id="$(jq --arg tag "$tag_name" -r \
    '[.[] | select(.tag_name == $tag)] | if length == 1 then .[0].id else empty end' \
    <<<"$releases")"
  if [[ -z "$release_id" ]]; then
    echo "Expected exactly one release for ${tag_name}" >&2
    jq --arg tag "$tag_name" '[.[] | select(.tag_name == $tag)]' <<<"$releases" >&2
    return 1
  fi

  api GET "/repos/${test_user}/${test_repository}/releases/${release_id}/assets" \
    | jq --argjson release_id "$release_id" '{release_id: $release_id, assets: .}' \
    >"$destination"
}

download_asset() {
  local snapshot=$1
  local destination=$2
  local download_url

  download_url="$(jq -r --arg name "$asset_name" \
    '.assets[] | select(.name == $name) | .browser_download_url' "$snapshot")"
  if [[ -z "$download_url" ]]; then
    echo "Missing ${asset_name} in release snapshot" >&2
    return 1
  fi
  curl --fail --location --silent --show-error "$download_url" --output "$destination"
}

docker run --detach \
  --name "$container" \
  --publish 127.0.0.1:3000:3000 \
  --env GITEA__actions__ENABLED=false \
  --env GITEA__database__DB_TYPE=sqlite3 \
  --env GITEA__security__INSTALL_LOCK=true \
  --env GITEA__server__OFFLINE_MODE=true \
  --env GITEA__server__ROOT_URL="${gitea_url}/" \
  --env GITEA__service__DISABLE_REGISTRATION=true \
  "docker.gitea.com/gitea:${GITEA_VERSION}" >/dev/null

wait_for_gitea

docker exec --user git "$container" gitea admin user create \
  --username "$test_user" \
  --password "$test_password" \
  --email "release-harness@example.invalid" \
  --admin \
  --must-change-password=false >/dev/null

gitea_token="$(docker exec --user git "$container" gitea admin user generate-access-token \
  --username "$test_user" \
  --token-name issue-803-harness \
  --scopes all \
  --raw)"
if [[ -z "$gitea_token" ]]; then
  echo "Gitea did not return an access token" >&2
  exit 1
fi
echo "::add-mask::${gitea_token}"

api POST /user/repos \
  --data "{\"name\":\"${test_repository}\",\"private\":false}" >/dev/null

repository_directory="${temp_directory}/repository"
git -c init.defaultBranch=main init "$repository_directory" >/dev/null
git -C "$repository_directory" config user.name "Release Harness"
git -C "$repository_directory" config user.email "release-harness@example.invalid"
printf '# Issue 803 Gitea overwrite harness\n' >"${repository_directory}/README.md"
git -C "$repository_directory" add README.md
git -C "$repository_directory" commit -m "test: seed Gitea repository" >/dev/null
commit_sha="$(git -C "$repository_directory" rev-parse HEAD)"
git -C "$repository_directory" remote add origin \
  "http://${test_user}:${gitea_token}@127.0.0.1:3000/${test_user}/${test_repository}.git"
git -C "$repository_directory" push --set-upstream origin main >/dev/null 2>&1
wait_for_repository
printf '{}\n' >"${temp_directory}/event.json"

original_content="original content ${GITHUB_RUN_ID}"
replacement_content="replacement content ${GITHUB_RUN_ID}"
printf '%s\n' "$original_content" >"${repository_directory}/${asset_name}"

if ! run_action "${temp_directory}/first-output" "${temp_directory}/first.log"; then
  echo "First action execution failed:" >&2
  sed -n '1,240p' "${temp_directory}/first.log" >&2
  exit 1
fi
sed -n '1,240p' "${temp_directory}/first.log"

release_snapshot "${temp_directory}/first-release.json"
first_release_id="$(jq -r '.release_id' "${temp_directory}/first-release.json")"
first_asset_count="$(jq --arg name "$asset_name" '[.assets[] | select(.name == $name)] | length' \
  "${temp_directory}/first-release.json")"
first_asset_id="$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .id' \
  "${temp_directory}/first-release.json")"
if [[ "$first_asset_count" -ne 1 ]]; then
  echo "Expected one asset after the first execution, got ${first_asset_count}" >&2
  exit 1
fi
download_asset "${temp_directory}/first-release.json" "${temp_directory}/first-download"
printf '%s\n' "$original_content" >"${temp_directory}/expected-original"
cmp "${temp_directory}/expected-original" "${temp_directory}/first-download"

printf '%s\n' "$replacement_content" >"${repository_directory}/${asset_name}"
set +e
run_action "${temp_directory}/second-output" "${temp_directory}/second.log"
second_exit_code=$?
set -e
sed -n '1,260p' "${temp_directory}/second.log"

if [[ "$EXPECTED_SECOND_RUN" == "success" && "$second_exit_code" -ne 0 ]]; then
  echo "Expected the second action execution to succeed" >&2
  exit 1
fi
if [[ "$EXPECTED_SECOND_RUN" == "failure" && "$second_exit_code" -eq 0 ]]; then
  echo "Expected the second action execution to fail" >&2
  exit 1
fi
if [[ "$EXPECTED_SECOND_RUN" == "failure" ]] && \
  ! grep -q '404 page not found' "${temp_directory}/second.log"; then
  echo "Expected the pre-fix deletion failure to contain '404 page not found'" >&2
  exit 1
fi

release_snapshot "${temp_directory}/second-release.json"
second_release_id="$(jq -r '.release_id' "${temp_directory}/second-release.json")"
second_asset_count="$(jq --arg name "$asset_name" '[.assets[] | select(.name == $name)] | length' \
  "${temp_directory}/second-release.json")"
second_asset_id="$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .id' \
  "${temp_directory}/second-release.json")"

if [[ "$second_release_id" != "$first_release_id" ]]; then
  echo "Release ID changed from ${first_release_id} to ${second_release_id}" >&2
  exit 1
fi
if [[ "$second_asset_count" -ne 1 ]]; then
  echo "Expected one asset after the second execution, got ${second_asset_count}" >&2
  exit 1
fi

download_asset "${temp_directory}/second-release.json" "${temp_directory}/second-download"
if [[ "$EXPECTED_SECOND_RUN" == "success" ]]; then
  printf '%s\n' "$replacement_content" >"${temp_directory}/expected-final"
else
  printf '%s\n' "$original_content" >"${temp_directory}/expected-final"
fi
cmp "${temp_directory}/expected-final" "${temp_directory}/second-download"

summary="$(jq -n \
  --arg action_repository "$ACTION_REPOSITORY" \
  --arg action_ref "$ACTION_REF" \
  --arg gitea_version "$GITEA_VERSION" \
  --arg expected_second_run "$EXPECTED_SECOND_RUN" \
  --arg tag_name "$tag_name" \
  --argjson first_release_id "$first_release_id" \
  --argjson second_release_id "$second_release_id" \
  --argjson first_asset_id "$first_asset_id" \
  --argjson second_asset_id "$second_asset_id" \
  --argjson final_asset_count "$second_asset_count" \
  --arg first_digest "$(sha256sum "${temp_directory}/first-download" | cut -d ' ' -f 1)" \
  --arg final_digest "$(sha256sum "${temp_directory}/second-download" | cut -d ' ' -f 1)" \
  '{
    action_repository: $action_repository,
    action_ref: $action_ref,
    gitea_version: $gitea_version,
    expected_second_run: $expected_second_run,
    tag_name: $tag_name,
    first_release_id: $first_release_id,
    second_release_id: $second_release_id,
    first_asset_id: $first_asset_id,
    second_asset_id: $second_asset_id,
    final_asset_count: $final_asset_count,
    first_digest: $first_digest,
    final_digest: $final_digest,
    container_cleanup: "scheduled by EXIT trap"
  }')"

printf '%s\n\n%s\n%s\n%s\n' \
  '### Gitea release asset overwrite' \
  '```json' \
  "$summary" \
  '```' >>"$GITHUB_STEP_SUMMARY"
printf '%s\n' "$summary"
