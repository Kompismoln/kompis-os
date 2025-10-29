{
  writeShellApplication,
  postgresql,
  gnugrep,
  coreutils,
  ...
}:
writeShellApplication {
  name = "pgsql-init";
  runtimeInputs = [
    postgresql
    gnugrep
    coreutils
  ];
  text = builtins.readFile ../tools/session/pgsql-init.sh;
}
