{ lib, org, ... }:
let
  regexes = rec {
    octet = "[0-9]{1,3}";

    hextet = "[0-9a-f]{1,4}";
    hextetP4 = "[0-9a-f]{4}";
    hextetP8 = "[0-9a-f]{8}";
    hextetP32 = "[0-9a-f]{32}";

    hexpair = "[0-9a-f]{2}";

    mac = "${hexpair}(:${hexpair}){5}";

    globalPrefix6 = "${hextet}:${hextet}:${hextet}";
    globalPrefix4 = "${octet}.${octet}";

    prefixLength6 = "(64|128)";
    prefixLength4 = "(24|32)";

    subnetPrefix6 = "${globalPrefix6}:${hextet}";
    subnetPrefix4 = "${globalPrefix4}.${octet}";

    subnetCidr6 = "${subnetPrefix6}::/${prefixLength6}";
    subnetCidr4 = "${subnetPrefix4}.0/${prefixLength4}";

    host6 = "${subnetPrefix6}:(:${hextet}){1,3}";
    host4 = "${subnetPrefix4}.${octet}";

    hostCidr6 = "${host6}/${prefixLength6}";
    hostCidr4 = "${host4}/${prefixLength4}";

    subnetCidrBracketed6 = "[[]${subnetPrefix6}::[]]/${prefixLength6}";
    hostCidrBracketed6 = "[[]${host6}[]]/${prefixLength6}";
  };
in
{
  host = with lib.types; enum (lib.attrNames org.host);
  user = with lib.types; enum (lib.attrNames org.user);
  service = with lib.types; enum (lib.attrNames org.service);
  store = with lib.types; enum (lib.attrNames org.store);
  class = with lib.types; enum (lib.attrNames org.class);
  flake = lib.types.attrsOf lib.types.str;
}
// (lib.mapAttrs (_: regex: lib.types.strMatching "^${regex}$") regexes)
