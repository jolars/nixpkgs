{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  makeWrapper,
  R,
  runtimeShell,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "arf";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "eitsupi";
    repo = "arf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7qHnc+red7onQyDRDePA5GaLfBLbuNdKrz/uTtmP0es=";
  };

  cargoHash = "sha256-+SX+oQaMRYOutdijkNTvEqpNm1lQKqXGq1agKW8FpYU=";

  env.LANG = "C.UTF-8";

  postPatch = ''
    substituteInPlace \
      crates/arf-console/src/external/formatter.rs \
      crates/arf-console/tests/pty_advanced_tests.rs \
      crates/arf-console/tests/resolve_tests.rs \
      --replace-fail '#!/bin/sh' '#!${runtimeShell}'
  '';

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  nativeCheckInputs = [
    R
    writableTmpDirAsHomeHook
  ];

  preCheck = lib.optionalString stdenv.hostPlatform.isLinux ''
    export LD_LIBRARY_PATH=${R}/lib/R/lib
  '';

  postInstall = ''
    ${lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      installShellCompletion --cmd arf \
        --bash <($out/bin/arf completions bash) \
        --fish <($out/bin/arf completions fish) \
        --zsh <($out/bin/arf completions zsh)
    ''}
    wrapProgram $out/bin/arf \
      --suffix PATH : ${lib.makeBinPath [ R ]}
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Modern R console written in Rust";
    homepage = "https://github.com/eitsupi/arf";
    changelog = "https://github.com/eitsupi/arf/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.jolars ];
    mainProgram = "arf";
    platforms = lib.platforms.unix;
  };
})
