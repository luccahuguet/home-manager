{
  programs.yazelix = {
    enable = true;
    manage_config = false;
    runtime_variant = "yzxterm";
    extra_terminal_variants = [
      "ghostty"
      "wezterm"
      "ratty"
      "kitty"
    ];
    terminals = [
      "yzxterm"
      "ghostty"
      "wezterm"
      "ratty"
      "kitty"
    ];
    agent_usage_programs = [
      "tokenusage"
    ];
  };
}
