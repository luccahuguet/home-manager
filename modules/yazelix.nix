{
  programs.yazelix = {
    enable = true;
    manage_config = false;
    runtime_variant = "yzxterm";
    yzxterm_profile = "shaders";
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
