{ 
python312Packages,
lib,
fetchFromGitHub
}:

python312Packages.buildPythonPackage {
  pname = "rassumfrassum";
  version = "0.3.3";
  src = fetchFromGitHub {
    owner = "joaotavora";
    repo = "rassumfrassum";
    rev = "v0.3.3";
    sha256 = "sha256-3Hcews5f7o45GUmFdpLwkAHf0bthC1tUikkxau952Ec=";

  };

  pyproject = true;
  nativeBuildInputs = [ python312Packages.setuptools ];

  pythonImportsCheck = [ "rassumfrassum" ];

  meta = with lib; {
    description = "LSP/JSONRPC multiplexer for connecting one LSP client to multiple servers";
    license = licenses.gpl3Plus;
    homepage = "https://github.com/joaotavora/rassumfrassum";
    mainProgram = "rass";
  };
}
