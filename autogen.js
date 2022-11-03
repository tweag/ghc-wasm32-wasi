#!/usr/bin/env -S deno run --allow-net --allow-read --allow-run --allow-write

async function fetchJSON(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(await r.text());
  return r.json();
}

async function fetchGitLabArtifactURL(
  gitlab_domain,
  project_id,
  ref,
  job_name,
  artifact_path
) {
  const pipeline_id = (
    await fetchJSON(
      `https://${gitlab_domain}/api/v4/projects/${project_id}/pipelines?status=success&source=push&ref=${ref}`
    )
  )[0].id;
  const job_id = (
    await fetchJSON(
      `https://${gitlab_domain}/api/v4/projects/${project_id}/pipelines/${pipeline_id}/jobs`
    )
  ).find((e) => e.name === job_name).id;
  return `https://${gitlab_domain}/api/v4/projects/${project_id}/jobs/${job_id}/artifacts/${artifact_path}`;
}

async function fetchGitHubArtifactURL(
  owner,
  repo,
  branch,
  workflow_name,
  artifact_name
) {
  const run_id = (
    await fetchJSON(
      `https://api.github.com/repos/${owner}/${repo}/actions/runs?branch=${branch}&event=push`
    )
  ).workflow_runs.find((e) => e.name && e.name === workflow_name).id;
  const artifact_id = (
    await fetchJSON(
      `https://api.github.com/repos/${owner}/${repo}/actions/runs/${run_id}/artifacts`
    )
  ).artifacts.find((e) => e.name === artifact_name).id;
  return `https://nightly.link/${owner}/${repo}/actions/artifacts/${artifact_id}.zip`;
}

async function fetchGitHubLatestReleaseURL(owner, repo, suffix) {
  return (
    await fetchJSON(
      `https://api.github.com/repos/${owner}/${repo}/releases/latest`
    )
  ).assets.find((e) => e.name.endsWith(suffix)).browser_download_url;
}

function parseActualHash(msg) {
  return Array.from(msg.matchAll(/sha256:[0-9a-z]+/g))
    .at(-1)[0]
    .split("sha256:")[1];
}

async function fetchHash(fetcher, fetcher_opts) {
  const proc = Deno.run({
    cmd: [
      "nix",
      "eval",
      "--expr",
      `${fetcher}(builtins.fromJSON(${JSON.stringify(
        JSON.stringify(fetcher_opts)
      )}))`,
    ],
    stdin: "null",
    stdout: "null",
    stderr: "piped",
  });
  const msg = new TextDecoder().decode(await proc.stderrOutput());
  const hash = parseActualHash(msg);
  return hash;
}

async function fetchGitLabArtifact(
  fetcher,
  gitlab_domain,
  project_id,
  ref,
  job_name,
  artifact_path
) {
  const url = await fetchGitLabArtifactURL(
    gitlab_domain,
    project_id,
    ref,
    job_name,
    artifact_path
  );
  const sha256 = await fetchHash(fetcher, { url, sha256: "" });
  return { url, sha256 };
}

async function fetchGitHubArtifact(
  owner,
  repo,
  branch,
  workflow_name,
  artifact_name
) {
  const url = await fetchGitHubArtifactURL(
    owner,
    repo,
    branch,
    workflow_name,
    artifact_name
  );
  const sha256 = await fetchHash("builtins.fetchTarball", { url, sha256: "" });
  return { url, sha256 };
}

async function fetchGitHubLatestRelease(fetcher, owner, repo, suffix) {
  const url = await fetchGitHubLatestReleaseURL(owner, repo, suffix);
  const sha256 = await fetchHash(fetcher, { url, sha256: "" });
  return { url, sha256 };
}

async function fetchurl(url) {
  const sha256 = await fetchHash("builtins.fetchurl", { url, sha256: "" });
  return { url, sha256 };
}

const _wasi_sdk = fetchGitHubArtifact(
  "tweag",
  "wasi-sdk",
  "main",
  "CI",
  "dist-ubuntu-latest"
);
const _libffi_wasm32 = fetchGitHubArtifact(
  "tweag",
  "libffi-wasm32",
  "master",
  "shell",
  "out"
);
const _deno = fetchGitHubLatestRelease(
  "builtins.fetchTarball",
  "denoland",
  "deno",
  "unknown-linux-gnu.zip"
);
const _binaryen = fetchGitHubLatestRelease(
  "builtins.fetchTarball",
  "WebAssembly",
  "binaryen",
  "x86_64-linux.tar.gz"
);
const _wabt = fetchGitHubLatestRelease(
  "builtins.fetchTarball",
  "WebAssembly",
  "wabt",
  "ubuntu.tar.gz"
);
const _wasmtime = fetchGitHubLatestRelease(
  "builtins.fetchTarball",
  "bytecodealliance",
  "wasmtime",
  "x86_64-linux.tar.xz"
);
const _wasmedge = fetchGitHubLatestRelease(
  "builtins.fetchTarball",
  "WasmEdge",
  "WasmEdge",
  "ubuntu20.04_x86_64.tar.gz"
);
const _wasmer = fetchGitHubLatestRelease(
  "builtins.fetchurl",
  "wasmerio",
  "wasmer",
  "linux-amd64.tar.gz"
);
const _wizer = fetchGitHubArtifact(
  "bytecodealliance",
  "wizer",
  "main",
  "Release",
  "bins-x86_64-linux"
);
const _cabal = fetchurl(
  "https://downloads.haskell.org/cabal/cabal-install-3.8.1.0/cabal-install-3.8.1.0-x86_64-linux-deb10.tar.xz"
);
const _proot = fetchGitLabArtifact(
  "builtins.fetchurl",
  "gitlab.com",
  9799675,
  "master",
  "dist",
  "dist/proot"
);

await Deno.writeTextFile(
  "autogen.json",
  JSON.stringify(
    {
      "wasi-sdk": await _wasi_sdk,
      "libffi-wasm32": await _libffi_wasm32,
      deno: await _deno,
      binaryen: await _binaryen,
      wabt: await _wabt,
      wasmtime: await _wasmtime,
      wasmedge: await _wasmedge,
      wasmer: await _wasmer,
      wizer: await _wizer,
      cabal: await _cabal,
      proot: await _proot,
    },
    null,
    2
  )
);
