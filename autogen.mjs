#!/usr/bin/env node

import child_process from "child_process";
import fs from "fs";
import util from "util";

async function getJSON(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(r);
  return r.json();
}

async function getGitLabPipelineId() {
  let r = await getJSON(
    "https://gitlab.haskell.org/api/v4/projects/1/merge_requests/7632/pipelines"
  );
  r = r.find((e) => e.status === "success");
  return r.id;
}

async function getGitLabJobId(pipeline_id, job_name) {
  let r = await getJSON(
    `https://gitlab.haskell.org/api/v4/projects/1/pipelines/${pipeline_id}/jobs`
  );
  r = r.find((e) => e.name === job_name);
  return r.id;
}

async function getGitLabArtifact(job_id, artifact_path) {
  const url = `https://gitlab.haskell.org/api/v4/projects/1/jobs/${job_id}/artifacts/${artifact_path}`;
  let r = await util.promisify(child_process.execFile)("nix-prefetch", [
    "fetchzip",
    "--url",
    url,
    "--type",
    "sha512",
  ]);
  const hash = r.stdout.trim();
  const nix = `
{ fetchzip }:
fetchzip {
  url =
    "${url}";
  hash =
    "${hash}";
}
`;
  const sh = `
#!/bin/sh

exec curl -f -L --retry 5 ${url}
`;
  return { nix, sh };
}

async function getGitHubRunId(owner, repo, branch, workflow_name) {
  const r = await getJSON(
    `https://api.github.com/repos/${owner}/${repo}/actions/runs?branch=${branch}&event=push&status=success&per_page=100`
  );
  return r.workflow_runs.find((e) => e.name && e.name === workflow_name).id;
}

async function getGitHubArtifactId(owner, repo, run_id, artifact_name) {
  try {
    let r = await getJSON(
      `https://api.github.com/repos/${owner}/${repo}/actions/runs/${run_id}/artifacts`
    );
    r = r.artifacts.find((e) => e.name === artifact_name);
    return r.id;
  } catch (err) {
    throw new Error(`getGitHubArtifactId ${owner}/${repo} failed with ${err}`);
  }
}

async function getGitHubArtifact(owner, repo, artifact_id) {
  const url = `https://nightly.link/${owner}/${repo}/actions/artifacts/${artifact_id}.zip`;
  const r = await util.promisify(child_process.execFile)("nix-prefetch", [
    "fetchzip",
    "--url",
    url,
    "--no-stripRoot",
    "--type",
    "sha512",
  ]);
  const hash = r.stdout.trim();
  const nix = `
{ fetchzip }:
fetchzip {
  url =
    "https://nightly.link/${owner}/${repo}/actions/artifacts/${artifact_id}.zip";
  hash =
    "${hash}";
  stripRoot = false;
}
`;
  const sh = `
#!/bin/sh

exec curl -f -L --retry 5 ${url}
`;
  return { nix, sh };
}

async function doGHC(bignum_backend) {
  const pipeline_id = await getGitLabPipelineId();
  const job_id = await getGitLabJobId(
    pipeline_id,
    `wasm32-wasi-bindist: [${bignum_backend}]`
  );
  const r = await getGitLabArtifact(
    job_id,
    `ghc-wasm32-wasi-${bignum_backend}.tar.xz`
  );
  return await Promise.all([
    fs.promises.writeFile(
      `autogen/ghc-wasm32-wasi-${bignum_backend}.nix`,
      r.nix
    ),
    fs.promises.writeFile(
      `autogen/ghc-wasm32-wasi-${bignum_backend}.sh`,
      r.sh,
      { mode: 0o755 }
    ),
  ]);
}

async function doGitHub(owner, repo, branch, workflow_name, artifact_name) {
  const run_id = await getGitHubRunId(owner, repo, branch, workflow_name);
  const artifact_id = await getGitHubArtifactId(
    owner,
    repo,
    run_id,
    artifact_name
  );
  const r = await getGitHubArtifact(owner, repo, artifact_id);
  return await Promise.all([
    fs.promises.writeFile(`autogen/${repo}.nix`, r.nix),
    fs.promises.writeFile(`autogen/${repo}.sh`, r.sh, { mode: 0o755 }),
  ]);
}

doGHC("gmp");
doGHC("native");
doGitHub("WebAssembly", "wasi-sdk", "main", "CI", "dist-ubuntu-latest");
doGitHub("tweag", "libffi-wasm32", "master", "shell", "out");
doGitHub("bytecodealliance", "wasmtime", "main", "CI", "bins-x86_64-linux");
doGitHub("haskell", "cabal", "master", "Validate", "cabal-Linux-9.2.3");
doGitHub("WebAssembly", "binaryen", "main", "CI", "build-ubuntu-latest");
