{ proot, qemu-system-wasm32, writeShellScriptBin, }:
writeShellScriptBin "wasmtime-run" ''
  exec ${proot}/bin/proot -q ${qemu-system-wasm32}/bin/qemu-system-wasm32 ''${1+"$@"}
''
