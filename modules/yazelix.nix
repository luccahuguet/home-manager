{
  programs.yazelix = {
    enable = true;
    manage_config = false;
    terminal = "ratty";
    yzxterm_profile = "shaders";
    extra_terminal_launchers = [
      "ghostty"
      "yzxterm"
      "rio"
      "foot"
      "wezterm"
    ];
    agent_usage_programs = [
      "tokenusage"
    ];
  };
}
