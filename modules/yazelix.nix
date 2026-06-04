{
  programs.yazelix = {
    enable = true;
    manage_config = false;
    terminal = "yzxterm";
    yzxterm_profile = "shaders";
    extra_terminal_launchers = [
      "ghostty"
      "rio"
      "foot"
      "wezterm"
    ];
    agent_usage_programs = [
      "tokenusage"
    ];
  };
}
