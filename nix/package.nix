{
  lib,
  python3Packages,
  self,
}:

python3Packages.buildPythonApplication {
  pname = "first-time-contribution-tagger";
  version = "0.1.1";
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

  meta = {
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ janik ];
  };
}
