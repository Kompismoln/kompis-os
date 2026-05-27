let
  colors-nested = builtins.fromJSON (builtins.readFile ./colors.json);
  color-names = builtins.attrNames colors-nested;

  color-name-value-pairs = builtins.concatMap (
    color-name:
    let
      shades = colors-nested.${color-name};
    in
    map (shade: {
      name = "${color-name}-${shade}";
      value = shades.${shade};
    }) (builtins.attrNames shades)
  ) color-names;
  colors = builtins.listToAttrs color-name-value-pairs;
in
with colors;
colors
// rec {
  base00 = zinc-950;
  base01 = red-600;
  base02 = green-200;
  base03 = orange-300;
  base04 = indigo-300;
  base05 = zinc-400;
  base06 = emerald-200;
  base07 = neutral-500;

  base08 = amber-50;
  base09 = red-500;
  base0A = green-800;
  base0B = orange-400;
  base0C = slate-500;
  base0D = violet-400;
  base0E = slate-500;
  base0F = stone-400;

  bg-200 = zinc-600;
  bg-300 = zinc-800;
  bg-400 = zinc-900;
  bg-500 = zinc-900;
  bg-inv = amber-100;

  fg-200 = amber-50;
  fg-300 = amber-100;
  fg-400 = stone-400;
  fg-500 = neutral-500;
  fg-inv = zinc-900;

  bg-selected = bg-inv;
  bg-success = green-200;
  bg-disabled = stone-400;
  bg-error = rose-400;
  bg-warning = orange-300;
  bg-info = sky-300;
  bg-hint = zinc-900;

  fg-selected = fg-inv;
  fg-success = zinc-900;
  fg-disabled = zinc-900;
  fg-error = zinc-900;
  fg-warning = zinc-900;
  fg-info = zinc-900;
  fg-hint = stone-400;

  fg-match = red-500;
  fg-match-selected = red-500;
}
