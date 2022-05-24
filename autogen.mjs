#!/usr/bin/env node

import child_process from "child_process";
import fs from "fs";
import util from "util";

async function getJSON(url) {
  const r = await fetch(url);
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
  let r = await util.promisify(child_process.execFile)("nix", [
    "run",
    ".#pkgs.nix-prefetch",
    "--",
    "fetchzip",
    "--url",
    url,
    "--type",
    "sha512",
  ]);
  const hash = r.stdout.trimEnd();
  return `
{ fetchzip }:
fetchzip {
  url =
    "${url}";
  hash =
    "${hash}";
}
`;
}

async function getGitHubRunId(owner, repo, branch, workflow_name) {
  const r = await getJSON(
    `https://api.github.com/repos/${owner}/${repo}/actions/runs?branch=${branch}&status=success&per_page=100`
  );
  return r.workflow_runs.find((e) => e.name === workflow_name).id;
}

async function getGitHubArtifactId(owner, repo, run_id, artifact_name) {
  let r = await getJSON(
    `https://api.github.com/repos/${owner}/${repo}/actions/runs/${run_id}/artifacts`
  );
  r = r.artifacts.find((e) => e.name === artifact_name);
  return r.id;
}

async function getGitHubArtifact(owner, repo, artifact_id) {
  const url = `https://nightly.link/${owner}/${repo}/actions/artifacts/${artifact_id}.zip`;
  const r = await util.promisify(child_process.execFile)("nix", [
    "run",
    ".#pkgs.nix-prefetch",
    "--",
    "fetchzip",
    "--url",
    url,
    "--no-stripRoot",
    "--type",
    "sha512",
  ]);
  const hash = r.stdout.trimEnd();
  return `
{ fetchzip }:
fetchzip {
  url =
    "https://nightly.link/${owner}/${repo}/actions/artifacts/${artifact_id}.zip";
  hash =
    "${hash}";
  stripRoot = false;
}
`;
}

async function doGHC() {
  const pipeline_id = await getGitLabPipelineId();
  const job_id = await getGitLabJobId(pipeline_id, "wasm32-wasi-bindist");
  const s = await getGitLabArtifact(job_id, "ghc-wasm32-wasi.tar.xz");
  return await fs.promises.writeFile("autogen/ghc-wasm32-wasi.nix", s);
}

async function doWasiSdk() {
  const run_id = await getGitHubRunId("WebAssembly", "wasi-sdk", "main", "CI");
  const artifact_id = await getGitHubArtifactId(
    "WebAssembly",
    "wasi-sdk",
    run_id,
    "dist-ubuntu-latest"
  );
  const s = await getGitHubArtifact("WebAssembly", "wasi-sdk", artifact_id);
  return await fs.promises.writeFile("autogen/wasi-sdk.nix", s);
}

async function doLibFFIWasm32() {
  const run_id = await getGitHubRunId(
    "tweag",
    "libffi-wasm32",
    "master",
    "shell"
  );
  const artifact_id = await getGitHubArtifactId(
    "tweag",
    "libffi-wasm32",
    run_id,
    "out"
  );
  const s = await getGitHubArtifact("tweag", "libffi-wasm32", artifact_id);
  return await fs.promises.writeFile("autogen/libffi-wasm32.nix", s);
}

async function doWasmtime() {
  const run_id = await getGitHubRunId(
    "bytecodealliance",
    "wasmtime",
    "main",
    "CI"
  );
  const artifact_id = await getGitHubArtifactId(
    "bytecodealliance",
    "wasmtime",
    run_id,
    "bins-x86_64-linux"
  );
  const s = await getGitHubArtifact(
    "bytecodealliance",
    "wasmtime",
    artifact_id
  );
  return await fs.promises.writeFile("autogen/wasmtime.nix", s);
}

async function doCabal() {
  const run_id = await getGitHubRunId("haskell", "cabal", "master", "Validate");
  const artifact_id = await getGitHubArtifactId(
    "haskell",
    "cabal",
    run_id,
    "cabal-Linux-8.10.7"
  );
  const s = await getGitHubArtifact("haskell", "cabal", artifact_id);
  return await fs.promises.writeFile("autogen/cabal.nix", s);
}

Promise.all([doGHC(), doWasiSdk(), doLibFFIWasm32(), doWasmtime(), doCabal()]);
