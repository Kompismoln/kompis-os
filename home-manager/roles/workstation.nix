{
  org,
  hmHost,
  ...
}:
{
  imports = [
    ./base.nix
  ];
  kompis-os-hm = {
    ide = {
      enable = true;
      name = org.user.${hmHost.username}.description;
      email = org.user.${hmHost.username}.email;
    };
    shell.enable = true;
    user = {
      enable = true;
      name = hmHost.username;
    };
  };
}
