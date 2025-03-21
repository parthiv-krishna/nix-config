{
  inputs,
  ...
}:
{

  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  programs.nixvim = {
    enable = true;

    viAlias = true;
    vimAlias = true;

    keymaps = [
      # swap gj/j and gk/k
      {
        key = "j";
        action = "gj";
        mode = "n";
      }
      {
        key = "k";
        action = "gk";
        mode = "n";
      }
      {
        key = "gj";
        action = "j";
        mode = "n";
      }
      {
        key = "gk";
        action = "k";
        mode = "n";
      }
      # swap g<down>/<down> and g<up>/<up>
      {
        key = "<down>";
        action = "g<down>";
      }
      {
        key = "<up>";
        action = "g<up>";
      }
      {
        key = "g<up>";
        action = "<up>";
      }
      {
        key = "g<down>";
        action = "<down>";
      }
      # remove search highlight
      {
        key = "<Leader>n";
        action = ":noh<CR>";
      }
      # vertical split
      {
        key = "<Leader>v";
        action = ":vs<CR>";
      }
      # horizontal split
      {
        key = "<Leader>h";
        action = ":sv<CR>";
      }
    ];
  };
}
