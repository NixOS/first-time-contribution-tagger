{
  lib,
  buildPythonApplication,
  poetry-core,
  pytestCheckHook,
  requests,
  self,
}:

buildPythonApplication rec {
  pname = "first-time-contribution-tagger";
  inherit (passthru.pyprojectToml.tool.poetry) version;
  pyproject = true;

  src = self;

  build-system = [ poetry-core ];

  dependencies = [ requests ];

  nativeCheckInputs = [ pytestCheckHook ];

  passthru = {
    pyprojectToml = lib.importTOML (self + "/pyproject.toml");
  };

  meta = {
    license = lib.licenses.agpl3Only;
    maintainers = [ ];
    mainProgram = "first-time-contribution-tagger";
  };
}
