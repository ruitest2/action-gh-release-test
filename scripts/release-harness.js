async function getReleaseByTagOrNull({ github, owner, repo, tag }) {
  try {
    const { data } = await github.rest.repos.getReleaseByTag({
      owner,
      repo,
      tag,
    });
    return data;
  } catch (error) {
    if (error.status === 404) {
      return null;
    }
    throw error;
  }
}

async function deleteTagIfExists({ github, owner, repo, tag }) {
  try {
    await github.request("DELETE /repos/{owner}/{repo}/git/refs/{ref}", {
      owner,
      repo,
      ref: `tags/${tag}`,
    });
  } catch (error) {
    if (
      error.status !== 404 &&
      !(error.status === 422 && /Reference does not exist/i.test(error.message))
    ) {
      throw error;
    }
  }
}

function writeJsonSummary(core, heading, summary) {
  return core.summary
    .addHeading(heading)
    .addCodeBlock(JSON.stringify(summary, null, 2), "json")
    .write();
}

module.exports = {
  deleteTagIfExists,
  getReleaseByTagOrNull,
  writeJsonSummary,
};
