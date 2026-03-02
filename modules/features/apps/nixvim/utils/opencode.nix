_:
let
  mkOpencodeKeymap =
    {
      key,
      action,
      mode,
      desc,
    }:
    {
      key = "<Leader>o${key}";
      action = "<cmd>lua require('opencode').${action}<CR>";
      inherit mode;
      options = {
        inherit desc;
      };
    };
in
{
  programs.nixvim.config = {
    plugins.opencode = {
      enable = true;
    };

    keymaps = map mkOpencodeKeymap [
      {
        key = "a";
        action = "ask('@this: ', { submit = true })";
        mode = [
          "n"
          "x"
        ];
        desc = "Ask";
      }
      {
        key = "?";
        action = "select()";
        mode = [
          "n"
          "x"
        ];
        desc = "Select action";
      }
      {
        key = "p";
        action = "prompt()";
        mode = [
          "n"
          "t"
        ];
        desc = "Open prompt";
      }
      {
        key = "o";
        action = "toggle()";
        mode = [
          "n"
          "t"
        ];
        desc = "Toggle opencode";
      }
    ];
  };
}
