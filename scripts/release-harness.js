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

function writeJsonSummary(core, heading, summary) {
  return core.summary
    .addHeading(heading)
    .addCodeBlock(JSON.stringify(summary, null, 2), "json")
    .write();
}

module.exports = {
  getReleaseByTagOrNull,
  writeJsonSummary,
};
