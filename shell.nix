{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = [
    pkgs.flutter
    (pkgs.python313.withPackages (pypkg: [pypkg.psycopg2]))
    pkgs.uv
    pkgs.postgresql
  ];
  PGDATA = "${toString ./.}/.data";
}
