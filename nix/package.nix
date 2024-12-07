{
  lib,
  python3Packages,
  self,
}:

python3Packages.buildPythonApplication rec {
  pname = "first-time-contribution-tagger";
  inherit (passthru.pyprojectToml.tool.poetry) version;
  pyproject = true;

  src = self;

  build-system = [
    python3Packages.poetry-core
  ];

  dependencies = [
    python3Packages.requests
  ];

  nativeCheckInputs = [
    python3Packages.pytestCheckHook
  ];

  passthru = {
    pyprojectToml = lib.importTOML (self + "/pyproject.toml");
  };

  meta = {
    license = lib.licenses.agpl3Only;
    maintainers = [ ];
    mainProgram = "first-time-contribution-tagger";
  };
}
